import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../models/payslip.dart';
import '../models/salary.dart';
import '../models/user_model.dart';
import '../services/pay_service.dart';
import '../services/payroll_service.dart';
import '../widgets/status_widgets.dart';
import '../widgets/time_wheel_picker.dart';
import '../widgets/earned_so_far.dart';
import '../widgets/payslip_card.dart';


/// Breakdown of a pay package; shows an empty state when none is set.
class SalaryBreakdown extends StatelessWidget {
  const SalaryBreakdown(this.p, {super.key});
  final SalaryPackage p;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget row(String label, double amount, {bool bold = false, String? suffix}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                      color: bold ? AppColors.charcoal : AppColors.ink)),
            ),
            Text('${money(amount, p.currency)}${suffix ?? ''}',
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    fontSize: bold ? 17 : 15)),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        StatusPill(p.payType.localized(l), icon: Icons.payments_outlined),
        const Spacer(),
        if (p.effectiveFrom != null)
          Text(l.effectiveFrom(DateFormat('d MMM yyyy', l.localeName).format(p.effectiveFrom!)),
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]),
      const SizedBox(height: 8),
      row(l.basic, p.basic, suffix: ' ${p.payType.localizedUnit(l)}'),
      if (p.housing > 0) row(l.housing, p.housing),
      if (p.transport > 0) row(l.transportation, p.transport),
      if (p.food > 0) row(l.food, p.food),
      for (final a in p.other) row(a.name, a.amount),
      if (p.monthlyAllowances > 0 && p.payType != PayType.monthly)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(l.allowancesMonthly,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ),
      if (p.monthlyTotal != null) ...[
        const Divider(height: 18),
        row(l.totalPerMonth, p.monthlyTotal!, bold: true),
      ],
      const SizedBox(height: 8),
      Text(
          l.workingTermsLine(
              _hours.format(p.weeklyHours),
              MaterialLocalizations.of(context).formatTimeOfDay(
                  TimeOfDay(hour: p.dayEndMinutes ~/ 60, minute: p.dayEndMinutes % 60),
                  alwaysUse24HourFormat: true),
              p.overtimeRate > 0
                  ? '${money(p.overtimeRate, p.currency)} ${l.perHour}'
                  : l.overtimeRateNotSet),
          style: const TextStyle(fontSize: 13, color: AppColors.muted)),
      const SizedBox(height: 4),
      Text(
          l.leaveTermsLine(p.annualLeaveDays, p.emergencyLeaveDays,
              weekdayName(p.weeklyOffDay, l.localeName)),
          style: const TextStyle(fontSize: 13, color: AppColors.muted)),
      if (p.notes?.isNotEmpty == true) ...[
        const SizedBox(height: 8),
        Text(p.notes!, style: const TextStyle(color: AppColors.muted)),
      ],
    ]);
  }
}

/// Salary section for the admin's view of a user.
class SalaryCard extends StatelessWidget {
  const SalaryCard({super.key, required this.user, required this.canEdit});
  final UserData user;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SalaryPackage?>(
      stream: PayrollService.watch(user.uid!),
      builder: (context, snap) {
        final p = snap.data;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: snap.hasError
                ? Text(context.l10n.payUnavailable,
                    style: TextStyle(color: AppColors.muted))
                : !snap.hasData && snap.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (p == null || p.isEmpty)
                            Text(context.l10n.noPayDetails,
                                style: TextStyle(color: AppColors.muted))
                          else ...[
                            SalaryBreakdown(p),
                            const Divider(height: 28),
                            EarnedSoFar(uid: user.uid!, package: p),
                          ],
                          if (canEdit) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SalaryEditorScreen(
                                      user: user,
                                      initial: p ?? const SalaryPackage()),
                                ),
                              ),
                              icon: Icon(p == null ? Icons.add : Icons.edit_outlined),
                              label: Text(p == null ? context.l10n.setPayDetails : context.l10n.editPayDetails),
                            ),
                          ],
                        ],
                      ),
          ),
        );
      },
    );
  }
}

/// Admin editor for a worker's pay package.
class SalaryEditorScreen extends StatefulWidget {
  const SalaryEditorScreen({super.key, required this.user, required this.initial});
  final UserData user;
  final SalaryPackage initial;

