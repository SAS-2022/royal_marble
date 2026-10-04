import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../core/maps.dart';
import '../core/roles.dart';
import '../l10n/app_localizations.dart';
import '../models/attendance.dart';
import '../models/business_model.dart';
import '../models/device_status.dart';
import '../models/user_model.dart';
import '../services/checkin_service.dart' show SiteKind;
import '../services/database.dart';
import '../shared/loading.dart';
import '../widgets/checkin_card.dart' show timesheetDayId;
import '../widgets/status_widgets.dart';
import 'site_details_screen.dart' show SiteDetailsLoader;
import 'site_form_screen.dart' show SiteFormScreen, addressFromPlacemark;
import 'team_status_screen.dart' show timeAgo;

/// Where a worker stands today, most urgent first. Decides the pin colour.
enum WorkerState { phoneProblem, outside, onSite, notCheckedIn }

/// A location older than this is drawn faded: the phone has gone quiet.
const staleLocation = Duration(hours: 2);

/// One worker on the map, with everything the pin and its sheet show.
class MapWorker {
  final UserData user;
  final LatLng? position;
  final DeviceStatus status;
  final DayEntry today;

  MapWorker(this.user, this.status, this.today)
      : position = _latLng(user.currentLocation);

  static LatLng? _latLng(Map<String, dynamic>? m) {
    final lat = m?['Lat'], lng = m?['Lng'];
    return lat is num && lng is num ? LatLng(lat.toDouble(), lng.toDouble()) : null;
  }

  String get name => '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
  DateTime? get locatedAt => status.lastLocationAt ?? status.lastSeen;
  bool get stale =>
      locatedAt == null || DateTime.now().difference(locatedAt!) > staleLocation;

  WorkerState get state {
    final open = today.open;
    if (status.problems.isNotEmpty) return WorkerState.phoneProblem;
    if (open != null && open.outsideSince != null) return WorkerState.outside;
    if (open != null) return WorkerState.onSite;
    return WorkerState.notCheckedIn;
  }
}

double _hue(WorkerState s) => switch (s) {
      WorkerState.phoneProblem => BitmapDescriptor.hueRed,
      WorkerState.outside => BitmapDescriptor.hueOrange,
      WorkerState.onSite => BitmapDescriptor.hueGreen,
      WorkerState.notCheckedIn => BitmapDescriptor.hueAzure,
    };

Tone _tone(WorkerState s) => switch (s) {
      WorkerState.phoneProblem => Tone.bad,
      WorkerState.outside => Tone.warn,
      WorkerState.onSite => Tone.ok,
      WorkerState.notCheckedIn => Tone.neutral,
    };

/// A site drawn on the map.
class _MapSite {
  final SiteKind kind;
  final String id;
  final String name;
  final LatLng center;
  final double radius;
  const _MapSite(this.kind, this.id, this.name, this.center, this.radius);
}

