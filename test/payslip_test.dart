import 'package:flutter_test/flutter_test.dart';
import 'package:royal_marble/models/attendance.dart';
import 'package:royal_marble/models/pay_calc.dart';
import 'package:royal_marble/models/payslip.dart';
import 'package:royal_marble/models/salary.dart';
import 'package:royal_marble/services/checkin_service.dart' show SiteKind;

WorkSession stay(DateTime start, [DateTime? end]) => WorkSession(
    siteId: 's', kind: SiteKind.project, siteName: 'Site', start: start, end: end);

DateTime at(int day, int h, [int m = 0]) => DateTime(2026, 9, day, h, m);

void main() {
  // AED 2,900 a month for 48 h a week (208 h a month), AED 15 per overtime hour.
  const pkg = SalaryPackage(
      basic: 1800, housing: 500, transport: 200, food: 400, overtimeRate: 15);
  final september = DateTime(2026, 9);
  final afterMonth = DateTime(2026, 10, 2, 9);
  const approved =
      OvertimeDecision(status: OvertimeStatus.approved, minutes: 90, rate: 15);

  PaySoFar pay(Map<DateTime, DayEntry> days,
          [Map<DateTime, OvertimeDecision> decisions = const {}]) =>
      paySoFar(pkg, days, decisions, afterMonth);

  // 8:00–18:30 on the 5th (90 min overtime), 8:00–17:00 on the 6th.
  final days = {
    at(5, 0): DayEntry([stay(at(5, 8), at(5, 18, 30))]),
    at(6, 0): DayEntry([stay(at(6, 8), at(6, 17))]),
  };

  test('approved overtime is its own line and part of the total', () {
    final f = payslipFields(
        uid: 'u1',
        name: 'Ravi',
        month: september,
        package: pkg,
        pay: pay(days, {at(5, 0): approved}));
    final slip = Payslip.fromMap(f);
    expect(f['status'], 'locked');
    expect([slip.year, slip.month, slip.daysWorked], [2026, 9, 2]);
    expect([slip.regularMinutes, slip.overtimeMinutes], [540 + 540, 90]);
    expect(slip.regularPay, closeTo(2900 / 208 * 18, 0.005));
    expect(slip.overtimePay, 22.5);
    expect(slip.total, closeTo(slip.regularPay + slip.overtimePay, 1e-9));
  });

  test('payslip ids are per worker and month', () {
    expect(payslipDocId('u1', DateTime(2026, 9, 30)), 'u1_9-2026');
  });

  group('payroll state', () {
    test('the current month can\'t be approved yet', () {
      expect(
          payrollState(
              month: september, now: DateTime(2026, 9, 30, 23), pay: pay(days)),
          PayrollState.monthNotOver);
    });
    test('overtime waiting blocks approval', () {
      expect(payrollState(month: september, now: afterMonth, pay: pay(days)),
          PayrollState.overtimeWaiting);
    });
    test('all overtime decided: ready', () {
      expect(
          payrollState(
              month: september, now: afterMonth, pay: pay(days, {at(5, 0): approved})),
          PayrollState.ready);
    });
    test('a stay never checked out blocks approval', () {
      final open = {at(7, 0): DayEntry([stay(at(7, 8))])};
      expect(payrollState(month: september, now: afterMonth, pay: pay(open)),
          PayrollState.unclosedStay);
    });
    test('no check-ins all month: no attendance, not ready', () {
      expect(payrollState(month: september, now: afterMonth, pay: pay(const {})),
          PayrollState.noAttendance);
    });
    test('no pay package', () {
      expect(payrollState(month: september, now: afterMonth),
          PayrollState.noPayDetails);
    });
    test('locked payslip is approved; a reopened one is worked out again', () {
      final f = payslipFields(
          uid: 'u1',
          name: 'Ravi',
          month: september,
          package: pkg,
          pay: pay(days, {at(5, 0): approved}));
      expect(
          payrollState(
              month: september, now: afterMonth, slip: Payslip.fromMap(f)),
          PayrollState.approved);
      final reopened = Payslip.fromMap({...f, 'status': 'reopened'});
      expect(
          payrollState(
              month: september, now: afterMonth, pay: pay(days), slip: reopened),
          PayrollState.overtimeWaiting);
    });
  });
}
