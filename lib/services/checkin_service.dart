import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:royal_marble/core/error_reporter.dart';
import 'package:royal_marble/l10n/app_localizations.dart';

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

  /// [l10n] is captured by the caller before awaiting, so messages come back
  /// in the user's language.
  static Future<CheckInResult> submit({
    required AppLocalizations l10n,
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
      return CheckInResult(false, l10n.errLocationUnavailable);
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
          true, checkIn ? l10n.checkedInAt(time) : l10n.checkedOutAt(time));
    } on FirebaseFunctionsException catch (e) {
      return CheckInResult(false, _serverError(l10n, e));
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      return CheckInResult(false, l10n.errNoServer);
    }
  }

  /// The function sends `details.reason` (+ parameters); older deployments
  /// only send English text, which is the fallback.
  static String _serverError(AppLocalizations l, FirebaseFunctionsException e) {
    final d = e.details is Map ? e.details as Map : const {};
    int n(String k) => (d[k] as num?)?.round() ?? 0;
    final site = '${d['site'] ?? ''}';
    return switch (d['reason']) {
      'sign_in_again' => l.errSignInAgain,
      'not_active' => l.errNotActive,
      'not_assigned' => l.errNotAssigned,
      'mock_location' => l.errMockLocation,
      'weak_gps' => l.errWeakGps(n('meters')),
      'no_site_location' => l.errNoSiteLocation,
      'out_of_range' => l.errOutOfRange(n('meters')),
      'already_checked_in' => l.errAlreadyCheckedIn(site),
      'not_checked_in' => l.errNotCheckedIn,
      'checked_in_elsewhere' => l.errCheckedInElsewhere(site),
      _ => e.message ?? l.errCheckInFailed(e.code),
    };
  }
}
