import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/locale_controller.dart';
import '../models/attendance.dart';
import '../models/user_model.dart';
import '../screens/live_map_screen.dart';
import '../screens/site_details_screen.dart';
import '../screens/sites_screen.dart';
import '../services/checkin_service.dart' show SiteKind;
import 'status_widgets.dart';

/// A site with today's head count: open stays inside and outside its area.
class SiteActivity {
  SiteActivity(this.site, this.inside, this.outside);
  final SiteRef site;
  final int inside;
  final int outside;

  int get present => inside + outside;

  LatLng? get pin {
    final lat = site.address?['Lat'], lng = site.address?['Lng'];
    return lat is num && lng is num ? LatLng(lat.toDouble(), lng.toDouble()) : null;
  }

  /// Head counts per site from today's timesheet, busiest first.
  static List<SiteActivity> of(List<SiteRef> sites, Map<String, dynamic> timesheet) {
    final inside = <String, int>{}, outside = <String, int>{};
    for (final v in timesheet.values) {
      if (v is! Map) continue;
      final open = DayEntry.fromMap(v).open;
      if (open == null) continue;
      final counts = open.outsideSince == null ? inside : outside;
      counts[open.siteId] = (counts[open.siteId] ?? 0) + 1;
    }
    return [
      for (final s in sites) SiteActivity(s, inside[s.id] ?? 0, outside[s.id] ?? 0)
    ]..sort((a, b) {
        final byPeople = b.present.compareTo(a.present);
        return byPeople != 0
            ? byPeople
            : a.site.name.toLowerCase().compareTo(b.site.name.toLowerCase());
      });
  }
}

/// The admin home's sites: one map with every active site, then a compact
/// list, busiest first. Shows [initialCount] rows and expands in place; "All
/// sites" opens the full list with search and filters.
class ActiveSitesOverview extends StatefulWidget {
  const ActiveSitesOverview(
      {super.key, required this.sites, required this.user, this.initialCount = 5});

  final List<SiteRef> sites;
  final UserData user;
  final int initialCount;

  @override
  State<ActiveSitesOverview> createState() => _ActiveSitesOverviewState();
}

class _ActiveSitesOverviewState extends State<ActiveSitesOverview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final timesheet = Provider.of<Map<String, dynamic>>(context);
    final rows = SiteActivity.of(widget.sites, timesheet);
    final shown = _expanded ? rows : rows.take(widget.initialCount).toList();
    final hidden = rows.length - shown.length;
    void push(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(
        l.activeSites(rows.length),
        trailing: TextButton(
            onPressed: () => push(SitesScreen(currentUser: widget.user)),
            child: Text(l.allSites)),
      ),
      if (rows.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(l.nobodyYet, style: const TextStyle(color: AppColors.muted)),
          ),
        )
      else
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            if (rows.any((r) => r.pin != null))
              _SitesMap(
                  rows: rows,
                  onTap: () => push(LiveMapScreen(currentUser: widget.user))),
            for (final (i, r) in shown.indexed) ...[
              if (i > 0) const Divider(height: 1, indent: 56),
              SiteRow(activity: r, user: widget.user),
            ],
          ]),
        ),
      if (hidden > 0)
        Center(
          child: TextButton(
            onPressed: () => setState(() => _expanded = true),
            child: Text(l.showMoreSites(hidden)),
          ),
        ),
      if (rows.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(spacing: 14, alignment: WrapAlignment.center, children: [
            _Key(color: AppColors.ok, icon: Icons.circle, text: l.onSite),
            _Key(color: AppColors.warn, icon: Icons.change_history, text: l.outsideSite),
          ]),
        ),
    ]);
  }
}

/// One line per site: kind icon, name, area and team size, today's counts.
class SiteRow extends StatelessWidget {
  const SiteRow({super.key, required this.activity, required this.user});
  final SiteActivity activity;
  final UserData user;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = activity;
    final s = r.site;
    final area = prettyAddress(s.address?['addressName']);
    return ListTile(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  SiteDetailsLoader(kind: s.kind, id: s.id, currentUser: user))),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: r.present > 0
            ? AppColors.okSoft
            : AppColors.gold.withValues(alpha: 0.15),
        child: Icon(s.kind == SiteKind.project ? Icons.apartment : Icons.view_in_ar,
            size: 18, color: r.present > 0 ? AppColors.ok : AppColors.goldDeep),
      ),
      title: Text(s.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
          [
            if (s.kind == SiteKind.mockup) l.mockup,
            if (area.isNotEmpty) area,
            l.siteAssignedCount(s.workerIds.length),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (r.present == 0)
          Text(l.nobodyShort, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        if (r.inside > 0) _Count(r.inside, Icons.circle, AppColors.ok),
        if (r.outside > 0) ...[
          const SizedBox(width: 10),
          _Count(r.outside, Icons.change_history, AppColors.warn),
        ],
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: AppColors.muted),
      ]),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.n, this.icon, this.color);
  final int n;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text('$n', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ]);
}

class _Key extends StatelessWidget {
  const _Key({required this.color, required this.icon, required this.text});
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]);
}

/// Every site as a pin (green when someone is there), framed to fit; a still
/// lite-mode map. Tapping opens the live map.
class _SitesMap extends StatelessWidget {
  const _SitesMap({required this.rows, required this.onTap});
  final List<SiteActivity> rows;
  final VoidCallback onTap;

  static const _height = 150.0;

  @override
  Widget build(BuildContext context) {
    final pins = [for (final r in rows) if (r.pin != null) (r, r.pin!)];
    return LayoutBuilder(builder: (context, c) {
      final camera = _fit([for (final p in pins) p.$2], c.maxWidth, _height);
      return SizedBox(
        height: _height,
        child: Stack(fit: StackFit.expand, children: [
          IgnorePointer(
            child: GoogleMap(
              key: ValueKey(pins.map((p) => '${p.$1.site.id}${p.$1.present}').join()),
              initialCameraPosition: camera,
              liteModeEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              markers: {
                for (final (r, pin) in pins)
                  Marker(
                    markerId: MarkerId(r.site.id),
                    position: pin,
                    icon: BitmapDescriptor.defaultMarkerWithHue(r.present > 0
                        ? BitmapDescriptor.hueGreen
                        : BitmapDescriptor.hueYellow),
                  ),
              },
            ),
          ),
          Material(type: MaterialType.transparency, child: InkWell(onTap: onTap)),
        ]),
      );
    });
  }

  /// Centre and zoom that fit all [points] in a [w]×[h] map (lite mode has no
  /// camera bounds), with some margin so pins aren't cut at the edges.
  static CameraPosition _fit(List<LatLng> points, double w, double h) {
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    double y(double lat) {
      final s = math.sin(lat * math.pi / 180);
      return math.log((1 + s) / (1 - s)) / 2;
    }

    const margin = 1.6;
    final lngFrac = (maxLng - minLng) / 360 * margin;
    final latFrac = (y(maxLat) - y(minLat)) / (2 * math.pi) * margin;
    double zoomFor(double px, double frac) =>
        frac <= 0 ? 21 : math.log(px / 256 / frac) / math.ln2;
    final zoom = math.min(zoomFor(w, lngFrac), zoomFor(h, latFrac)).clamp(3.0, 14.0);
    return CameraPosition(target: center, zoom: zoom);
  }
}
