import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../account_settings/admin_user_view.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../core/roles.dart';
import '../l10n/app_localizations.dart';
import '../models/pay_calc.dart';
import '../models/payslip.dart';
import '../models/salary.dart';
import '../models/user_model.dart';
import '../reports/report_export.dart';
import '../services/pay_service.dart';
import '../shared/loading.dart';
import '../shared/save_launch_file.dart';
import '../widgets/payslip_card.dart';
import '../widgets/status_widgets.dart';
import 'overtime_screen.dart';

/// HR and admins: what everyone earned this month (or last month) from their
/// hours and approved overtime. Once a month has ended each worker's pay is
/// approved and locked (a payslip); an admin can reopen it. Excel export.
class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key, required this.users, required this.viewer});
  final List<UserData> users;
  final UserData viewer;

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _Line {
  final UserData user;
  final SalaryPackage? package;
  final PaySoFar? pay;
  final Payslip? slip;
  final PayrollState state;
  const _Line(this.user, this.package, this.pay, this.slip, this.state);

  String get name => _name(user);
  String get currency => slip?.currency ?? package?.currency ?? 'AED';

  /// What approving would save now (null without a pay package).
  Map<String, dynamic>? fields(DateTime month) => package == null || pay == null
      ? null
      : payslipFields(uid: user.uid!, name: name, month: month, package: package!, pay: pay!);

  /// The approved payslip, or a preview of one.
  Payslip? shown(DateTime month) {
    if (slip?.isLocked == true) return slip;
    final f = fields(month);
    return f == null ? null : Payslip.fromMap(f);
  }
}

String _name(UserData u) => '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim();

extension on PayrollState {
  String label(AppLocalizations l) => switch (this) {
        PayrollState.approved => l.payStateApproved,
        PayrollState.ready => l.payStateReady,
        PayrollState.monthNotOver => l.payStateMonthNotOver,
        PayrollState.overtimeWaiting => l.payStateOvertimeWaiting,
        PayrollState.unclosedStay => l.payStateUnclosedStay,
        PayrollState.noPayDetails => l.noPayDetails,
        PayrollState.noAttendance => l.payStateNoAttendance,
      };

  Tone get tone => switch (this) {
        PayrollState.approved => Tone.ok,
        PayrollState.ready || PayrollState.monthNotOver || PayrollState.noAttendance =>
          Tone.neutral,
        _ => Tone.warn,
      };

  IconData get icon => switch (this) {
        PayrollState.approved => Icons.lock_outline,
        PayrollState.ready => Icons.check_circle_outline,
        PayrollState.monthNotOver => Icons.schedule,
        PayrollState.noAttendance => Icons.event_busy,
        _ => Icons.error_outline,
      };
}

class _PayrollScreenState extends State<PayrollScreen> {
  bool _lastMonth = false;
  late Future<List<_Line>> _lines = _load();
  bool _approving = false;

  DateTime get _month {
    final now = DateTime.now();
    return _lastMonth ? DateTime(now.year, now.month - 1) : DateTime(now.year, now.month);
  }

  String get _viewerName => _name(widget.viewer);

  Future<List<_Line>> _load() async {
    final now = DateTime.now();
    final month = _month;
    final range = PayService.month(month, now);
    final (workers, packages, decisions, slips) = await (
      PayService.loadDays(range),
      PayService.packages(),
      PayService.decisionsIn(range),
      PayService.payslipsIn(month),
    ).wait;
    final lines = <_Line>[];
    for (final u in widget.users) {
      final uid = u.uid;
      if (uid == null) continue;
      final slip = slips[uid];
      final listed = slip != null ||
          (u.isActive == true &&
              primaryRole(u.roles).isTracked &&
              (packages.containsKey(uid) || workers.containsKey(uid)));
      if (!listed) continue;
      final package = packages[uid];
      final pay = package == null
          ? null
          : paySoFar(package, workers[uid]?.days ?? const {}, decisions[uid] ?? const {}, now);
      lines.add(
          _Line(u, package, pay, slip, payrollState(month: month, now: now, pay: pay, slip: slip)));
    }
    return lines..sort((a, b) => a.name.compareTo(b.name));
  }