  @override
  State<SalaryEditorScreen> createState() => _SalaryEditorScreenState();
}

/// "48" or "47.5": hours without trailing zeros.
final _hours = NumberFormat('0.#');

class _SalaryEditorScreenState extends State<SalaryEditorScreen> {
  final _form = GlobalKey<FormState>();
  late PayType _type = widget.initial.payType;
  late DateTime _from = widget.initial.effectiveFrom ?? DateTime.now();
  late final _basic = _ctrl(widget.initial.basic);
  late final _housing = _ctrl(widget.initial.housing);
  late final _transport = _ctrl(widget.initial.transport);
  late final _food = _ctrl(widget.initial.food);
  late final _notes = TextEditingController(text: widget.initial.notes);
  late final _weeklyHours = TextEditingController(
      text: _hours.format(widget.initial.weeklyHours));
  late int _dayEnd = widget.initial.dayEndMinutes;
  late final _overtimeRate = _ctrl(widget.initial.overtimeRate);
  late final List<(TextEditingController, TextEditingController)> _other = [
    for (final a in widget.initial.other)
      (TextEditingController(text: a.name), _ctrl(a.amount))
  ];
  bool _saving = false;

  static TextEditingController _ctrl(double v) =>
      TextEditingController(text: v == 0 ? '' : NumberFormat('0.##').format(v));

  static double _val(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  // Leave settings are kept as they are (set on the leave entitlement screen).
  SalaryPackage get _package {
    final i = widget.initial;
    return _pay.withLeave(
        annualLeaveDays: i.annualLeaveDays,
        emergencyLeaveDays: i.emergencyLeaveDays,
        weeklyOffDay: i.weeklyOffDay,
        sickFullDays: i.sickFullDays,
        sickHalfDays: i.sickHalfDays,
        sickUnpaidDays: i.sickUnpaidDays,
        joinDate: i.joinDate);
  }

  SalaryPackage get _pay => SalaryPackage(
        currency: widget.initial.currency,
        payType: _type,
        basic: _val(_basic),
        housing: _val(_housing),
        transport: _val(_transport),
        food: _val(_food),
        other: [
          for (final (n, a) in _other)
            if (n.text.trim().isNotEmpty && _val(a) > 0)
              Allowance(n.text.trim(), _val(a))
        ],
        weeklyHours: double.tryParse(_weeklyHours.text.trim()) ??
            SalaryPackage.defaultWeeklyHours,
        dayEndMinutes: _dayEnd,
        overtimeRate: _val(_overtimeRate),
        effectiveFrom: DateTime(_from.year, _from.month, _from.day),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await PayrollService.save(widget.user.uid!, _package);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.bad, content: Text(error)));
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.ok, content: Text(l10n.paySaved)));
  }

  Widget _amount(TextEditingController c, String label, {bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: InputDecoration(
            labelText: label,
            prefixText: '${widget.initial.currency} ',
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) {
            final t = (v ?? '').replaceAll(',', '').trim();
            if (t.isEmpty) return required ? context.l10n.required : null;
            final n = double.tryParse(t);
            return n == null || n < 0 ? context.l10n.enterValidAmount : null;
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = _package;
    return Scaffold(
      appBar: AppBar(
          title: Text(context.l10n.payFor('${widget.user.firstName ?? ''} ${widget.user.lastName ?? ''}'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<PayType>(
              segments: [
                ButtonSegment(value: PayType.monthly, label: Text(context.l10n.monthly)),
                ButtonSegment(value: PayType.daily, label: Text(context.l10n.daily)),
                ButtonSegment(value: PayType.hourly, label: Text(context.l10n.hourly)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            _amount(_basic, '${context.l10n.basic} ${_type.localizedUnit(context.l10n)}', required: true),
            SectionTitle(context.l10n.monthlyAllowances),
            _amount(_housing, context.l10n.housing),
            _amount(_transport, context.l10n.transportation),
            _amount(_food, context.l10n.food),
            for (final (i, (name, amount)) in _other.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: name,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: context.l10n.allowance),
                      validator: (v) => (v ?? '').trim().isEmpty && _val(amount) > 0
                          ? context.l10n.nameIt
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: _amount(amount, context.l10n.amount)),
                  IconButton(
                    onPressed: () => setState(() => _other.removeAt(i)),
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.bad),
                  ),
                ]),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() =>
                    _other.add((TextEditingController(), TextEditingController()))),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.addAllowance),
              ),
            ),
            SectionTitle(context.l10n.workingHoursOvertime),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _weeklyHours,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: InputDecoration(
                    labelText: context.l10n.hoursPerWeek,
                    suffixText: context.l10n.hoursUnit),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  return n == null || n <= 0 || n > 84
                      ? context.l10n.enterValidHours
                      : null;
                },
              ),
            ),
            InkWell(
              onTap: () async {
                final t = await showTimeWheel(context,
                    initial: TimeOfDay(hour: _dayEnd ~/ 60, minute: _dayEnd % 60),
                    title: context.l10n.dayEndsAt);
                if (t != null) setState(() => _dayEnd = t.hour * 60 + t.minute);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                    labelText: context.l10n.dayEndsAt,
                    helperText: context.l10n.dayEndHint,
                    suffixIcon: const Icon(Icons.schedule)),
                child: Text(MaterialLocalizations.of(context).formatTimeOfDay(
                    TimeOfDay(hour: _dayEnd ~/ 60, minute: _dayEnd % 60),
                    alwaysUse24HourFormat: true)),
              ),
            ),
            const SizedBox(height: 12),
            _amount(_overtimeRate,
                '${context.l10n.overtimeRate} ${context.l10n.perHour}'),
            SectionTitle(context.l10n.details),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _from,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _from = d);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                    labelText: context.l10n.effectiveFromLabel,
                    suffixIcon: const Icon(Icons.event)),
                child: Text(DateFormat('d MMM yyyy', context.l10n.localeName).format(_from)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(labelText: context.l10n.notesOptional),
            ),
            SectionTitle(context.l10n.summary),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SalaryBreakdown(p),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(context.l10n.savePayDetails),
            ),
          ],
        ),
      ),
    );
  }
}

