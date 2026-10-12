import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../models/pay_calc.dart';
import '../models/salary.dart';
import '../models/user_model.dart';
import '../services/pay_service.dart';
import '../shared/loading.dart';
import '../widgets/status_widgets.dart';

/// One worker's overtime on one day, as HR reviews it.
class _Row {
  final String uid;
  final String name;
  final DayPay day;
  final DateTime? lastOut;
  final SalaryPackage package;
  const _Row(this.uid, this.name, this.day, this.lastOut, this.package);
}

/// Every worker's days with overtime in this month (or the last), newest first.
Future<List<_Row>> _loadOvertime({bool lastMonth = false}) async {
  final now = DateTime.now();
  final range =
      PayService.month(lastMonth ? DateTime(now.year, now.month - 1) : now, now);
  final (workers, packages, decisions) = await (
    PayService.loadDays(range),
    PayService.packages(),
    PayService.decisionsIn(range),
  ).wait;
  final rows = <_Row>[];
  for (final MapEntry(key: uid, value: w) in workers.entries) {
    final p = packages[uid] ?? const SalaryPackage();
    for (final MapEntry(key: day, value: entry) in w.days.entries) {
      final d = dayPay(day, entry, p, decisions[uid]?[day], now);
      if (d.overtimeMinutes == 0) continue;
      final outs = entry.sessions.map((s) => s.end).whereType<DateTime>();
      final lastOut = outs.isEmpty ? null : outs.reduce((a, b) => a.isAfter(b) ? a : b);
      rows.add(_Row(uid, w.name, d, lastOut, p));
    }
  }
  rows.sort((a, b) {
    final byDay = b.day.day.compareTo(a.day.day);
    return byDay != 0 ? byDay : a.name.compareTo(b.name);
  });
  return rows;
}

/// Overtime days this month still waiting for HR (for the home screen).
Future<int> countWaitingOvertime() async => (await _loadOvertime())
    .where((r) => r.day.overtimeStatus == OvertimeStatus.pending)
    .length;

/// HR and admins: overtime (time after each worker's day end) to approve or
/// reject. Only approved overtime is paid.
class OvertimeScreen extends StatefulWidget {
  const OvertimeScreen({super.key, required this.viewer});
  final UserData viewer;

  @override
  State<OvertimeScreen> createState() => _OvertimeScreenState();
}

class _OvertimeScreenState extends State<OvertimeScreen> {
  bool _lastMonth = false;
  late Future<List<_Row>> _rows = _load();

  Future<List<_Row>> _load() => _loadOvertime(lastMonth: _lastMonth);

  void _reload() => setState(() => _rows = _load());

  Future<void> _decide(_Row r, OvertimeStatus status) async {
    final l = context.l10n;
    String? note;
    if (status == OvertimeStatus.rejected) {
      final c = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.rejectOvertimeTitle),
          content: TextField(
            controller: c,
            decoration: InputDecoration(labelText: l.notesOptional),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.reject)),
          ],
        ),
      );
      if (ok != true) return;
      note = c.text.trim().isEmpty ? null : c.text.trim();
    }
    final v = widget.viewer;
    final error = await PayService.decide(
      uid: r.uid,
      day: r.day.day,
      status: status,
      minutes: r.day.overtimeMinutes,
      rate: r.package.overtimeRate,
      note: note,
      byName: '${v.firstName ?? ''} ${v.lastName ?? ''}'.trim(),
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.bad, content: Text(error)));
      return;
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.overtime),
          bottom: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: AppColors.gold,
              tabs: [
            Tab(text: l.overtimeWaiting),
            Tab(text: l.overtimeApproved),
            Tab(text: l.overtimeRejected),
          ]),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(spacing: 8, children: [
              ChoiceChip(
                label: Text(l.thisMonth),
                selected: !_lastMonth,
                onSelected: (_) {
                  _lastMonth = false;
                  _reload();
                },
              ),
              ChoiceChip(
                label: Text(l.lastMonth),
                selected: _lastMonth,
                onSelected: (_) {
                  _lastMonth = true;
                  _reload();
                },
              ),
            ]),
          ),
          Expanded(
            child: FutureBuilder<List<_Row>>(
              future: _rows,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text(l.couldNotLoad));
                }
                if (!snap.hasData) return const Center(child: Loading());
                final rows = snap.data!;
                return TabBarView(children: [
                  for (final s in OvertimeStatus.values)
                    _List(
                      rows: rows.where((r) => r.day.overtimeStatus == s).toList(),
                      onDecide: _decide,
                    ),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.rows, required this.onDecide});
  final List<_Row> rows;
  final void Function(_Row, OvertimeStatus) onDecide;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (rows.isEmpty) {
      return Center(
          child: Text(l.noOvertime, style: const TextStyle(color: AppColors.muted)));
    }
    final dayFmt = DateFormat('EEE d MMM', l.localeName);
    final hm = DateFormat('HH:mm');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final r = rows[i];
        final d = r.day;
        final dec = d.decision;
        final status = d.overtimeStatus;
        final rate = status == OvertimeStatus.approved ? dec!.rate : r.package.overtimeRate;
        final dayEnd = hm.format(DateTime(0).add(Duration(minutes: r.package.dayEndMinutes)));
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(r.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                Text(dayFmt.format(d.day), style: const TextStyle(color: AppColors.muted)),
              ]),
              const SizedBox(height: 6),
              Text(l.overtimeLine(
                  localizedDuration(l, Duration(minutes: d.overtimeMinutes)),
                  dayEnd,
                  r.lastOut == null ? '—' : hm.format(r.lastOut!))),
              const SizedBox(height: 4),
              Text(
                  rate > 0
                      ? l.overtimeWorth(money(rate * d.overtimeMinutes / 60, r.package.currency),
                          money(rate, r.package.currency))
                      : l.noOvertimeRate,
                  style: TextStyle(color: rate > 0 ? AppColors.ink : AppColors.warn)),
              if (d.changedSinceDecision) ...[
                const SizedBox(height: 8),
                StatusPill(l.changedAfterDecision, tone: Tone.warn, icon: Icons.edit_note),
              ],
              if (dec != null && !d.changedSinceDecision) ...[
                const SizedBox(height: 6),
                Text(
                    l.decidedBy(dec.byName ?? '',
                        dec.at == null ? '' : DateFormat('d MMM', l.localeName).format(dec.at!)),
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                if (dec.note?.isNotEmpty == true)
                  Text(dec.note!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
              const SizedBox(height: 10),
              // The theme's buttons are full width, so each takes half.
              Row(children: [
                if (status != OvertimeStatus.rejected)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.bad),
                      onPressed: () => onDecide(r, OvertimeStatus.rejected),
                      child: Text(l.reject),
                    ),
                  ),
                if (status == OvertimeStatus.pending) const SizedBox(width: 10),
                if (status != OvertimeStatus.approved)
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.ok),
                      onPressed: () => onDecide(r, OvertimeStatus.approved),
                      child: Text(l.approve),
                    ),
                  ),
              ]),
            ]),
          ),
        );
      },
    );
  }
}