/// Workers' last positions over the sites' check-in circles. Admins see
/// everyone; supervisors see the people and sites they are responsible for.
/// Tap a pin for the worker's status, tap a circle to open the site, and
/// long-press the map to start a new site there.
class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key, required this.currentUser});
  final UserData currentUser;

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  static const _dubai = LatLng(25.2048, 55.2708);

  final _db = DatabaseService();
  late final _users = _db.getAllUsers();
  late final _projects = _db.getAllProjects();
  late final _mockups = _db.getAllMockups();
  late final _timesheet = _db.getTimeSheetData(uid: timesheetDayId());
  late final AppRole _role = primaryRole(widget.currentUser.roles);

  GoogleMapController? _map;
  bool _framed = false;
  WorkerState? _filter;

  /// Ids of the supervisor's own sites; null for admins (all sites).
  Set<String>? get _mySites => _role == AppRole.admin
      ? null
      : {
          for (final a in siteAssignments(widget.currentUser.assignedProject)) '${a['id']}',
          for (final a in siteAssignments(widget.currentUser.assignedMockups)) '${a['id']}',
        };

  List<MapWorker> _workers(List<UserData> users, Map<String, dynamic> sheet) {
    final mine = _mySites;
    return [
      for (final u in users)
        if (u.error == null &&
            u.isActive == true &&
            u.uid != widget.currentUser.uid &&
            !primaryRole(u.roles).canMonitor &&
            (mine == null ||
                [...siteAssignments(u.assignedProject), ...siteAssignments(u.assignedMockups)]
                    .any((a) => mine.contains('${a['id']}'))))
          MapWorker(u, DeviceStatus.fromMap(u.deviceStatus),
              DayEntry.fromMap(sheet[u.uid] as Map?)),
    ];
  }

  List<_MapSite> _sites(List<ProjectData> projects, List<MockupData> mockups) {
    final mine = _mySites;
    LatLng? at(Map<String, dynamic>? a) => MapWorker._latLng(a);
    return [
      for (final p in projects)
        if (p.error == null &&
            p.projectStatus != 'closed' &&
            at(p.projectAddress) != null &&
            (mine == null || mine.contains(p.uid)))
          _MapSite(SiteKind.project, p.uid!, p.projectName ?? '', at(p.projectAddress)!,
              p.radius ?? 150),
      for (final m in mockups)
        if (m.error == null &&
            m.mockupStatus != 'closed' &&
            at(m.mockupAddress) != null &&
            (mine == null || mine.contains(m.uid)))
          _MapSite(SiteKind.mockup, m.uid!, m.mockupName ?? '', at(m.mockupAddress)!,
              m.radius ?? 150),
    ];
  }

  /// Moves the camera so every shown worker (or, with none, every site) fits.
  Future<void> _frame(Iterable<LatLng> points) async {
    final pts = points.toList();
    if (_map == null || pts.isEmpty) return;
    if (pts.length == 1) {
      await _map!.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 16));
      return;
    }
    var s = pts.first.latitude, n = s, w = pts.first.longitude, e = w;
    for (final p in pts) {
      s = math.min(s, p.latitude);
      n = math.max(n, p.latitude);
      w = math.min(w, p.longitude);
      e = math.max(e, p.longitude);
    }
    await _map!.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e)), 64));
  }

  void _openSite(_MapSite s) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              SiteDetailsLoader(kind: s.kind, id: s.id, currentUser: widget.currentUser)));

  Future<void> _newSiteAt(LatLng p) async {
    final l = context.l10n;
    final kind = await showModalBottomSheet<SiteKind>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.apartment),
            title: Text(l.newProjectHere),
            onTap: () => Navigator.pop(context, SiteKind.project),
          ),
          ListTile(
            leading: const Icon(Icons.view_in_ar),
            title: Text(l.newMockupHere),
            onTap: () => Navigator.pop(context, SiteKind.mockup),
          ),
        ]),
      ),
    );
    if (kind == null) return;
    var name = '';
    try {
      final marks = await Geocoding(locale: const Locale('en'))
          .placemarkFromCoordinates(p.latitude, p.longitude);
      if (marks.isNotEmpty) name = addressFromPlacemark(marks.first);
    } catch (_) {
      // Offline: the admin can type the address on the form.
    }
    if (!mounted) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SiteFormScreen(
                kind: kind,
                initialPin: {'addressName': name, 'Lat': p.latitude, 'Lng': p.longitude},
                createdBy: widget.currentUser.uid,
                currentUser: widget.currentUser)));
  }

  void _showWorker(MapWorker w, List<_MapSite> sites) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _WorkerSheet(
        worker: w,
        sites: sites,
        onOpenSite: (s) {
          Navigator.pop(context);
          _openSite(s);
        },
      ),
    );
  }

  void _showList(List<MapWorker> shown, List<_MapSite> sites) {
    final l = context.l10n;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: shown.isEmpty
            ? Center(child: Text(l.noActiveWorkers))
            : ListView(children: [
                for (final w in shown)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _tone(w.state).bg,
                      child: Icon(Icons.person, color: _tone(w.state).fg),
                    ),
                    title: Text(w.name),
                    subtitle: Text(w.position == null
                        ? l.noLocationYet
                        : _stateText(l, w)),
                    onTap: () {
                      Navigator.pop(context);
                      if (w.position != null) {
                        _map?.animateCamera(CameraUpdate.newLatLngZoom(w.position!, 17));
                      }
                      _showWorker(w, sites);
                    },
                  ),
              ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.liveMap)),
      body: StreamBuilder<List<UserData>>(
        stream: _users,
        builder: (context, u) => StreamBuilder<Map<String, dynamic>>(
          stream: _timesheet,
          builder: (context, t) => StreamBuilder<List<ProjectData>>(
            stream: _projects,
            builder: (context, p) => StreamBuilder<List<MockupData>>(
              stream: _mockups,
              builder: (context, m) {
                if (!u.hasData || !p.hasData || !m.hasData) return const Loading();
                final workers = _workers(u.data!, t.data ?? const {});
                final sites = _sites(p.data!, m.data!);
                final counts = {
                  for (final s in WorkerState.values)
                    s: workers.where((w) => w.state == s).length
                };
                // Most urgent first, then by name.
                final shown = workers
                    .where((w) => _filter == null || w.state == _filter)
                    .toList()
                  ..sort((a, b) => a.state.index != b.state.index
                      ? a.state.index.compareTo(b.state.index)
                      : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                final located = shown.where((w) => w.position != null).toList();

                if (!_framed && _map != null) {
                  _framed = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) => _frame(
                      located.isNotEmpty
                          ? located.map((w) => w.position!)
                          : sites.map((s) => s.center)));
                }

                return Stack(children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(target: _dubai, zoom: 10),
                    onMapCreated: (c) {
                      _map = c;
                      setState(() {});
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    padding: const EdgeInsets.only(top: 56, bottom: 72),
                    onLongPress: _newSiteAt,
                    circles: {
                      for (final s in sites)
                        Circle(
                          circleId: CircleId('${s.kind.name}_${s.id}'),
                          center: s.center,
                          radius: s.radius,
                          strokeWidth: 2,
                          strokeColor: AppColors.goldDeep,
                          fillColor: AppColors.gold.withValues(alpha: 0.18),
                          consumeTapEvents: true,
                          onTap: () => _openSite(s),
                        ),
                    },
                    markers: {
                      for (final s in sites)
                        Marker(
                          markerId: MarkerId('site_${s.kind.name}_${s.id}'),
                          position: s.center,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueYellow),
                          alpha: 0.7,
                          infoWindow: InfoWindow(
                              title: s.name,
                              snippet: l.checkInRadius(s.radius.round()),
                              onTap: () => _openSite(s)),
                        ),
                      for (final w in located)
                        Marker(
                          markerId: MarkerId('w_${w.user.uid}'),
                          position: w.position!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(_hue(w.state)),
                          alpha: w.stale ? 0.45 : 1,
                          zIndexInt: 2,
                          onTap: () => _showWorker(w, sites),
                        ),
                    },
                  ),
                  // Filter by state, with counts.
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(children: [
                        for (final s in <WorkerState?>[null, ...WorkerState.values])
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: ChoiceChip(
                              backgroundColor: Colors.white,
                              avatar: s == null
                                  ? null
                                  : CircleAvatar(backgroundColor: _tone(s).fg, radius: 6),
                              label: Text(
                                  '${s == null ? l.everything : _stateLabel(l, s)} '
                                  '(${s == null ? workers.length : counts[s]})'),
                              selected: _filter == s,
                              onSelected: (_) => setState(() => _filter = s),
                            ),
                          ),
                      ]),
                    ),
                  ),
                  PositionedDirectional(
                    end: 16,
                    bottom: 96,
                    child: FloatingActionButton.small(
                      heroTag: 'fit',
                      tooltip: l.showEveryone,
                      onPressed: () => _frame(located.isNotEmpty
                          ? located.map((w) => w.position!)
                          : sites.map((s) => s.center)),
                      child: const Icon(Icons.fit_screen),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: SafeArea(
                      top: false,
                      child: FilledButton.icon(
                        onPressed: () => _showList(shown, sites),
                        icon: const Icon(Icons.people_outline),
                        label: Text(l.peopleOnMap(located.length, shown.length)),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }
}

String _stateLabel(AppLocalizations l, WorkerState s) => switch (s) {
      WorkerState.phoneProblem => l.phoneProblems,
      WorkerState.outside => l.outsideSite,
      WorkerState.onSite => l.onSiteNow,
      WorkerState.notCheckedIn => l.notCheckedIn,
    };

/// "On site at Villa since 07:10", "Outside the site since 11:40", …
String _stateText(AppLocalizations l, MapWorker w) {
  final hm = DateFormat('HH:mm');
  final open = w.today.open;
  if (open != null && open.outsideSince != null) {
    return '${open.siteName} · ${l.outsideSiteSince(hm.format(open.outsideSince!))}';
  }
  if (open != null) return l.onSiteAtSince(open.siteName, hm.format(open.start));
  return w.today.isEmpty ? l.notCheckedIn : l.checkedOut;
}

class _WorkerSheet extends StatelessWidget {
  const _WorkerSheet(
      {required this.worker, required this.sites, required this.onOpenSite});
  final MapWorker worker;
  final List<_MapSite> sites;
  final void Function(_MapSite) onOpenSite;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final w = worker;
    final open = w.today.open;
    final openSite = open == null
        ? null
        : sites.where((s) => s.id == open.siteId).firstOrNull;
    // The closest site, to say how far away a worker who is not checked in is.
    _MapSite? nearest;
    double? nearestM;
    if (w.position != null) {
      for (final s in sites) {
        final d = Geolocator.distanceBetween(w.position!.latitude,
                w.position!.longitude, s.center.latitude, s.center.longitude) -
            s.radius;
        if (nearestM == null || d < nearestM) {
          nearest = s;
          nearestM = d;
        }
      }
    }
    final phone = w.user.phoneNumber;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _tone(w.state).bg,
                  child: Text(
                      '${w.user.firstName?.characters.firstOrNull ?? ''}${w.user.lastName?.characters.firstOrNull ?? ''}',
                      style: TextStyle(
                          color: _tone(w.state).fg, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(w.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(primaryRole(w.user.roles).localized(l),
                        style: const TextStyle(color: AppColors.muted)),
                  ]),
                ),
                StatusPill(_stateLabel(l, w.state), tone: _tone(w.state)),
              ]),
              const SizedBox(height: 12),
              Card(
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(_stateText(l, w)),
                  ),
                  ListTile(
                    leading: Icon(Icons.my_location,
                        color: w.stale ? AppColors.warn : null),
                    title: Text(w.position == null
                        ? l.noLocationYet
                        : l.locationUpdated(timeAgo(l, w.locatedAt))),
                    subtitle: nearest != null && nearestM! > 0 && open == null
                        ? Text(l.distanceFromSite(_distance(l, nearestM), nearest.name))
                        : null,
                  ),
                ]),
              ),
              if (w.status.problems.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final p in w.status.problems)
                    StatusPill(p.text(l), tone: Tone.bad, icon: Icons.warning_amber),
                ]),
              ],
              const SizedBox(height: 14),
              Row(children: [
                if (phone?.isNotEmpty == true)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                      icon: const Icon(Icons.call),
                      label: Text(l.callAction),
                    ),
                  ),
                if (phone?.isNotEmpty == true && w.position != null)
                  const SizedBox(width: 10),
                if (w.position != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          openDirections(w.position!.latitude, w.position!.longitude),
                      icon: const Icon(Icons.directions),
                      label: Text(l.directions),
                    ),
                  ),
              ]),
              if (openSite != null) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => onOpenSite(openSite),
                  icon: Icon(openSite.kind == SiteKind.project
                      ? Icons.apartment
                      : Icons.view_in_ar),
                  label: Text(openSite.name),
                ),
              ],
            ]),
      ),
    );
  }
}

/// "350 m" or "2.4 km".
String _distance(AppLocalizations l, double m) =>
    m < 1000 ? l.metersShort(m.round()) : l.kilometersShort((m / 1000).toStringAsFixed(1));
