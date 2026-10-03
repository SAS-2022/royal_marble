import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/error_reporter.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../models/attendance.dart';
import '../reports/report_data.dart' show dayId;
import '../services/checkin_service.dart' show SiteKind;
import '../widgets/status_widgets.dart';

/// A site an admin can pick for a session.
class _Site {
  final SiteKind kind;
  final String id;
  final String name;
  const _Site(this.kind, this.id, this.name);
  String get key => '${kind.name}:$id';
}

/// One editable session; [from] is its index in the saved day, so the server
/// keeps its presence events and work report.
class _Draft {
  int? from;
  _Site site;
  DateTime start;
  DateTime? end;
  final WorkSession? original;
  _Draft(this.site, this.start, this.end, {this.from, this.original});
}

/// Admin view of one worker's day: fix check-in/out times, add a forgotten
/// stay, remove a wrong one, or approve an automatic check-out as it is.
/// Saves go through `correctAttendance`, which keeps the previous version.
class AttendanceEditScreen extends StatefulWidget {
  const AttendanceEditScreen(
      {super.key, required this.day, required this.uid, required this.name});
  final DateTime day;
  final String uid;
  final String name;

  @override
  State<AttendanceEditScreen> createState() => _AttendanceEditScreenState();
}

class _AttendanceEditScreenState extends State<AttendanceEditScreen> {
  DayEntry? _entry;
  List<_Site> _sites = [];
  List<_Draft> _drafts = [];
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection('time_sheet').doc(dayId(widget.day)).get(),
      db.collection('projects').get(),
      db.collection('mockup').get(),
    ]);
    final sheet = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final projects = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final mockups = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final entry = DayEntry.fromMap(sheet.data()?[widget.uid] as Map?);
    final sites = [
      for (final d in projects.docs)
        _Site(SiteKind.project, d.id, '${d.data()['projectName'] ?? d.id}'),
      for (final d in mockups.docs)
        _Site(SiteKind.mockup, d.id, '${d.data()['name'] ?? d.id}'),
    ]..sort((a, b) => a.name.compareTo(b.name));
    // A session at a site that was deleted since still needs a choice.
    for (final s in entry.sessions) {
      if (!sites.any((x) => x.kind == s.kind && x.id == s.siteId)) {
        sites.add(_Site(s.kind, s.siteId, s.siteName));
      }
    }
    if (!mounted) return;
    setState(() {
      _entry = entry;
      _sites = sites;
      _drafts = [
        for (final (i, s) in entry.sessions.indexed)
          _Draft(sites.firstWhere((x) => x.kind == s.kind && x.id == s.siteId),
              s.start, s.end,
              from: i, original: s),
      ];
    });
  }

  bool get _changed {
    final saved = _entry?.sessions ?? const [];
    if (_drafts.length != saved.length) return true;
    for (final d in _drafts) {
      final o = d.original;
      if (o == null ||
          o.siteId != d.site.id ||
          o.start != d.start ||
          o.end != d.end) {
        return true;
      }
    }
    return false;
  }

  /// Mirrors the server's checks so mistakes show before saving.
  String? _validate() {
    final l = context.l10n;
    final sorted = [..._drafts]..sort((a, b) => a.start.compareTo(b.start));
    for (final (i, d) in sorted.indexed) {
      if (d.end != null && !d.end!.isAfter(d.start)) return l.errEndBeforeStart;
      if (d.end == null && i != sorted.length - 1) return l.errOnlyLastOpen;
      if (i > 0 && (sorted[i - 1].end ?? d.start).isAfter(d.start)) {
        return l.errSessionsOverlap;
      }
    }
    return null;
  }

  Future<DateTime?> _pickTime(DateTime? initial) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );
    if (t == null) return null;
    final d = widget.day;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  void _add() {
    final last = _drafts.isEmpty ? null : _drafts.last;
    final d = widget.day;
    final start = last?.end ?? DateTime(d.year, d.month, d.day, 7);
    setState(() => _drafts.add(_Draft(
        last?.site ?? _sites.first, start, start.add(const Duration(hours: 1)))));
  }

  Future<void> _save() async {
    final l = context.l10n;
    final problem = _validate();
    setState(() => _error = problem);
    if (problem != null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('correctAttendance')
          .call({
        'day': dayId(widget.day),
        'uid': widget.uid,
        'note': _note.text.trim(),
        'sessions': [
          for (final d in _drafts)
            {
              'siteId': d.site.id,
              'siteKind': d.site.kind.name,
              'siteName': d.site.name,
              'in': stamp(d.start),
              'out': d.end == null ? null : stamp(d.end!),
              'from': d.from,
            }
        ],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.ok, content: Text(l.attendanceSaved)));
      Navigator.pop(context, true);
    } on FirebaseFunctionsException catch (e) {
      final reason = e.details is Map ? (e.details as Map)['reason'] : null;
      setState(() => _error = switch (reason) {
            'not_admin' => l.errNotAdmin,
            'bad_sessions' => e.message ?? l.errCheckInFailed(e.code),
            _ => l.errCheckInFailed(e.code),
          });
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      setState(() => _error = l.errNoServer);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final entry = _entry;
    final hm = DateFormat('HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
                DateFormat('EEEE d MMMM yyyy', l.localeName).format(widget.day),
                style: const TextStyle(color: Colors.white70)),
          ),
        ),
      ),
      body: entry == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (entry.needsReview)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(l.reviewHint,
                        style: const TextStyle(color: AppColors.muted)),
                  ),
                for (final (i, d) in _drafts.indexed)
                  _SessionEditor(
                    draft: d,
                    sites: _sites,
                    canBeOpen: i == _drafts.length - 1,
                    onPickStart: () async {
                      final t = await _pickTime(d.start);
                      if (t != null) setState(() => d.start = t);
                    },
                    onPickEnd: () async {
                      final t = await _pickTime(d.end ?? d.start);
                      if (t != null) setState(() => d.end = t);
                    },
                    onClearEnd: () => setState(() => d.end = null),
                    onSite: (s) => setState(() => d.site = s),
                    onDelete: () => setState(() => _drafts.removeAt(i)),
                  ),
                if (_sites.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: Text(l.addSession),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _note,
                  decoration: InputDecoration(
                      labelText: l.correctionNote, hintText: l.correctionNoteHint),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.bad)),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving || (!_changed && !entry.needsReview)
                      ? null
                      : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Icon(_changed ? Icons.save : Icons.check),
                  label: Text(_changed ? l.saveChanges : l.approveAsIs),
                ),
                if (entry.corrections.isNotEmpty) ...[
                  SectionTitle(l.correctionHistory),
                  Card(
                    child: Column(children: [
                      for (final c in entry.corrections.reversed)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.history),
                          title: Text([
                            '${c['byName'] ?? ''}',
                            if (c['at'] is Timestamp)
                              DateFormat('d MMM HH:mm', l.localeName)
                                  .format((c['at'] as Timestamp).toDate()),
                          ].join(' · ')),
                          subtitle: Text([
                            if ('${c['note'] ?? ''}'.isNotEmpty) '${c['note']}',
                            l.previously((c['before'] as List? ?? const [])
                                .whereType<Map>()
                                .map((b) =>
                                    '${b['siteName']} ${hm.format(DateTime.parse('${b['in']}'))}'
                                    '–${b['out'] == null ? '?' : hm.format(DateTime.parse('${b['out']}'))}')
                                .join(', ')),
                          ].join('\n')),
                        ),
                    ]),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SessionEditor extends StatelessWidget {
  const _SessionEditor({
    required this.draft,
    required this.sites,
    required this.canBeOpen,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClearEnd,
    required this.onSite,
    required this.onDelete,
  });
  final _Draft draft;
  final List<_Site> sites;
  final bool canBeOpen;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onClearEnd;
  final ValueChanged<_Site> onSite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final o = draft.original;
    final hm = DateFormat('HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: DropdownButton<String>(
                value: draft.site.key,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: [
                  for (final s in sites)
                    DropdownMenuItem(
                      value: s.key,
                      child: Row(children: [
                        Icon(
                            s.kind == SiteKind.project
                                ? Icons.apartment
                                : Icons.view_in_ar,
                            size: 18,
                            color: AppColors.goldDeep),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(s.name, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                ],
                onChanged: (k) => onSite(sites.firstWhere((s) => s.key == k)),
              ),
            ),
            IconButton(
              tooltip: l.removeSession,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.bad),
            ),
          ]),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onPickStart,
                child: Text('${l.inLabel} ${hm.format(draft.start)}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onPickEnd,
                child: Text(draft.end == null
                    ? l.setCheckOut
                    : '${l.outLabel} ${hm.format(draft.end!)}'),
              ),
            ),
            if (canBeOpen && draft.end != null)
              IconButton(
                tooltip: l.leaveOpen,
                onPressed: onClearEnd,
                icon: const Icon(Icons.clear),
              )
            else
              const SizedBox(width: 48),
          ]),
          if (o != null &&
              (o.auto != null || o.events.isNotEmpty || o.workType != null))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                if (o.auto != null)
                  StatusPill(
                      o.auto == 'left_site'
                          ? l.autoLeftSiteShort
                          : l.autoEndOfDayShort,
                      tone: Tone.warn,
                      icon: Icons.timer_off),
                if (o.away().inMinutes > 0)
                  StatusPill(l.awayFor(localizedDuration(l, o.away())),
                      icon: Icons.directions_walk),
                for (final e in o.events)
                  StatusPill(
                      '${e.exit ? l.leftAt : l.returnedAt} ${hm.format(e.at)}'),
                if (o.workType != null)
                  StatusPill(
                      [o.workType!, if (o.squareMeters != null) '${o.squareMeters} m²']
                          .join(' · '),
                      icon: Icons.construction),
              ]),
            ),
        ]),
      ),
    );
  }
}