  void _reload() => setState(() {
        _lines = _load();
      });

  Future<void> _export(List<_Line> lines) async {
    final month = _month;
    await saveAndLaunchFile(
      payrollXlsx(month: DateFormat('MMMM yyyy').format(month), lines: [
        for (final l in lines)
          (
            name: l.name,
            currency: l.currency,
            pay: l.slip?.isLocked == true ? null : l.pay,
            slip: l.slip?.isLocked == true ? l.slip : null,
            status: switch (l.state) {
              PayrollState.approved => 'Approved',
              PayrollState.ready => 'Ready to approve',
              PayrollState.monthNotOver => 'Month not over',
              PayrollState.overtimeWaiting => 'Overtime waiting',
              PayrollState.unclosedStay => 'Stay without check-out',
              PayrollState.noPayDetails => 'No pay details',
              PayrollState.noAttendance => 'No attendance',
            },
          )
      ]),
      'payroll_${DateFormat('yyyy-MM').format(month)}.xlsx',
    );
  }

  Future<void> _approveAll(List<_Line> ready) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.approveAllTitle(ready.length)),
        content: Text(l.approveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true), child: Text(l.approveAndLock)),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _approving = true);
    final error = await PayService.approve([for (final line in ready) line.fields(_month)!],
        byName: _viewerName);
    if (!mounted) return;
    setState(() => _approving = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(backgroundColor: AppColors.bad, content: Text(error)));
    }
    _reload();
  }

  Future<void> _open(_Line line) async {
    final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => _PayslipScreen(line: line, month: _month, viewer: widget.viewer)));
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String h(int minutes) => localizedDuration(l, Duration(minutes: minutes));
    return FutureBuilder<List<_Line>>(
      future: _lines,
      builder: (context, snap) {
        final lines = snap.data;
        final ready =
            lines?.where((x) => x.state == PayrollState.ready).toList() ?? const <_Line>[];
        return Scaffold(
          appBar: AppBar(
            title: Text(l.payroll),
            actions: [
              IconButton(
                tooltip: l.export,
                onPressed: lines == null ? null : () => _export(lines),
                icon: const Icon(Icons.ios_share),
              ),
            ],
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Wrap(spacing: 8, children: [
                for (final last in [false, true])
                  ChoiceChip(
                    label: Text(last ? l.lastMonth : l.thisMonth),
                    selected: _lastMonth == last,
                    onSelected: (_) {
                      _lastMonth = last;
                      _reload();
                    },
                  ),
              ]),
            ),
            if (ready.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: FilledButton.icon(
                  onPressed: _approving ? null : () => _approveAll(ready),
                  icon: const Icon(Icons.lock_outline),
                  label: Text(l.approveAllReady(ready.length)),
                ),
              ),
            Expanded(
              child: snap.hasError
                  ? Center(child: Text(l.couldNotLoad))
                  : lines == null
                      ? const Center(child: Loading())
                      : lines.isEmpty
                          ? Center(
                              child: Text(l.noPayrollYet,
                                  style: const TextStyle(color: AppColors.muted)))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                              itemCount: lines.length,
                              itemBuilder: (context, i) {
                                final line = lines[i];
                                final shown = line.shown(_month);
                                final pay = line.pay;
                                return Card(
                                  child: ListTile(
                                    onTap: () => _open(line),
                                    title: Text(line.name),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (shown != null)
                                          Text([
                                            '${l.regularTime} ${h(shown.regularMinutes)}',
                                            if (shown.overtimeMinutes > 0)
                                              '${l.approvedOvertime} ${h(shown.overtimeMinutes)}',
                                            if (line.slip?.isLocked != true &&
                                                (pay?.pendingOvertimeMinutes ?? 0) > 0)
                                              '${l.overtimeWaitingHr} ${h(pay!.pendingOvertimeMinutes)}',
                                          ].join(' · ')),
                                        const SizedBox(height: 6),
                                        StatusPill(line.state.label(l),
                                            tone: line.state.tone, icon: line.state.icon),
                                      ],
                                    ),
                                    trailing: shown == null
                                        ? null
                                        : Text(money(shown.total, line.currency),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700, fontSize: 15)),
                                  ),
                                );
                              },
                            ),
            ),
          ]),
        );
      },
    );
  }
}

