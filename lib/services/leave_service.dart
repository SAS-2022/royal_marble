import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/error_reporter.dart';
import '../models/leave.dart';

/// Why saving a leave request failed (the screens translate it).
enum LeaveError { denied, upload, failed }

/// A file picked as the hospital report, before upload.
typedef PickedReport = ({String name, String contentType, Uint8List bytes});

/// Leave requests (`leave_requests`) and their hospital reports in Storage
/// (`leave_reports/{uid}/…`).
class LeaveService {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('leave_requests');

  static List<LeaveRequest> _list(QuerySnapshot<Map<String, dynamic>> s) =>
      [for (final d in s.docs) LeaveRequest.fromMap(d.id, d.data())]
        ..sort((a, b) => b.from.compareTo(a.from));

  /// One worker's requests, newest first (the worker can read their own).
  static Stream<List<LeaveRequest>> watchMine(String uid) =>
      _col.where('uid', isEqualTo: uid).snapshots().map(_list);

  static Future<List<LeaveRequest>> forWorker(String uid) async =>
      _list(await _col.where('uid', isEqualTo: uid).get());

  /// Everyone's requests that end on or after [since] (HR and admins), by
  /// worker. Pass the start of the year when sick tiers matter.
  static Future<Map<String, List<LeaveRequest>>> everyoneSince(DateTime since) async {
    final snap = await _col
        .where('to', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();
    final out = <String, List<LeaveRequest>>{};
    for (final r in _list(snap)) {
      out.putIfAbsent(r.uid, () => []).add(r);
    }
    return out;
  }

  /// Requests waiting for HR (HR and admins).
  static Stream<int> watchPendingCount() => _col
      .where('status', isEqualTo: LeaveStatus.pending.name)
      .snapshots()
      .map((s) => s.size);

  /// Uploads [reports], then saves [request] as pending with them.
  static Future<LeaveError?> submit(LeaveRequest request, int days,
      {List<PickedReport> reports = const []}) async {
    final uploaded = <LeaveReport>[];
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (final (i, report) in reports.indexed) {
      final safe = report.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final path = 'leave_reports/${request.uid}/${stamp}_${i}_$safe';
      try {
        await FirebaseStorage.instance
            .ref(path)
            .putData(report.bytes, SettableMetadata(contentType: report.contentType));
      } catch (e, st) {
        await ErrorReporter.record(e, stackTrace: st);
        return LeaveError.upload;
      }
      uploaded.add(LeaveReport(path, report.name, report.contentType));
    }
    final r = LeaveRequest(
        uid: request.uid,
        name: request.name,
        type: request.type,
        from: request.from,
        to: request.to,
        reason: request.reason,
        travel: request.travel,
        reports: uploaded);
    return _write(() => _col.add(r.toNewMap(days)));
  }

  /// The worker withdraws a pending request.
  static Future<LeaveError?> cancel(LeaveRequest r) => _write(() => _col.doc(r.id).update({
        'status': LeaveStatus.cancelled.name,
        'at': FieldValue.serverTimestamp(),
      }));

  /// HR or an admin approves or rejects; [paid] matters for annual and
  /// emergency leave only.
  static Future<LeaveError?> decide(LeaveRequest r,
          {required LeaveStatus status,
          required bool paid,
          required String byName,
          String? note}) =>
      _write(() => _col.doc(r.id).update({
            'status': status.name,
            'paid': r.isSick ? false : paid,
            'note': note,
            'by': FirebaseAuth.instance.currentUser?.uid,
            'byName': byName,
            'at': FieldValue.serverTimestamp(),
          }));

  /// A link to open the hospital report.
  static Future<String> reportUrl(LeaveReport report) =>
      FirebaseStorage.instance.ref(report.path).getDownloadURL();

  static Future<LeaveError?> _write(Future<void> Function() write) async {
    try {
      await write();
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return LeaveError.denied;
      await ErrorReporter.record(e);
      return LeaveError.failed;
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      return LeaveError.failed;
    }
  }
}
