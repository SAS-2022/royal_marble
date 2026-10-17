import 'package:cloud_firestore/cloud_firestore.dart';

import 'salary.dart';

/// Annual and emergency leave come out of their own yearly allowance (set
/// by HR on the pay package); sick leave needs a hospital report and is
/// paid by the UAE law tiers (see [sickPayFactor]).
enum LeaveType { annual, emergency, sick }

enum LeaveStatus { pending, approved, rejected, cancelled }

/// Most files a sick leave can carry (each up to 10 MB).
const maxLeaveReports = 5;

/// Longest request, so a request touches at most three months (the rules
/// check each month's payslip).
const maxLeaveDays = 60;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// `{m-yyyy}`, the month part of a payslip id.
String monthKey(DateTime d) => '${d.month}-${d.year}';

/// The days from [from] to [to] that count as leave: every day except the
/// worker's weekly day off ([offDay] is a [DateTime.weekday], 7 = Sunday).
List<DateTime> leaveDaysIn(DateTime from, DateTime to, int offDay) {
  final out = <DateTime>[];
  for (var d = _day(from); !d.isAfter(_day(to)); d = DateTime(d.year, d.month, d.day + 1)) {
    if (d.weekday != offDay) out.add(d);
  }
  return out;
}

/// The hospital report attached to a sick leave, in Storage at [path]
/// (`leave_reports/{uid}/…`).
class LeaveReport {
  final String path;
  final String name;
  final String contentType;
  const LeaveReport(this.path, this.name, this.contentType);

  bool get isPdf => contentType == 'application/pdf';

  Map<String, dynamic> toMap() => {'path': path, 'name': name, 'contentType': contentType};

  static LeaveReport? fromMap(dynamic m) => m is Map && m['path'] is String
      ? LeaveReport('${m['path']}', '${m['name'] ?? ''}', '${m['contentType'] ?? ''}')
      : null;
}

/// Travel for annual or emergency leave: where from and to, and whether
/// the company buys the ticket.
class LeaveTravel {
  final String from;
  final String to;
  final bool companyTicket;
  const LeaveTravel(this.from, this.to, this.companyTicket);

  Map<String, dynamic> toMap() => {'from': from, 'to': to, 'companyTicket': companyTicket};

  static LeaveTravel? fromMap(dynamic m) => m is Map
      ? LeaveTravel('${m['from'] ?? ''}', '${m['to'] ?? ''}', m['companyTicket'] == true)
      : null;
}

/// A request at `leave_requests/{auto}`. The worker creates it pending; HR
/// or an admin approves (picking [paid] for annual and emergency) or
/// rejects it; the worker can cancel it while it's pending.
class LeaveRequest {
  final String id;
  final String uid;
  final String name;
  final LeaveType type;
  final DateTime from;
  final DateTime to;
  final String reason;

  /// Hospital report files (sick leave).
  final List<LeaveReport> reports;

  /// Annual and emergency: null means no travel.
  final LeaveTravel? travel;
  final LeaveStatus status;

  /// Annual and emergency: HR's choice when approving. Sick leave is paid
  /// by the tiers instead, so this is ignored for it.
  final bool paid;
  final String? note;
  final String? byName;
  final DateTime? at;
  final DateTime? createdAt;

  const LeaveRequest({
    this.id = '',
    required this.uid,
    required this.name,
    required this.type,
    required this.from,
    required this.to,
    this.reason = '',
    this.reports = const [],
    this.travel,
    this.status = LeaveStatus.pending,
    this.paid = false,
    this.note,
    this.byName,
    this.at,
    this.createdAt,
  });

  bool get isSick => type == LeaveType.sick;
  bool get isPending => status == LeaveStatus.pending;
  bool get isApproved => status == LeaveStatus.approved;

  /// The payslip months this request touches (`{m-yyyy}`, in order).
  List<String> get months {
    final out = <String>[];
    for (var m = DateTime(from.year, from.month);
        !m.isAfter(DateTime(to.year, to.month));
        m = DateTime(m.year, m.month + 1)) {
      out.add(monthKey(m));
    }
    return out;
  }

  List<DateTime> days(int offDay) => leaveDaysIn(from, to, offDay);

  bool overlaps(DateTime start, DateTime end) =>
      !_day(from).isAfter(_day(end)) && !_day(to).isBefore(_day(start));

  factory LeaveRequest.fromMap(String id, Map<String, dynamic> m) => LeaveRequest(
        id: id,
        uid: '${m['uid'] ?? ''}',
        name: '${m['name'] ?? ''}',
        type: LeaveType.values.asNameMap()[m['type']] ?? LeaveType.annual,
        from: _day((m['from'] as Timestamp?)?.toDate() ?? DateTime(2000)),
        to: _day((m['to'] as Timestamp?)?.toDate() ?? DateTime(2000)),
        reason: '${m['reason'] ?? ''}',
        reports: [
          for (final r in (m['reports'] as List?) ?? [m['report']])
            if (LeaveReport.fromMap(r) case final report?) report
        ],
        travel: LeaveTravel.fromMap(m['travel']),
        status: LeaveStatus.values.asNameMap()[m['status']] ?? LeaveStatus.pending,
        paid: m['paid'] == true,
        note: m['note'] as String?,
        byName: m['byName'] as String?,
        at: (m['at'] as Timestamp?)?.toDate(),
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );

  /// The fields a new request is created with; [days] is the count shown
  /// in lists (the pay calculation recounts from the dates).
  Map<String, dynamic> toNewMap(int days) => {
        'uid': uid,
        'name': name,
        'type': type.name,
        'from': Timestamp.fromDate(_day(from)),
        'to': Timestamp.fromDate(_day(to)),
        'days': days,
        'months': months,
        'reason': reason,
        'reports': [for (final r in reports) r.toMap()],
        'travel': travel?.toMap(),
        'status': LeaveStatus.pending.name,
        'paid': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

/// One leave allowance in a year.
class LeaveBalance {
  final int allowance;
  final int approved;
  final int pending;
  const LeaveBalance(this.allowance, this.approved, this.pending);

  int get left => allowance - approved;
}

/// Days of [type] in [year] (a request over New Year counts in each year
/// for its own days), against the package's entitlement (for sick leave,
/// all three tiers together).
LeaveBalance leaveBalance(
    LeaveType type, int year, List<LeaveRequest> requests, SalaryPackage p) {
  var approved = 0, pending = 0;
  for (final r in requests) {
    if (r.type != type) continue;
    final n = r.days(p.weeklyOffDay).where((d) => d.year == year).length;
    if (r.isApproved) approved += n;
    if (r.isPending) pending += n;
  }
  final allowance = switch (type) {
    LeaveType.annual => p.annualLeaveDays,
    LeaveType.emergency => p.emergencyLeaveDays,
    LeaveType.sick => p.sickDaysTotal,
  };
  return LeaveBalance(allowance, approved, pending);
}

/// Sick leave pay for the [n]th approved sick day of a year (1-based): the
/// package's full-pay days, then its half-pay days, the rest unpaid (UAE
/// law: 15 full, 30 half).
double sickPayFactor(int n, [SalaryPackage p = const SalaryPackage()]) =>
    n <= p.sickFullDays ? 1 : (n <= p.sickFullDays + p.sickHalfDays ? 0.5 : 0);

/// Annual leave days a year the UAE law allows after [joinDate] as of
/// [asOf]: none under 6 months of service, 2 days per full month from 6 to
/// 12 months, 30 days from one year. Null without a start date.
int? lawAnnualLeaveDays(DateTime? joinDate, DateTime asOf) {
  if (joinDate == null) return null;
  var months = (asOf.year - joinDate.year) * 12 + asOf.month - joinDate.month;
  if (asOf.day < joinDate.day) months--;
  if (months < 6) return 0;
  if (months < 12) return 2 * months;
  return 30;
}

/// One day of approved leave in a pay period. [factor] is the share of a
/// working day paid: 1 or 0 for annual/emergency (HR's choice), the tier for
/// sick leave. [worked] means the worker checked in that day, so it's paid
/// as work and not as leave.
class LeaveDay {
  final DateTime day;
  final LeaveType type;
  final double factor;
  final bool worked;
  const LeaveDay(this.day, this.type, this.factor, {this.worked = false});

  double get paidFactor => worked ? 0 : factor;
}

/// Approved leave days from [start] to [end]. [requests] should hold the
/// worker's approved sick leave from the start of [start]'s year too, so
/// the tiers count the year's earlier sick days. Days in [workedDays] are
/// marked [LeaveDay.worked].
List<LeaveDay> leaveDaysFor(List<LeaveRequest> requests, SalaryPackage p,
    DateTime start, DateTime end, {Set<DateTime> workedDays = const {}}) {
  final first = _day(start), last = _day(end);
  bool inPeriod(DateTime d) => !d.isBefore(first) && !d.isAfter(last);
  final out = <LeaveDay>[];
  final sick = <DateTime>{};
  for (final r in requests) {
    if (!r.isApproved) continue;
    for (final d in r.days(p.weeklyOffDay)) {
      if (r.isSick) {
        if (d.year == first.year || d.year == last.year) sick.add(d);
      } else if (inPeriod(d)) {
        out.add(LeaveDay(d, r.type, r.paid ? 1 : 0, worked: workedDays.contains(d)));
      }
    }
  }
  // Tiers restart each calendar year.
  final counts = <int, int>{};
  for (final d in sick.toList()..sort()) {
    final n = counts[d.year] = (counts[d.year] ?? 0) + 1;
    if (inPeriod(d)) {
      out.add(LeaveDay(d, LeaveType.sick, sickPayFactor(n, p), worked: workedDays.contains(d)));
    }
  }
  return out..sort((a, b) => a.day.compareTo(b.day));
}
