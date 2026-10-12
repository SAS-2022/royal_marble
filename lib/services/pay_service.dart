import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show DateTimeRange;

import '../core/error_reporter.dart';
import '../models/attendance.dart';
import '../models/pay_calc.dart';
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
