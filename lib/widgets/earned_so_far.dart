import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../models/attendance.dart';
import '../models/leave.dart';
import '../models/pay_calc.dart';
import '../models/salary.dart';
import '../services/leave_service.dart';
import '../services/pay_service.dart';
import 'payslip_card.dart' show leavePayRows;

/// Loads one worker's month so far: their days, HR's overtime decisions
/// and their leave.
Future<PaySoFar> loadPaySoFar(String uid, SalaryPackage p) async {
  final now = DateTime.now();
  final range = PayService.monthToDate(now);
  final (loaded, leave) = await (
    PayService.loadDays(range, uid: uid),
    LeaveService.forWorker(uid).catchError((_) => <LeaveRequest>[]),
  ).wait;
  final days = loaded[uid]?.days ?? const <DateTime, DayEntry>{};
  final withOvertime = [
    for (final e in days.entries)
      if (dayPay(e.key, e.value, p, null, now).overtimeMinutes > 0) e.key
  ];
  final decisions = await PayService.decisionsFor(uid, withOvertime);
  return paySoFar(p, days, decisions, now,
      leave: leave, from: range.start, to: range.end);
}

/// "Earned so far this month": regular time at the hourly rate plus approved
/// overtime; overtime waiting for HR is shown but not counted. Used in My
/// pay (the worker) and on the worker's page (HR and admins).
class EarnedSoFar extends StatefulWidget {
  const EarnedSoFar({super.key, required this.uid, required this.package});
  final String uid;
  final SalaryPackage package;

  @override
  State<EarnedSoFar> createState() => _EarnedSoFarState();
}

class _EarnedSoFarState extends State<EarnedSoFar> {
  late Future<PaySoFar> _pay = loadPaySoFar(widget.uid, widget.package);

  @override
  void didUpdateWidget(EarnedSoFar old) {
    super.didUpdateWidget(old);
    // A new rate, day end or hours changes the numbers.
    if (old.package.toMap().toString() != widget.package.toMap().toString()) {
      _pay = loadPaySoFar(widget.uid, widget.package);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cur = widget.package.currency;
    String h(int minutes) => localizedDuration(l, Duration(minutes: minutes));

    return FutureBuilder<PaySoFar>(
      future: _pay,
      builder: (context, snap) {
        if (snap.hasError) {
          return Text(l.couldNotLoad, style: const TextStyle(color: AppColors.muted));
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final pay = snap.data!;
        Widget row(String label, String amount, {bool muted = false}) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(
                  child: Text(label,
                      style: TextStyle(color: muted ? AppColors.muted : AppColors.ink)),
                ),
                Text(amount,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: muted ? AppColors.muted : AppColors.charcoal)),
              ]),
            );

        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.earnedSoFarTitle(DateFormat('MMMM', l.localeName).format(DateTime.now())),
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(money(pay.total, cur),
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.charcoal)),
          const SizedBox(height: 8),
          row('${l.regularTime} · ${h(pay.regularMinutes)}', money(pay.regularPay, cur)),
          if (pay.approvedOvertimeMinutes > 0)
            row('${l.approvedOvertime} · ${h(pay.approvedOvertimeMinutes)}',
                money(pay.overtimePay, cur)),
          if (pay.pendingOvertimeMinutes > 0)
            row('${l.overtimeWaitingHr} · ${h(pay.pendingOvertimeMinutes)}', l.notPaidYet,
                muted: true),
          if (pay.rejectedOvertimeMinutes > 0)
            row('${l.overtimeNotApproved} · ${h(pay.rejectedOvertimeMinutes)}', '—',
                muted: true),
          ...leavePayRows(l, row,
              currency: cur,
              paidDays: pay.paidLeaveDays,
              paidPay: pay.paidLeavePay,
              unpaidDays: pay.unpaidLeaveDays,
              sickFull: pay.sickDays(1),
              sickHalf: pay.sickDays(0.5),
              sickUnpaid: pay.sickDays(0),
              sickPay: pay.sickPay),
          if (pay.pendingLeave > 0)
            row(l.leaveWaitingHr, l.notPaidYet, muted: true),
          const SizedBox(height: 8),
          Text(
              l.hourlyRateNote(money(pay.hourlyRate, cur),
                  NumberFormat('0.#').format(monthlyHours(widget.package))),
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]);
      },
    );
  }
}
