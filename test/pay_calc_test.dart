import 'package:flutter_test/flutter_test.dart';
import 'package:royal_marble/models/attendance.dart';
import 'package:royal_marble/models/pay_calc.dart';
import 'package:royal_marble/models/salary.dart';
import 'package:royal_marble/services/checkin_service.dart' show SiteKind;

WorkSession stay(DateTime start, [DateTime? end]) => WorkSession(
    siteId: 's', kind: SiteKind.project, siteName: 'Site', start: start, end: end);

DateTime at(int day, int h, [int m = 0]) => DateTime(2026, 10, day, h, m);

void main() {
  // AED 2,900 a month for 48 h a week (208 h a month), AED 15 per overtime hour.
  const pkg = SalaryPackage(
      basic: 1800, housing: 500, transport: 200, food: 400, overtimeRate: 15);
  final now = at(12, 12);

  group('hourly rate', () {
    test('monthly pay: total ÷ monthly hours', () {
      expect(monthlyHours(pkg), 208);
      expect(hourlyRate(pkg), closeTo(2900 / 208, 1e-9));
    });
    test('daily pay: a day is a sixth of the weekly hours', () {
      const daily = SalaryPackage(payType: PayType.daily, basic: 80);
      expect(hourlyRate(daily), closeTo(10, 1e-9)); // 80 ÷ 8 h
    });
    test('hourly pay: the basic, plus allowances spread over the month', () {
      const hourly = SalaryPackage(payType: PayType.hourly, basic: 12, housing: 208);
      expect(hourlyRate(hourly), closeTo(13, 1e-9));
    });
  });

  group('a day', () {
    test('time after the day end is overtime', () {
      final d = dayPay(at(5, 0), DayEntry([stay(at(5, 8), at(5, 18, 30))]), pkg, null, now);
      expect([d.workedMinutes, d.overtimeMinutes, d.regularMinutes], [630, 90, 540]);
      expect(d.overtimeStatus, OvertimeStatus.pending);
    });
    test('a stay that starts after the day end is all overtime', () {
      final d = dayPay(at(5, 0), DayEntry([stay(at(5, 8), at(5, 12)), stay(at(5, 19), at(5, 21))]),
          pkg, null, now);
      expect([d.workedMinutes, d.overtimeMinutes], [360, 120]);
    });
    test('a later day end moves the overtime', () {
      final late = dayPay(at(5, 0), DayEntry([stay(at(5, 8), at(5, 18, 30))]),
          const SalaryPackage(dayEndMinutes: 18 * 60), null, now);
      expect(late.overtimeMinutes, 30);
    });
    test('an open stay today counts until now', () {
      final d = dayPay(at(12, 0), DayEntry([stay(at(12, 8))]), pkg, null, now);
      expect([d.workedMinutes, d.overtimeMinutes], [240, 0]);
    });
    test('a past stay never checked out counts as nothing until corrected', () {
      final d = dayPay(at(5, 0), DayEntry([stay(at(5, 8))]), pkg, null, now);
      expect(d.workedMinutes, 0);
    });
  });

  group('month so far', () {
    final days = {
      at(5, 0): DayEntry([stay(at(5, 8), at(5, 18))]), // 600 min, 60 overtime
      at(6, 0): DayEntry([stay(at(6, 8), at(6, 17))]), // 540 min, none
      at(7, 0): DayEntry([stay(at(7, 8), at(7, 19))]), // 660 min, 120 overtime
    };
    OvertimeDecision decided(OvertimeStatus s, int minutes, {double rate = 15}) =>
        OvertimeDecision(status: s, minutes: minutes, rate: rate);

    test('nothing decided: regular hours paid, overtime pending', () {
      final pay = paySoFar(pkg, days, const {}, now);
      expect(pay.regularMinutes, 540 + 540 + 540);
      expect(pay.pendingOvertimeMinutes, 180);
      expect(pay.overtimePay, 0);
      expect(pay.regularPay, closeTo(2900 / 208 * 27, 1e-9));
      expect(pay.pendingOvertimePay, closeTo(45, 1e-9));
    });
    test('approved overtime is paid at the rate it was approved with', () {
      final pay = paySoFar(pkg, days, {
        at(5, 0): decided(OvertimeStatus.approved, 60, rate: 20),
        at(7, 0): decided(OvertimeStatus.rejected, 120),
      }, now);
      expect([pay.approvedOvertimeMinutes, pay.rejectedOvertimeMinutes, pay.pendingOvertimeMinutes],
          [60, 120, 0]);
      expect(pay.overtimePay, closeTo(20, 1e-9));
      expect(pay.total, closeTo(pay.regularPay + 20, 1e-9));
    });
    test('attendance changed after approval goes back to pending', () {
      final pay = paySoFar(pkg, days, {at(7, 0): decided(OvertimeStatus.approved, 90)}, now);
      final day7 = pay.days.firstWhere((d) => d.day == at(7, 0));
      expect(day7.changedSinceDecision, isTrue);
      expect(day7.overtimeStatus, OvertimeStatus.pending);
      expect(pay.overtimePay, 0);
    });
  });
}