/// One worker's month: the breakdown, and approve and lock (HR, admin) or
/// reopen (admin). Pops true when something changed.
class _PayslipScreen extends StatefulWidget {
  const _PayslipScreen({required this.line, required this.month, required this.viewer});
  final _Line line;
  final DateTime month;
  final UserData viewer;

  @override
  State<_PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<_PayslipScreen> {
  bool _saving = false;

  bool get _admin => primaryRole(widget.viewer.roles) == AppRole.admin;

  void _done(String? error) {
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(backgroundColor: AppColors.bad, content: Text(error)));
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _approve() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.approveAndLock),
        content: Text(l.approveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true), child: Text(l.approveAndLock)),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    _done(await PayService.approve([widget.line.fields(widget.month)!],
        byName: _name(widget.viewer)));
  }

  Future<void> _reopen() async {
    final l = context.l10n;
    final c = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(l.reopenTitle),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l.reopenBody),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              autofocus: true,
              decoration: InputDecoration(labelText: l.reopenReason),
              onChanged: (_) => setDialog(() {}),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
            FilledButton(
              onPressed: c.text.trim().isEmpty ? null : () => Navigator.pop(context, c.text.trim()),
              child: Text(l.reopen),
            ),
          ],
        ),
      ),
    );
    if (reason == null) return;
    setState(() => _saving = true);
    _done(await PayService.reopen(widget.line.slip!, reason: reason, byName: _name(widget.viewer)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final line = widget.line;
    final state = line.state;
    final shown = line.shown(widget.month);
    final slip = line.slip;
    Widget note(String text, {Color color = AppColors.muted}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(text, style: TextStyle(color: color)),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(line.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(DateFormat('MMMM yyyy', l.localeName).format(widget.month),
                style: const TextStyle(color: Colors.white70)),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusPill(state.label(l), tone: state.tone, icon: state.icon),
          ),
          const SizedBox(height: 12),
          if (shown != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PayslipBreakdown(shown, showApproval: slip?.isLocked == true),
              ),
            ),
          // A reopened month keeps its history while it's being redone.
          if (slip != null && !slip.isLocked)
            for (final r in slip.reopened)
              note(
                  l.reopenedByOn(
                      r.byName,
                      r.at == null ? '' : DateFormat('d MMM yyyy', l.localeName).format(r.at!),
                      r.reason),
                  color: AppColors.warn),
          const SizedBox(height: 8),
          switch (state) {
            PayrollState.approved => note(l.monthLocked),
            PayrollState.ready => FilledButton.icon(
                onPressed: _saving ? null : _approve,
                icon: const Icon(Icons.lock_outline),
                label: Text(l.approveAndLock),
              ),
            PayrollState.monthNotOver => note(l.approveAfterMonth),
            PayrollState.overtimeWaiting => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  note(l.decideOvertimeFirst, color: AppColors.warn),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => OvertimeScreen(viewer: widget.viewer))),
                    icon: const Icon(Icons.more_time),
                    label: Text(l.overtime),
                  ),
                ],
              ),
            PayrollState.unclosedStay => note(l.fixUnclosedFirst, color: AppColors.warn),
            PayrollState.noPayDetails => note(l.noPayDetails),
            PayrollState.noAttendance => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  note(l.noAttendanceNote),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _approve,
                    icon: const Icon(Icons.lock_outline),
                    label: Text(l.approveAndLock),
                  ),
                ],
              ),
          },
          if (state == PayrollState.approved && _admin) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.bad),
              onPressed: _saving ? null : _reopen,
              icon: const Icon(Icons.lock_open),
              label: Text(l.reopen),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => UserAdminScreen(user: line.user, viewer: widget.viewer))),
            icon: const Icon(Icons.person_outline),
            label: Text(l.workerPage),
          ),
        ],
      ),
    );
  }
}
