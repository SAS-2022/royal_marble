import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/roles.dart';
import '../models/attendance.dart';
import '../models/business_model.dart';
import '../models/user_model.dart';
import '../services/database.dart';

/// One stay at one site, read from `time_sheet/{d-m-yyyy}`. A worker who
/// visits two sites in a day has two rows.
class AttendanceRow {
  final DateTime day;
  final String uid;
  final String name;
  final String role;
  final String siteId;
  final String project;
  final DateTime? arrived;
  final DateTime? left;
  final bool stillOnSite;
  final String? workType;
  final double? squareMeters;

  /// `left_site` / `end_of_day` when the system checked the worker out.
  final String? autoReason;

  /// Time spent outside the site area while checked in.
  final Duration away;

  /// An admin edited this session.
  final bool corrected;

  /// An admin has reviewed (corrected or approved) this worker's day.
  final bool reviewed;

  const AttendanceRow({
    required this.day,
    required this.uid,
    required this.name,
    required this.role,
    this.siteId = '',
    required this.project,
    this.arrived,
    this.left,
    this.stillOnSite = false,
    this.workType,
    this.squareMeters,
    this.autoReason,
    this.away = Duration.zero,
    this.corrected = false,
    this.reviewed = false,
  });

  /// Worked time; null while still on site or when a time is missing.
  Duration? get worked =>
      arrived != null && left != null && left!.isAfter(arrived!)
          ? left!.difference(arrived!)
          : null;

  bool get missingCheckOut => left == null && !stillOnSite;

  /// Closed by the system, or never closed, and not yet reviewed.
  bool get needsReview => !reviewed && (autoReason != null || missingCheckOut);
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

String dayId(DateTime d) => '${d.day}-${d.month}-${d.year}';

/// Loads attendance for every day in [range] in parallel. [role] filters by
/// the role stored on the entry; null means everyone.
Future<List<AttendanceRow>> loadAttendance(
    DateTimeRange range, AppRole? role) async {
  final col = FirebaseFirestore.instance.collection('time_sheet');
  final days = daysIn(range);
  final snaps = await Future.wait(days.map((d) => col.doc(dayId(d)).get()));
  final today = dayOnly(DateTime.now());

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
      final entry = DayEntry.fromMap(v);
      for (final s in entry.sessions) {
        rows.add(AttendanceRow(
          day: days[i],
          uid: e.key,
          name: '${v['firstName'] ?? ''} ${v['lastName'] ?? ''}'.trim(),
          role: entryRole,
          siteId: s.siteId,
          project: s.siteName,
          arrived: s.start,
          left: s.end,
          // An open session only means "on site" today; on a past day the
          // worker simply never checked out.
          stillOnSite: s.isOpen && days[i] == today,
          workType: s.workType?.trim().isEmpty == true ? null : s.workType,
          squareMeters: s.squareMeters,
          autoReason: s.auto,
          away: s.away(),
          corrected: s.corrected,
          reviewed: entry.reviewed,
        ));
      }
    }
  }
  rows.sort((a, b) {
    final d = a.day.compareTo(b.day);
    if (d != 0) return d;
    final n = a.name.compareTo(b.name);
    return n != 0 ? n : (a.arrived ?? a.day).compareTo(b.arrived ?? b.day);
  });
  return rows;
}

/// Totals over a group of rows (one person, or one site).
class AttendanceTotals {
  final String key;
  final String name;
  final List<AttendanceRow> rows;
  AttendanceTotals(this.key, this.name, this.rows);

  /// Distinct days with any attendance.
  int get days => rows.map((r) => r.day).toSet().length;

  /// Distinct people.
  int get people => rows.map((r) => r.uid).toSet().length;
  Duration get worked =>
      rows.fold(Duration.zero, (t, r) => t + (r.worked ?? Duration.zero));
  double get squareMeters =>
      rows.fold(0.0, (t, r) => t + (r.squareMeters ?? 0));
  int get missingCheckOuts => rows.where((r) => r.missingCheckOut).length;
  int get toReview => rows.where((r) => r.needsReview).length;
}

List<AttendanceTotals> _totalsBy(List<AttendanceRow> rows,
    String Function(AttendanceRow) key, String Function(AttendanceRow) name) {
  final groups = <String, List<AttendanceRow>>{};
  for (final r in rows) {
    groups.putIfAbsent(key(r), () => []).add(r);
  }
  return [
    for (final e in groups.entries)
      AttendanceTotals(e.key, name(e.value.first), e.value)
  ]..sort((a, b) => b.worked.compareTo(a.worked));
}

List<AttendanceTotals> totalsByPerson(List<AttendanceRow> rows) =>
    _totalsBy(rows, (r) => r.uid, (r) => r.name);

/// Hours per site; sessions from before site ids were stored group by name.
List<AttendanceTotals> totalsBySite(List<AttendanceRow> rows) => _totalsBy(
    rows, (r) => r.siteId.isEmpty ? r.project : r.siteId, (r) => r.project);

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
