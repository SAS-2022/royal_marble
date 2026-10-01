import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:sentry_flutter/sentry_flutter.dart';

enum SiteKind { project, mockup }

class CheckInResult {
  final bool ok;
  final String message;
  const CheckInResult(this.ok, this.message);
}

/// Accuracy we try to reach before giving up and sending the best fix we got.
/// The server rejects anything worse than 50 m.
const _targetAccuracyM = 20.0;

class CheckInService {
  /// Takes up to three multi-sample readings and keeps the most accurate one.
  static Future<bg.Location> bestFix() async {
    bg.Location? best;
    for (var attempt = 0; attempt < 3; attempt++) {
      final l = await bg.BackgroundGeolocation.getCurrentPosition(
        samples: 3,
        desiredAccuracy: 10,
        timeout: 20,
        maximumAge: 0,
        persist: false,
        extras: {'checkin': true},
      );
      if (best == null || l.coords.accuracy < best.coords.accuracy) best = l;
      if (best.coords.accuracy <= _targetAccuracyM) break;
    }
    return best!;
  }

  static Future<CheckInResult> submit({
    required bool checkIn,
    required SiteKind kind,
    required String siteId,
    String? workType,
    double? squareMeters,
  }) async {
    final bg.Location fix;
    try {
      fix = await bestFix();
    } catch (e) {
      return const CheckInResult(false,
          'Could not get your location. Make sure location is turned on and try again.');
    }

    try {
      final res = await FirebaseFunctions.instance
          .httpsCallable('checkInOut')
          .call<Map<String, dynamic>>({
        'action': checkIn ? 'in' : 'out',
        'kind': kind.name,
        'siteId': siteId,
        'lat': fix.coords.latitude,
        'lng': fix.coords.longitude,
        'accuracy': fix.coords.accuracy,
        'mock': fix.mock,
        'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
        if (workType != null) 'workType': workType,
        if (squareMeters != null) 'squareMeters': squareMeters,
      });
      final time = (res.data['time'] as String?)?.substring(11, 16) ?? '';
      return CheckInResult(
          true,
          checkIn
              ? 'Checked in at $time. Have a good day!'
              : 'Checked out at $time. Thank you!');
    } on FirebaseFunctionsException catch (e) {
      return CheckInResult(false, e.message ?? 'Check-in failed (${e.code}).');
    } catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
      return const CheckInResult(
          false, 'No connection to the server. Check your internet and try again.');
    }
  }
}
