import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/roles.dart';
import '../models/business_model.dart';
import '../models/user_model.dart';
import '../services/database.dart';

/// One person's attendance on one day, read from `time_sheet/{d-m-yyyy}`.
class AttendanceRow {
  final DateTime day;
  final String uid;
  final String name;
  final String role;
  final String project;
  final DateTime? arrived;
  final DateTime? left;
  final bool stillOnSite;
  final String? workType;
  final double? squareMeters;

  const AttendanceRow({
    required this.day,
    required this.uid,
    required this.name,
    required this.role,
    required this.project,
    this.arrived,
    this.left,
    this.stillOnSite = false,
    this.workType,
    this.squareMeters,
  });

  /// Worked time; null while still on site or when a time is missing.
  Duration? get worked =>
      arrived != null && left != null && left!.isAfter(arrived!)
          ? left!.difference(arrived!)
          : null;
}

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Every calendar day from [range.start] to [range.end], both inclusive.
List<DateTime> daysIn(DateTimeRange range) {
  final first = dayOnly(range.start);
  final last = dayOnly(range.end);
  return [
    for (var d = first; !d.isAfter(last); d = DateTime(d.year, d.month, d.day + 1))
      d
  ];
}

double? _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

/// Loads attendance for every day in [range] in parallel. [role] filters by
/// the role stored on the entry; null means everyone.
Future<List<AttendanceRow>> loadAttendance(
    DateTimeRange range, AppRole? role) async {
  final col = FirebaseFirestore.instance.collection('time_sheet');
  final days = daysIn(range);
  final snaps = await Future.wait(
      days.map((d) => col.doc('${d.day}-${d.month}-${d.year}').get()));

  final rows = <AttendanceRow>[];
  for (var i = 0; i < days.length; i++) {
    final data = snaps[i].data();
    if (data == null) continue;
    for (final e in data.entries) {
      final v = e.value;
      if (v is! Map) continue;
      // Older first check-ins stored `role` instead of `roles`.
      final entryRole = '${v['roles'] ?? v['role'] ?? ''}';
      if (role != null && entryRole != role.key) continue;
      final work = v['workCompleted'] as Map?;
      rows.add(AttendanceRow(
        day: days[i],
        uid: e.key,
        name: '${v['firstName'] ?? ''} ${v['lastName'] ?? ''}'.trim(),
        role: entryRole,
        project: '${v['projectName'] ?? ''}',
        arrived: DateTime.tryParse('${v['arriving_at']}'),
        left: DateTime.tryParse('${v['leaving_at']}'),
        // An open entry only means "on site" today; on a past day the
        // worker simply never checked out.
        stillOnSite: v['isOnSite'] == true &&
            v['leaving_at'] == null &&
            days[i] == dayOnly(DateTime.now()),
        workType: (work?['workType'] as String?)?.trim().isEmpty == true
            ? null
            : work?['workType'] as String?,
        squareMeters: _num(work?['squareMeters'] ?? work?['sqaureMeters']),
      ));
    }
  }
  rows.sort((a, b) {
    final d = a.day.compareTo(b.day);
    return d != 0 ? d : a.name.compareTo(b.name);
  });
  return rows;
}

/// Per-person totals over a set of rows.
class PersonTotals {
  final String uid;
  final String name;
  final List<AttendanceRow> rows;
  PersonTotals(this.uid, this.name, this.rows);

  int get days => rows.map((r) => r.day).toSet().length;
  Duration get worked =>
      rows.fold(Duration.zero, (t, r) => t + (r.worked ?? Duration.zero));
  double get squareMeters =>
      rows.fold(0.0, (t, r) => t + (r.squareMeters ?? 0));
  int get missingCheckOuts =>
      rows.where((r) => r.left == null && !r.stillOnSite).length;
}

List<PersonTotals> totalsByPerson(List<AttendanceRow> rows) {
  final byUid = <String, List<AttendanceRow>>{};
  for (final r in rows) {
    byUid.putIfAbsent(r.uid, () => []).add(r);
  }
  return [
    for (final e in byUid.entries) PersonTotals(e.key, e.value.first.name, e.value)
  ]..sort((a, b) => b.worked.compareTo(a.worked));
}

/// A salesperson's visits in the range.
class SalesSummary {
  final UserData user;
  final List<ClientVisitDetails> clientVisits;
  final List<ProjectVisitDetails> projectVisits;
  SalesSummary(this.user, this.clientVisits, this.projectVisits);

  int get workingDays => {
        ...clientVisits.map((v) => '${v.visitTime}'),
        ...projectVisits.map((v) => '${v.visitTime}'),
      }.length;
  int get totalVisits => clientVisits.length + projectVisits.length;
}

Future<List<SalesSummary>> loadSales(
    List<UserData> salesUsers, DateTimeRange range) async {
  final db = DatabaseService();
  final from = dayOnly(range.start);
  final to = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
  return Future.wait(salesUsers.map((u) async {
    final clients = await db.getTimeRangedClientVisitsFuture(
        userId: u.uid, fromDate: from, toDate: to);
    final projects = await db.getTimeRangedProjectVisitsFuture(
        userId: u.uid, fromDate: from, toDate: to);
    return SalesSummary(
      u,
      clients.where((v) => v.error == null).toList(),
      projects.where((v) => v.error == null).toList(),
    );
  }));
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}
