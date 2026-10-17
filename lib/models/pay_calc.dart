import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'attendance.dart';
import 'leave.dart';
import 'salary.dart';

/// HR's answer about one worker's overtime on one day.
enum OvertimeStatus { pending, approved, rejected }

/// Stored at `overtime/{uid}_{d-m-yyyy}` (see [overtimeDocId]). [minutes] is
/// what HR saw when deciding; if attendance changes later the day goes back
/// to pending. [rate] is the overtime rate at that moment.
class OvertimeDecision {
  final OvertimeStatus status;
  final int minutes;
  final double rate;
  final String? note;
  final String? byName;
  final DateTime? at;

  const OvertimeDecision({
    required this.status,
    required this.minutes,
    required this.rate,
    this.note,
    this.byName,
    this.at,
  });

  factory OvertimeDecision.fromMap(Map<String, dynamic> m) => OvertimeDecision(
        status: OvertimeStatus.values.asNameMap()[m['status']] ??
            OvertimeStatus.pending,
        minutes: (m['minutes'] as num?)?.toInt() ?? 0,
        rate: (m['rate'] as num?)?.toDouble() ?? 0,
        note: m['note'] as String?,
        byName: m['byName'] as String?,
        at: (m['at'] as Timestamp?)?.toDate(),
      );
}

String overtimeDocId(String uid, DateTime day) =>
    '${uid}_${day.day}-${day.month}-${day.year}';

/// Contracted hours in an average month: 48 h a week → 208 h.
double monthlyHours(SalaryPackage p) => p.weeklyHours * 52 / 12;

/// Hours in one working day (a sixth of the week), what a paid leave day
/// is worth in time.
double dayHours(SalaryPackage p) => p.weeklyHours / 6;

/// What one regular hour is worth, allowances included (they are monthly
/// amounts, spread over the month's hours).
double hourlyRate(SalaryPackage p) {
  final hours = monthlyHours(p);
  if (hours <= 0) return 0;
  final allowances = p.monthlyAllowances / hours;
  return switch (p.payType) {
    PayType.monthly => (p.basic + p.monthlyAllowances) / hours,
    // A day is a sixth of the week's hours (UAE six-day week).
    PayType.daily => p.basic / (p.weeklyHours / 6) + allowances,
    PayType.hourly => p.basic + allowances,
  };
}

/// End of a stay for pay: the check-out, or "now" while it's open today. A
/// stay from an earlier day that was never closed counts as nothing until
/// someone corrects it.
DateTime? _until(WorkSession s, DateTime now) {
  if (s.end != null) return s.end;
  final started = DateTime(s.start.year, s.start.month, s.start.day);
  final today = DateTime(now.year, now.month, now.day);
  return s.isOpen && started == today ? now : null;
}

/// Minutes of [s] after the working day ended on the day it started.
int overtimeMinutesOf(WorkSession s, int dayEndMinutes, DateTime now) {
  final until = _until(s, now);
  if (until == null) return 0;
  final dayEnd = DateTime(s.start.year, s.start.month, s.start.day)
      .add(Duration(minutes: dayEndMinutes));
  final from = s.start.isAfter(dayEnd) ? s.start : dayEnd;
  return math.max(0, until.difference(from).inMinutes);
}

/// One worker's day for pay.
class DayPay {
  final DateTime day;
  final int workedMinutes;
  final int overtimeMinutes;
  final OvertimeDecision? decision;

  /// Stays from an earlier day that were never closed (they count nothing).
  final int unclosedStays;

  const DayPay(this.day, this.workedMinutes, this.overtimeMinutes, this.decision,
      {this.unclosedStays = 0});

  int get regularMinutes => workedMinutes - overtimeMinutes;

  /// The decision no longer matches the attendance (corrected afterwards).
  bool get changedSinceDecision =>
      decision != null && decision!.minutes != overtimeMinutes;

  OvertimeStatus get overtimeStatus => decision == null || changedSinceDecision
      ? OvertimeStatus.pending
      : decision!.status;
}