/// A worker's own read-only view of their pay package.
class MyPayScreen extends StatelessWidget {
  const MyPayScreen({super.key, required this.user});
  final UserData user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.myPay)),
      body: StreamBuilder<SalaryPackage?>(
        stream: PayrollService.watch(user.uid!),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snap.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (snap.hasError || p == null || p.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      const Icon(Icons.payments_outlined,
                          size: 40, color: AppColors.muted),
                      const SizedBox(height: 8),
                      Text(context.l10n.payNotAddedTitle,
                          textAlign: TextAlign.center),
                      Text(context.l10n.payNotAddedBody,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted)),
                    ]),
                  ),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: EarnedSoFar(uid: user.uid!, package: p),
                  ),
                ),
                _ApprovedPay(uid: user.uid!),
                SectionTitle(context.l10n.yourPackage),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SalaryBreakdown(p),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The worker's approved months (the last three), each opening to its
/// breakdown. Nothing shows until HR has approved a month.
class _ApprovedPay extends StatefulWidget {
  const _ApprovedPay({required this.uid});
  final String uid;

  @override
  State<_ApprovedPay> createState() => _ApprovedPayState();
}

class _ApprovedPayState extends State<_ApprovedPay> {
  late final Future<List<Payslip>> _slips = () {
    final now = DateTime.now();
    return PayService.payslipsFor(
        widget.uid, [for (var i = 1; i <= 3; i++) DateTime(now.year, now.month - i)]);
  }();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FutureBuilder<List<Payslip>>(
      future: _slips,
      builder: (context, snap) {
        final slips = snap.data?.where((s) => s.isLocked).toList() ?? const [];
        if (slips.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionTitle(l.approvedPay),
          for (final slip in slips)
            Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                shape: const Border(),
                leading: const Icon(Icons.lock_outline, color: AppColors.ok),
                title: Text(DateFormat('MMMM yyyy', l.localeName).format(slip.monthStart)),
                trailing: Text(money(slip.total, slip.currency),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.charcoal)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [PayslipBreakdown(slip, showReopenings: false)],
              ),
            ),
        ]);
      },
    );
  }
}
