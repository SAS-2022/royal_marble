import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show DateTimeRange;

import '../core/error_reporter.dart';
import '../models/attendance.dart';
import '../models/pay_calc.dart';
import '../models/payslip.dart';
import '../models/salary.dart';
import '../reports/report_data.dart' show dayId, dayOnly, daysIn;

/// One worker's days in a period, keyed by day, with the name the timesheet
/// stored for them.
typedef WorkerDays = ({String name, Map<DateTime, DayEntry> days});

/// Loads what pay and overtime are worked out from: timesheets, pay
/// packages and HR's overtime decisions (`overtime/{uid}_{d-m-yyyy}`).
class PayService {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _overtime =>
      _db.collection('overtime');

  /// The month so far: the 1st until today.
  static DateTimeRange monthToDate(DateTime now) =>
      DateTimeRange(start: DateTime(now.year, now.month), end: dayOnly(now));

  /// A whole calendar month, or up to today for the current one.
  static DateTimeRange month(DateTime anyDay, DateTime now) {
    final start = DateTime(anyDay.year, anyDay.month);
    final end = DateTime(anyDay.year, anyDay.month + 1, 0);
    return DateTimeRange(start: start, end: end.isAfter(now) ? dayOnly(now) : end);
  }

  /// Every worker's days in [range]; [uid] limits it to one person.
  static Future<Map<String, WorkerDays>> loadDays(DateTimeRange range,
      {String? uid}) async {
    final days = daysIn(range);
    final snaps = await Future.wait(
        days.map((d) => _db.collection('time_sheet').doc(dayId(d)).get()));
    final out = <String, WorkerDays>{};
    for (var i = 0; i < days.length; i++) {
      for (final e in (snaps[i].data() ?? const {}).entries) {
        if (uid != null && e.key != uid) continue;
        final v = e.value;
        if (v is! Map) continue;
        final entry = DayEntry.fromMap(v);
        if (entry.isEmpty) continue;
        final name = '${v['firstName'] ?? ''} ${v['lastName'] ?? ''}'.trim();
        final w = out.putIfAbsent(e.key, () => (name: name, days: {}));
        w.days[days[i]] = entry;
      }
    }
    return out;
  }

  /// Everyone's pay packages (HR and admins).
  static Future<Map<String, SalaryPackage>> packages() async {
    final snap = await _db.collection('payroll').get();
    return {for (final d in snap.docs) d.id: SalaryPackage.fromMap(d.data())};
  }

  /// Decisions in [range], by worker then day (HR and admins).
  static Future<Map<String, Map<DateTime, OvertimeDecision>>> decisionsIn(
      DateTimeRange range) async {
    final snap = await _overtime
        .where('day', isGreaterThanOrEqualTo: Timestamp.fromDate(dayOnly(range.start)))
        .where('day', isLessThanOrEqualTo: Timestamp.fromDate(dayOnly(range.end)))
        .get();
    final out = <String, Map<DateTime, OvertimeDecision>>{};
    for (final d in snap.docs) {
      final m = d.data();
      final day = (m['day'] as Timestamp?)?.toDate();
      if (day == null || m['uid'] == null) continue;
      out.putIfAbsent('${m['uid']}', () => {})[dayOnly(day)] =
          OvertimeDecision.fromMap(m);
    }
    return out;
  }

  /// One worker's decisions for [days], looked up by id (workers can read
  /// their own).
  static Future<Map<DateTime, OvertimeDecision>> decisionsFor(
      String uid, Iterable<DateTime> days) async {
    final list = days.toList();
    final snaps = await Future.wait(
        list.map((d) => _overtime.doc(overtimeDocId(uid, d)).get()));
    return {
      for (var i = 0; i < list.length; i++)
        if (snaps[i].data() case final m?) list[i]: OvertimeDecision.fromMap(m)
    };
  }

  static CollectionReference<Map<String, dynamic>> get _payslips =>
      _db.collection('payslips');

  /// Everyone's payslips for [month], by worker (HR and admins).
  static Future<Map<String, Payslip>> payslipsIn(DateTime month) async {
    final snap = await _payslips
        .where('year', isEqualTo: month.year)
        .where('month', isEqualTo: month.month)
        .get();
    return {for (final d in snap.docs) '${d.data()['uid']}': Payslip.fromMap(d.data())};
  }

  /// One worker's payslip for [month], or null (workers can read their own).
  static Future<Payslip?> payslipFor(String uid, DateTime month) async {
    final m = (await _payslips.doc(payslipDocId(uid, month)).get()).data();
    return m == null ? null : Payslip.fromMap(m);
  }

  /// One worker's payslips for the given months, newest first, skipping
  /// months with none.
  static Future<List<Payslip>> payslipsFor(String uid, List<DateTime> months) async {
    final slips = await Future.wait(months.map((m) => payslipFor(uid, m)));
    return slips.whereType<Payslip>().toList()
      ..sort((a, b) => b.monthStart.compareTo(a.monthStart));
  }

  /// Approves and locks each of [slips] (fields from [payslipFields]) in one
  /// batch; returns null on success, or a message to show.
  static Future<String?> approve(List<Map<String, dynamic>> slips,
      {required String byName}) async {
    final batch = _db.batch();
    for (final f in slips) {
      final month = DateTime(f['year'] as int, f['month'] as int);
      batch.set(
          _payslips.doc(payslipDocId('${f['uid']}', month)),
          {
            ...f,
            'approvedBy': FirebaseAuth.instance.currentUser?.uid,
            'approvedByName': byName,
            'approvedAt': FieldValue.serverTimestamp(),
          },
          // Keeps the list of earlier reopenings.
          SetOptions(merge: true));
    }
    return _write(batch.commit, 'You don\'t have permission to approve pay.');
  }

  /// Admins: reopens an approved month so attendance and overtime can change.
  static Future<String?> reopen(Payslip slip,
      {required String reason, required String byName}) {
    return _write(
        () => _payslips.doc(payslipDocId(slip.uid, slip.monthStart)).update({
              'status': PayslipStatus.reopened.name,
              'reopened': FieldValue.arrayUnion([
                {
                  'by': FirebaseAuth.instance.currentUser?.uid,
                  'byName': byName,
                  'at': Timestamp.now(),
                  'reason': reason,
                }
              ]),
            }),
        'Only an admin can reopen approved pay.');
  }

  static Future<String?> _write(
      Future<void> Function() write, String deniedMessage) async {
    try {
      await write();
      return null;
    } on FirebaseException catch (e) {
      return e.code == 'permission-denied'
          ? deniedMessage
          : 'Could not save: ${e.message}';
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      return 'Could not save. Please try again.';
    }
  }

  /// Saves HR's decision; returns null on success, or a message to show.
  static Future<String?> decide({
    required String uid,
    required DateTime day,
    required OvertimeStatus status,
    required int minutes,
    required double rate,
    required String byName,
    String? note,
  }) async {
    try {
      await _overtime.doc(overtimeDocId(uid, day)).set({
        'uid': uid,
        'day': Timestamp.fromDate(dayOnly(day)),
        'status': status.name,
        'minutes': minutes,
        'rate': rate,
        'note': note,
        'by': FirebaseAuth.instance.currentUser?.uid,
        'byName': byName,
        'at': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException catch (e) {
      return e.code == 'permission-denied'
          ? 'You don\'t have permission to decide on overtime.'
          : 'Could not save: ${e.message}';
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      return 'Could not save. Please try again.';
    }
  }
}
