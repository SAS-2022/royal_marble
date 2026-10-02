import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../core/roles.dart';
import '../models/user_model.dart';
import '../services/checkin_service.dart';
import '../services/tracking_service.dart';
import 'status_widgets.dart';

/// Legacy `time_sheet` doc id for the phone's local date (`d-m-yyyy`).
String timesheetDayId([DateTime? at]) {
  final d = at ?? DateTime.now();
  return '${d.day}-${d.month}-${d.year}';
}

/// A site the user can check in to: name, live distance, today's status and
/// the check-in/out button. Used on the worker home and the site screens.
class CheckInCard extends StatefulWidget {
  const CheckInCard({
    super.key,
    required this.user,
    required this.kind,
    required this.siteId,
    required this.siteName,
    this.details,
    this.lat,
    this.lng,
    this.radius,
    this.onOpen,
  });

  final UserData user;
  final SiteKind kind;
  final String siteId;
  final String siteName;
  final String? details;
  final double? lat;
  final double? lng;
  final double? radius;
  final VoidCallback? onOpen;

  @override
  State<CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends State<CheckInCard> {
  bool _busy = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Keeps the "on site for 2h 14m" counter moving.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Stream<Map<String, dynamic>?> get _todayEntry => FirebaseFirestore.instance
      .collection('time_sheet')
      .doc(timesheetDayId())
      .snapshots()
      .map((s) => s.data()?[widget.user.uid] as Map<String, dynamic>?);

  double? _distanceToEdge(LiveDeviceState s) {
    final l = s.lastLocation;
    if (l == null || widget.lat == null || widget.lng == null) return null;
    return haversineMeters(
            l.coords.latitude, l.coords.longitude, widget.lat!, widget.lng!) -
        (widget.radius ?? 0);
  }

  Future<void> _submit(bool checkIn) async {
    final l10n = context.l10n;
    String? workType;
    double? squareMeters;
    if (!checkIn && primaryRole(widget.user.roles) == AppRole.worker) {
      final work = await showWorkCompletedSheet(context);
      if (work == null) return;
      (workType, squareMeters) = work;
    }
    setState(() => _busy = true);
    final result = await CheckInService.submit(
      l10n: l10n,
      checkIn: checkIn,
      kind: widget.kind,
      siteId: widget.siteId,
      workType: workType,
      squareMeters: squareMeters,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: result.ok ? AppColors.ok : AppColors.bad,
      content: Text(result.message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _todayEntry,
        builder: (context, snap) {
          final l10n = context.l10n;
          final entry = snap.data;
          final here = entry?['projectId'] == widget.siteId;
          final onSite = entry?['isOnSite'] == true && entry?['leaving_at'] == null;
          final elsewhere = onSite && !here;
          final arrived = DateTime.tryParse('${entry?['arriving_at']}');
          final left = DateTime.tryParse('${entry?['leaving_at']}');

          final (String statusText, Tone statusTone) = switch (null) {
            _ when onSite && here && arrived != null => (
                l10n.onSiteSince(TimeOfDay.fromDateTime(arrived).format(context),
                    localizedDuration(l10n, DateTime.now().difference(arrived))),
                Tone.ok
              ),
            _ when elsewhere => (
                l10n.checkedInAtSite('${entry?['projectName']}'),
                Tone.warn
              ),
            _ when here && arrived != null && left != null => (
                l10n.doneToday(localizedDuration(l10n, left.difference(arrived))),
                Tone.neutral
              ),
            _ => (l10n.notCheckedIn, Tone.neutral),
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: widget.onOpen,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: AppColors.gold.withValues(alpha: 0.18),
                      child: Icon(
                          widget.kind == SiteKind.project
                              ? Icons.apartment
                              : Icons.view_in_ar,
                          color: AppColors.goldDeep),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.siteName,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                          if (widget.details?.isNotEmpty == true)
                            Text(widget.details!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.muted)),
                        ],
                      ),
                    ),
                    if (widget.onOpen != null)
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(spacing: 8, runSpacing: 6, children: [
                  StatusPill(statusText, tone: statusTone, icon: Icons.schedule),
                  ValueListenableBuilder<LiveDeviceState>(
                    valueListenable: TrackingService.state,
                    builder: (_, s, __) {
                      final d = _distanceToEdge(s);
                      if (d == null) return const SizedBox.shrink();
                      return d <= 0
                          ? StatusPill(l10n.withinSiteArea,
                              tone: Tone.ok, icon: Icons.place)
                          : StatusPill(
                              d >= 1000
                                  ? l10n.kmAway((d / 1000).toStringAsFixed(1))
                                  : l10n.metersAway(d.round()),
                              icon: Icons.near_me);
                    },
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _busy
                    ? SizedBox(
                        height: 52,
                        child: Center(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5)),
                                const SizedBox(width: 12),
                                Text(l10n.gettingGpsFix),
                              ]),
                        ),
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              onSite && here ? AppColors.bad : AppColors.ok,
                        ),
                        onPressed: elsewhere
                            ? null
                            : () => _submit(!(onSite && here)),
                        icon: Icon(onSite && here ? Icons.logout : Icons.login),
                        label: Text(onSite && here ? l10n.checkOut : l10n.checkIn),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Asks a worker what they did today before checking out.
Future<(String, double)?> showWorkCompletedSheet(BuildContext context) {
  final l10n = context.l10n;
  // Stored values stay in English so reports are consistent; only the labels
  // are translated.
  const types = ['Installing System', 'Installing Tiles', 'Others'];
  final labels = {
    'Installing System': l10n.workSystem,
    'Installing Tiles': l10n.workTiles,
    'Others': l10n.workOthers,
  };
  String type = types.first;
  final other = TextEditingController();
  final meters = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet<(String, double)>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: StatefulBuilder(
        builder: (context, setSheet) => Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.workCompletedTitle,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  for (final t in types)
                    ButtonSegment(value: t, label: Text(labels[t]!)),
                ],
                selected: {type},
                onSelectionChanged: (v) => setSheet(() => type = v.first),
              ),
              if (type == 'Others') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: other,
                  decoration: InputDecoration(labelText: l10n.describeWork),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.required : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: meters,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: l10n.areaCompleted, suffixText: 'm²'),
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? l10n.enterNumber : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(context, (
                    type == 'Others' ? other.text.trim() : type,
                    double.parse(meters.text),
                  ));
                },
                child: Text(l10n.checkOut),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
