import 'package:cloud_firestore/cloud_firestore.dart';

import 'pay_calc.dart';
import 'salary.dart';

/// A worker's month as HR approved it, stored at `payslips/{uid}_{m-yyyy}`
/// (see [payslipDocId]). The numbers are a snapshot: later changes to the
/// pay package or attendance don't move them. While [isLocked], attendance
/// corrections and overtime decisions in that month are refused; an admin
/// can reopen it with a reason, and HR approves it again.
enum PayslipStatus { locked, reopened }

String payslipDocId(String uid, DateTime month) => '${uid}_${month.month}-${month.year}';

/// Who reopened an approved month, and why.
class Reopening {
  final String byName;
  final DateTime? at;
  final String reason;
  const Reopening(this.byName, this.at, this.reason);

  factory Reopening.fromMap(Map m) =>
      Reopening('${m['byName'] ?? ''}', (m['at'] as Timestamp?)?.toDate(), '${m['reason'] ?? ''}');
}

class Payslip {
  final String uid;
  final String name;
  final int year;
  final int month;
  final PayslipStatus status;
  final String currency;
  final String payType;
  final double hourlyRate;
  final double monthlyHours;
  final int daysWorked;
  final int regularMinutes;
  final double regularPay;
  final int overtimeMinutes;
  final double overtimePay;
  final int rejectedOvertimeMinutes;
  final double total;
  final String? approvedByName;
  final DateTime? approvedAt;
  final List<Reopening> reopened;

  const Payslip({
    required this.uid,
    required this.name,
    required this.year,
    required this.month,
    required this.status,
    required this.currency,
    required this.payType,
    required this.hourlyRate,
    required this.monthlyHours,
    required this.daysWorked,
    required this.regularMinutes,
    required this.regularPay,
    required this.overtimeMinutes,
    required this.overtimePay,
    required this.rejectedOvertimeMinutes,
    required this.total,
    this.approvedByName,
    this.approvedAt,
    this.reopened = const [],
  });

  bool get isLocked => status == PayslipStatus.locked;
  DateTime get monthStart => DateTime(year, month);

  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;
  static int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

  factory Payslip.fromMap(Map<String, dynamic> m) => Payslip(
        uid: '${m['uid'] ?? ''}',
        name: '${m['name'] ?? ''}',
        year: _i(m['year']),
        month: _i(m['month']),
        status: PayslipStatus.values.asNameMap()[m['status']] ?? PayslipStatus.reopened,
        currency: m['currency'] as String? ?? 'AED',
        payType: m['payType'] as String? ?? PayType.monthly.name,
        hourlyRate: _d(m['hourlyRate']),
        monthlyHours: _d(m['monthlyHours']),
        daysWorked: _i(m['daysWorked']),
        regularMinutes: _i(m['regularMinutes']),
        regularPay: _d(m['regularPay']),
        overtimeMinutes: _i(m['overtimeMinutes']),
        overtimePay: _d(m['overtimePay']),
        rejectedOvertimeMinutes: _i(m['rejectedOvertimeMinutes']),
        total: _d(m['total']),
        approvedByName: m['approvedByName'] as String?,
        approvedAt: (m['approvedAt'] as Timestamp?)?.toDate(),
        reopened: [
          for (final r in (m['reopened'] as List?) ?? const [])
            if (r is Map) Reopening.fromMap(r)
        ],
      );
}

double _r2(double v) => (v * 100).roundToDouble() / 100;

/// The fields HR's approval writes for [pay] (the whole of [month]).
/// Approved overtime is its own line and part of the total; amounts are
/// rounded to fils so the parts add up to the total.
Map<String, dynamic> payslipFields({
  required String uid,
  required String name,
  required DateTime month,
  required SalaryPackage package,
  required PaySoFar pay,
}) {
  final regular = _r2(pay.regularPay);
  final overtime = _r2(pay.overtimePay);
  return {
    'uid': uid,
    'name': name,
    'year': month.year,
    'month': month.month,
    'status': PayslipStatus.locked.name,
    'currency': package.currency,
    'payType': package.payType.name,
    'hourlyRate': _r2(pay.hourlyRate),
    'monthlyHours': monthlyHours(package),
    'daysWorked': pay.daysWorked,
    'regularMinutes': pay.regularMinutes,
    'regularPay': regular,
    'overtimeMinutes': pay.approvedOvertimeMinutes,
    'overtimePay': overtime,
    'rejectedOvertimeMinutes': pay.rejectedOvertimeMinutes,
    'total': _r2(regular + overtime),
  };
}

/// Where a worker's month stands on the payroll page.
enum PayrollState {
  /// Approved and locked.
  approved,

  /// Can be approved now.
  ready,

  /// The month hasn't ended yet.
  monthNotOver,

  /// Overtime still waiting for approve or reject.
  overtimeWaiting,

  /// A stay with no check-out; correct it first.
  unclosedStay,

  /// No pay package.
  noPayDetails,
}

PayrollState payrollState({
  required DateTime month,
  required DateTime now,
  PaySoFar? pay,
  Payslip? slip,
}) {
  if (slip?.isLocked == true) return PayrollState.approved;
  if (pay == null) return PayrollState.noPayDetails;
  if (now.isBefore(DateTime(month.year, month.month + 1))) {
    return PayrollState.monthNotOver;
  }
  if (pay.pendingOvertimeMinutes > 0) return PayrollState.overtimeWaiting;
  if (pay.unclosedStays > 0) return PayrollState.unclosedStay;
  return PayrollState.ready;
}
