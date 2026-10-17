import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:royal_marble/models/attendance.dart';
import 'package:royal_marble/models/leave.dart';
import 'package:royal_marble/models/pay_calc.dart';
import 'package:royal_marble/models/payslip.dart';
import 'package:royal_marble/models/salary.dart';
import 'package:royal_marble/services/checkin_service.dart' show SiteKind;

DateTime d(int month, int day) => DateTime(2026, month, day);

LeaveRequest req(LeaveType type, DateTime from, DateTime to,
        {LeaveStatus status = LeaveStatus.approved, bool paid = true}) =>
    LeaveRequest(uid: 'w', name: 'W', type: type, from: from, to: to, status: status, paid: paid);

void main() {
  // AED 2,080 a month for 48 h a week: 10 an hour, a day of 8 h is AED 80.
  const pkg = SalaryPackage(basic: 2080, annualLeaveDays: 30, emergencyLeaveDays: 5);

  group('days counted', () {
    test('the weekly day off is skipped', () {
      // Thu 1 Oct – Wed 7 Oct 2026; Sunday the 4th is off.
      expect(leaveDaysIn(d(10, 1), d(10, 7), DateTime.sunday).length, 6);
      expect(leaveDaysIn(d(10, 1), d(10, 7), DateTime.friday).map((x) => x.day),
          [1, 3, 4, 5, 6, 7]);
    });
    test('the months a request touches', () {
      expect(req(LeaveType.annual, d(10, 28), d(12, 2)).months,
          ['10-2026', '11-2026', '12-2026']);
    });
  });

  group('stored request', () {
    final base = {
      'uid': 'w', 'type': 'annual', 'status': 'pending',
      'from': Timestamp.fromDate(d(10, 5)), 'to': Timestamp.fromDate(d(10, 6)),
    };
    test('travel and several reports read back', () {
      final r = LeaveRequest.fromMap('x', {
        ...base,
        'travel': {'from': 'Dubai', 'to': 'Kathmandu', 'companyTicket': true},
        'reports': [
          {'path': 'leave_reports/w/1', 'name': 'a.pdf', 'contentType': 'application/pdf'},
          {'path': 'leave_reports/w/2', 'name': 'b.jpg', 'contentType': 'image/jpeg'},
        ],
      });
      expect([r.travel!.from, r.travel!.to, r.travel!.companyTicket], ['Dubai', 'Kathmandu', true]);
      expect(r.reports.map((x) => x.isPdf), [true, false]);
    });
    test('an older single report still reads; no travel is null', () {
      final r = LeaveRequest.fromMap('x', {
        ...base,
        'report': {'path': 'leave_reports/w/1', 'name': 'a.pdf', 'contentType': 'application/pdf'},
      });
      expect([r.reports.length, r.travel], [1, null]);
    });
  });

  group('balances', () {
    final requests = [
      req(LeaveType.annual, d(10, 1), d(10, 7)), // 6 days
      req(LeaveType.annual, d(11, 2), d(11, 3), status: LeaveStatus.pending),
      req(LeaveType.annual, d(11, 9), d(11, 10), status: LeaveStatus.rejected),
      req(LeaveType.emergency, d(10, 12), d(10, 12)),
    ];
    test('approved days come off the allowance; pending shown apart', () {
      final b = leaveBalance(LeaveType.annual, 2026, requests, pkg);
      expect([b.allowance, b.approved, b.pending, b.left], [30, 6, 2, 24]);
      expect(leaveBalance(LeaveType.emergency, 2026, requests, pkg).left, 4);
    });
    test('a request over New Year counts in each year for its own days', () {
      final b = leaveBalance(LeaveType.annual, 2027,
          [req(LeaveType.annual, DateTime(2026, 12, 29), DateTime(2027, 1, 2))], pkg);
      expect(b.approved, 2); // 1 and 2 Jan 2027
    });
  });

  group('sick tiers', () {
    test('15 days full, 30 half, then unpaid', () {
      expect([sickPayFactor(15), sickPayFactor(16), sickPayFactor(45), sickPayFactor(46)],
          [1, 0.5, 0.5, 0]);
    });
    test('the package can set other tiers', () {
      const p = SalaryPackage(sickFullDays: 10, sickHalfDays: 5, sickUnpaidDays: 0);
      expect([sickPayFactor(10, p), sickPayFactor(11, p), sickPayFactor(16, p)], [1, 0.5, 0]);
      expect(leaveBalance(LeaveType.sick, 2026, const [], p).allowance, 15);
      expect(leaveBalance(LeaveType.sick, 2026, const [], const SalaryPackage()).allowance, 90);
    });
    test('UAE annual leave by service', () {
      final asOf = d(10, 17);
      expect(lawAnnualLeaveDays(null, asOf), null);
      expect(lawAnnualLeaveDays(d(5, 1), asOf), 0); // 5 months
      expect(lawAnnualLeaveDays(d(4, 17), asOf), 12); // 6 months: 2 a month
      expect(lawAnnualLeaveDays(d(4, 18), asOf), 0); // a day short of 6 months
      expect(lawAnnualLeaveDays(DateTime(2025, 11, 1), asOf), 22); // 11 months
      expect(lawAnnualLeaveDays(DateTime(2025, 10, 17), asOf), 30); // one year
    });
    test('earlier sick days in the year move the tier', () {
      const allDays = SalaryPackage(basic: 2080, weeklyOffDay: 0); // no day off
      final days = leaveDaysFor([
        req(LeaveType.sick, d(1, 1), d(1, 14)), // 14 days in January
        req(LeaveType.sick, d(3, 1), d(3, 3)),
      ], allDays, d(3, 1), d(3, 31));
      expect(days.map((x) => x.factor), [1, 0.5, 0.5]);
    });
  });

  group('pay', () {
    WorkSession stay(DateTime start, DateTime end) => WorkSession(
        siteId: 's', kind: SiteKind.project, siteName: 'Site', start: start, end: end);
    final now = d(11, 5);

    PaySoFar october(List<LeaveRequest> leave, [Map<DateTime, DayEntry> days = const {}]) =>
        paySoFar(pkg, days, const {}, now, leave: leave, from: d(10, 1), to: d(10, 31));

    test('paid leave adds a working day each; unpaid adds nothing', () {
      final pay = october([
        req(LeaveType.annual, d(10, 5), d(10, 6)),
        req(LeaveType.emergency, d(10, 7), d(10, 7), paid: false),
      ]);
      expect([pay.paidLeaveDays, pay.unpaidLeaveDays], [2, 1]);
      expect(pay.paidLeavePay, closeTo(160, 1e-9));
      expect(pay.total, closeTo(160, 1e-9));
    });
    test('sick pay by tier', () {
      final pay = october([req(LeaveType.sick, d(10, 1), d(10, 20))]); // 17 days (3 Sundays)
      expect([pay.sickDays(1), pay.sickDays(0.5)], [15, 2]);
      expect(pay.sickPay, closeTo(15 * 80 + 2 * 40, 1e-9));
    });
    test('a leave day the worker checked in is paid as work only', () {
      final pay = october([req(LeaveType.annual, d(10, 5), d(10, 6))], {
        d(10, 5): DayEntry([stay(DateTime(2026, 10, 5, 8), DateTime(2026, 10, 5, 12))]),
      });
      expect(pay.paidLeaveDays, 1);
      expect(pay.total, closeTo(40 + 80, 1e-9));
    });
    test('leave outside the period is left out; pending is counted', () {
      final pay = october([
        req(LeaveType.annual, d(11, 2), d(11, 3)),
        req(LeaveType.annual, d(10, 30), d(11, 2), status: LeaveStatus.pending),
      ]);
      expect([pay.leave.length, pay.pendingLeave], [0, 1]);
    });
    test('payslip lines add up and pending leave blocks approval', () {
      final pay = october([
        req(LeaveType.annual, d(10, 5), d(10, 5)),
        req(LeaveType.sick, d(10, 8), d(10, 8)),
      ]);
      final f = payslipFields(uid: 'w', name: 'W', month: d(10, 1), package: pkg, pay: pay);
      expect([f['paidLeavePay'], f['sickPay'], f['total']], [80.0, 80.0, 160.0]);
      expect(payrollState(month: d(10, 1), now: now, pay: pay), PayrollState.ready);
      final waiting = october(
          [req(LeaveType.annual, d(10, 5), d(10, 5), status: LeaveStatus.pending)]);
      expect(payrollState(month: d(10, 1), now: now, pay: waiting), PayrollState.leaveWaiting);
    });
  });
}
