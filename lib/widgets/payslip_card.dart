import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../models/payslip.dart';

/// A month's pay: regular time and approved overtime as separate lines,
/// both in the total. Shows an approved payslip, or what approving would
/// save.
class PayslipBreakdown extends StatelessWidget {
  const PayslipBreakdown(this.slip,
      {super.key, this.showApproval = true, this.showReopenings = true});
  final Payslip slip;

  /// Adds who approved it (only for saved payslips).
  final bool showApproval;

  /// Adds earlier reopenings and their reasons (office only, not the worker).
  final bool showReopenings;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cur = slip.currency;
    final date = DateFormat('d MMM yyyy', l.localeName);
    String h(int minutes) => localizedDuration(l, Duration(minutes: minutes));
    Widget row(String label, String value, {bool muted = false, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: muted ? AppColors.muted : AppColors.ink,
                      fontWeight: bold ? FontWeight.w700 : null)),
            ),
            Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    fontSize: bold ? 17 : null,
                    color: muted ? AppColors.muted : AppColors.charcoal)),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      row(l.daysWorked, '${slip.daysWorked}'),
      row('${l.regularTime} · ${h(slip.regularMinutes)}', money(slip.regularPay, cur)),
      if (slip.overtimeMinutes > 0)
        row('${l.approvedOvertime} · ${h(slip.overtimeMinutes)}', money(slip.overtimePay, cur)),
      if (slip.rejectedOvertimeMinutes > 0)
        row('${l.overtimeNotApproved} · ${h(slip.rejectedOvertimeMinutes)}', '—', muted: true),
      const Divider(height: 20),
      row(l.totalPay, money(slip.total, cur), bold: true),
      const SizedBox(height: 4),
      Text(
          '${l.hourlyRateLabel} ${money(slip.hourlyRate, cur)} · '
          '${NumberFormat('0.#').format(slip.monthlyHours)} h',
          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      if (showApproval && slip.approvedByName != null && slip.isLocked) ...[
        const SizedBox(height: 4),
        Text(
            l.approvedByOn(
                slip.approvedByName!, slip.approvedAt == null ? '' : date.format(slip.approvedAt!)),
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
      if (showApproval && showReopenings)
        for (final r in slip.reopened)
          Text(l.reopenedByOn(r.byName, r.at == null ? '' : date.format(r.at!), r.reason),
              style: const TextStyle(fontSize: 12, color: AppColors.warn)),
    ]);
  }
}
