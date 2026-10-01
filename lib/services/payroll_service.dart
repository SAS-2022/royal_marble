import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/error_reporter.dart';
import '../models/salary.dart';

/// Reads and writes pay packages in `payroll/{uid}`.
///
/// Every save also appends a snapshot to `payroll/{uid}/history` so earlier
/// packages remain available when calculating past months.
class PayrollService {
  static final _col = FirebaseFirestore.instance.collection('payroll');

  static Stream<SalaryPackage?> watch(String uid) => _col
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? SalaryPackage.fromMap(s.data()) : null);

  /// Returns null on success, or a message to show.
  static Future<String?> save(String uid, SalaryPackage p) async {
    try {
      final data = {
        ...p.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      };
      final batch = FirebaseFirestore.instance.batch()
        ..set(_col.doc(uid), data)
        ..set(_col.doc(uid).collection('history').doc(), data);
      await batch.commit();
      return null;
    } on FirebaseException catch (e) {
      return e.code == 'permission-denied'
          ? 'You don\'t have permission to edit pay details.'
          : 'Could not save: ${e.message}';
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      return 'Could not save. Please try again.';
    }
  }
}
