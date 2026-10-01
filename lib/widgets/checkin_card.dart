import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
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

String _hm(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return h > 0 ? '${h}h ${m}m' : '${m}m';
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
    String? workType;
    double? squareMeters;
    if (!checkIn && primaryRole(widget.user.roles) == AppRole.worker) {
      final work = await showWorkCompletedSheet(context);
      if (work == null) return;
      (workType, squareMeters) = work;
    }
    setState(() => _busy = true);
    final result = await CheckInService.submit(
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
          final entry = snap.data;
          final here = entry?['projectId'] == widget.siteId;
          final onSite = entry?['isOnSite'] == true && entry?['leaving_at'] == null;
          final elsewhere = onSite && !here;
          final arrived = DateTime.tryParse('${entry?['arriving_at']}');
          final left = DateTime.tryParse('${entry?['leaving_at']}');

          final (String statusText, Tone statusTone) = switch (null) {
            _ when onSite && here && arrived != null => (
                'On site since ${TimeOfDay.fromDateTime(arrived).format(context)} · ${_hm(DateTime.now().difference(arrived))}',
                Tone.ok
              ),
            _ when elsewhere => (
                'Checked in at ${entry?['projectName']}',
                Tone.warn
              ),
            _ when here && arrived != null && left != null => (
                'Done today · ${_hm(left.difference(arrived))}',
                Tone.neutral
              ),
            _ => ('Not checked in', Tone.neutral),
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
                          ? const StatusPill('Within site area',
                              tone: Tone.ok, icon: Icons.place)
                          : StatusPill(
                              d >= 1000
                                  ? '${(d / 1000).toStringAsFixed(1)} km away'
                                  : '${d.round()} m away',
                              icon: Icons.near_me);
                    },
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _busy
                    ? const SizedBox(
                        height: 52,
                        child: Center(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5)),
                                SizedBox(width: 12),
                                Text('Getting an accurate GPS fix…'),
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
                        label: Text(onSite && here ? 'Check out' : 'Check in'),
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
  const types = ['Installing System', 'Installing Tiles', 'Others'];
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
              const Text('Work completed today',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  for (final t in types)
                    ButtonSegment(value: t, label: Text(t.replaceFirst('Installing ', ''))),
                ],
                selected: {type},
                onSelectionChanged: (v) => setSheet(() => type = v.first),
              ),
              if (type == 'Others') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: other,
                  decoration: const InputDecoration(labelText: 'Describe the work'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: meters,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Area completed', suffixText: 'm²'),
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Enter a number' : null,
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
                child: const Text('Check out'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
