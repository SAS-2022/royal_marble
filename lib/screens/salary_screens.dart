import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../models/salary.dart';
import '../models/user_model.dart';
import '../services/payroll_service.dart';
import '../widgets/status_widgets.dart';

final _money = NumberFormat('#,##0.##');
String money(double v, String currency) => '$currency ${_money.format(v)}';

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
                ? const Text('Pay details are not available yet.',
                    style: TextStyle(color: AppColors.muted))
                : !snap.hasData && snap.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (p == null || p.isEmpty)
                            const Text('No pay details yet.',
                                style: TextStyle(color: AppColors.muted))
                          else
                            SalaryBreakdown(p),
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
                              label: Text(p == null ? 'Set pay details' : 'Edit pay details'),
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

class _SalaryEditorScreenState extends State<SalaryEditorScreen> {
  final _form = GlobalKey<FormState>();
  late PayType _type = widget.initial.payType;
  late DateTime _from = widget.initial.effectiveFrom ?? DateTime.now();
  late final _basic = _ctrl(widget.initial.basic);
  late final _housing = _ctrl(widget.initial.housing);
  late final _transport = _ctrl(widget.initial.transport);
  late final _food = _ctrl(widget.initial.food);
  late final _notes = TextEditingController(text: widget.initial.notes);
  late final List<(TextEditingController, TextEditingController)> _other = [
    for (final a in widget.initial.other)
      (TextEditingController(text: a.name), _ctrl(a.amount))
  ];
  bool _saving = false;

  static TextEditingController _ctrl(double v) =>
      TextEditingController(text: v == 0 ? '' : _money.format(v).replaceAll(',', ''));

  static double _val(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  SalaryPackage get _package => SalaryPackage(
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
        effectiveFrom: DateTime(_from.year, _from.month, _from.day),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );

  Future<void> _save() async {
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.ok, content: Text('Pay details saved')));
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
            if (t.isEmpty) return required ? 'Required' : null;
            final n = double.tryParse(t);
            return n == null || n < 0 ? 'Enter a valid amount' : null;
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = _package;
    return Scaffold(
      appBar: AppBar(
          title: Text('Pay · ${widget.user.firstName ?? ''} ${widget.user.lastName ?? ''}')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<PayType>(
              segments: const [
                ButtonSegment(value: PayType.monthly, label: Text('Monthly')),
                ButtonSegment(value: PayType.daily, label: Text('Daily')),
                ButtonSegment(value: PayType.hourly, label: Text('Hourly')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            _amount(_basic, 'Basic ${_type.unit}', required: true),
            const SectionTitle('Monthly allowances'),
            _amount(_housing, 'Housing'),
            _amount(_transport, 'Transportation'),
            _amount(_food, 'Food'),
            for (final (i, (name, amount)) in _other.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: name,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Allowance'),
                      validator: (v) => (v ?? '').trim().isEmpty && _val(amount) > 0
                          ? 'Name it'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: _amount(amount, 'Amount')),
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
                label: const Text('Add another allowance'),
              ),
            ),
            const SectionTitle('Details'),
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
                decoration: const InputDecoration(
                    labelText: 'Effective from', suffixIcon: Icon(Icons.event)),
                child: Text(DateFormat('d MMM yyyy').format(_from)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SectionTitle('Summary'),
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
                  : const Text('Save pay details'),
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