DayPay dayPay(DateTime day, DayEntry entry, SalaryPackage p,
    OvertimeDecision? decision, DateTime now) {
  var worked = 0, overtime = 0, unclosed = 0;
  for (final s in entry.sessions) {
    final until = _until(s, now);
    if (until == null) unclosed++;
    if (until == null || !until.isAfter(s.start)) continue;
    worked += until.difference(s.start).inMinutes;
    overtime += overtimeMinutesOf(s, p.dayEndMinutes, now);
  }
  return DayPay(day, worked, math.min(overtime, worked), decision,
      unclosedStays: unclosed);
}

/// Pay earned over a period (the month so far): regular hours at the hourly
/// rate, approved overtime at the rate HR approved it with, and approved
/// leave (paid annual/emergency days, sick days by tier) at a working day
/// each.
class PaySoFar {
  final double hourlyRate;
  final List<DayPay> days;
  final double overtimeRate;
  final List<LeaveDay> leave;

  /// Leave requests in the period still waiting for HR.
  final int pendingLeave;

  /// Hours one paid leave day is worth.
  final double leaveDayHours;

  PaySoFar(this.hourlyRate, this.days, this.overtimeRate,
      {this.leave = const [], this.pendingLeave = 0, this.leaveDayHours = 8});

  int _sum(int Function(DayPay d) f) => days.fold(0, (t, d) => t + f(d));
  int _overtime(OvertimeStatus s) =>
      _sum((d) => d.overtimeStatus == s ? d.overtimeMinutes : 0);

  int get regularMinutes => _sum((d) => d.regularMinutes);
  int get approvedOvertimeMinutes => _overtime(OvertimeStatus.approved);
  int get pendingOvertimeMinutes => _overtime(OvertimeStatus.pending);
  int get rejectedOvertimeMinutes => _overtime(OvertimeStatus.rejected);
  int get unclosedStays => _sum((d) => d.unclosedStays);
  int get daysWorked => days.where((d) => d.workedMinutes > 0).length;

  double get regularPay => hourlyRate * regularMinutes / 60;
  double get overtimePay => days.fold(0.0, (t, d) {
        if (d.overtimeStatus != OvertimeStatus.approved) return t;
        return t + d.decision!.rate * d.overtimeMinutes / 60;
      });

  /// What pending overtime would add if HR approves it at today's rate.
  double get pendingOvertimePay => overtimeRate * pendingOvertimeMinutes / 60;

  Iterable<LeaveDay> _leave(bool Function(LeaveDay d) f) =>
      leave.where((d) => !d.worked && f(d));
  bool _vacation(LeaveDay d) => d.type != LeaveType.sick;

  int get paidLeaveDays => _leave((d) => _vacation(d) && d.factor > 0).length;
  int get unpaidLeaveDays => _leave((d) => _vacation(d) && d.factor == 0).length;
  int sickDays(double factor) =>
      _leave((d) => d.type == LeaveType.sick && d.factor == factor).length;

  double _leavePay(bool Function(LeaveDay d) f) =>
      _leave(f).fold(0.0, (t, d) => t + hourlyRate * leaveDayHours * d.factor);
  double get paidLeavePay => _leavePay(_vacation);
  double get sickPay => _leavePay((d) => d.type == LeaveType.sick);

  double get total => regularPay + overtimePay + paidLeavePay + sickPay;
}

/// [leave] (the worker's requests) counts only with [from] and [to], the
/// period [days] covers; see [leaveDaysFor] for what it should hold.
PaySoFar paySoFar(SalaryPackage p, Map<DateTime, DayEntry> days,
    Map<DateTime, OvertimeDecision> decisions, DateTime now,
    {List<LeaveRequest> leave = const [], DateTime? from, DateTime? to}) {
  final list = [
    for (final e in days.entries)
      dayPay(e.key, e.value, p, decisions[e.key], now)
  ]..sort((a, b) => a.day.compareTo(b.day));
  if (from == null || to == null) return PaySoFar(hourlyRate(p), list, p.overtimeRate);
  final worked = {for (final d in list) if (d.workedMinutes > 0) d.day};
  return PaySoFar(hourlyRate(p), list, p.overtimeRate,
      leave: leaveDaysFor(leave, p, from, to, workedDays: worked),
      pendingLeave: leave.where((r) => r.isPending && r.overlaps(from, to)).length,
      leaveDayHours: dayHours(p));
}
