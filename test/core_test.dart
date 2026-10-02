import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:royal_marble/core/format.dart';
import 'package:royal_marble/core/l10n_helpers.dart';
import 'package:royal_marble/core/roles.dart';
import 'package:royal_marble/l10n/app_localizations.dart';
import 'package:royal_marble/models/salary.dart';

void main() {
  group('primaryRole', () {
    test('picks the highest-privilege role', () {
      expect(primaryRole(['isNormalUser', 'isSupervisor']), AppRole.supervisor);
      expect(primaryRole(['isSales', 'isAdmin']), AppRole.admin);
    });
    test('defaults to mason for unknown or missing roles', () {
      expect(primaryRole(null), AppRole.worker);
      expect(primaryRole(['somethingElse']), AppRole.worker);
    });
  });

  group('prettyAddress', () {
    test('cleans a Placemark.toString() dump', () {
      const raw = 'Name: 14,\n Street: 14 11B Street, ISO Country Code: AE, '
          'Country: United Arab Emirates, Postal code: , '
          'Administrative area: Dubai, Subadministrative area: , '
          'Locality: Dubai, Sublocality: Jumeirah, Thoroughfare: 11B Street';
      expect(prettyAddress(raw), '14 11B Street, Jumeirah, Dubai');
    });
    test('passes plain addresses through', () {
      expect(prettyAddress('Al Quoz 3, Dubai'), 'Al Quoz 3, Dubai');
      expect(prettyAddress(null), '');
    });
  });

  group('SalaryPackage', () {
    test('monthly total includes every allowance', () {
      const p = SalaryPackage(
        basic: 2000,
        housing: 500,
        transport: 200,
        food: 300,
        other: [Allowance('Phone', 50)],
      );
      expect(p.monthlyAllowances, 1050);
      expect(p.monthlyTotal, 3050);
    });
    test('no monthly total for daily pay', () {
      expect(const SalaryPackage(payType: PayType.daily, basic: 100).monthlyTotal,
          isNull);
    });
    test('round-trips through a Firestore map', () {
      const p = SalaryPackage(
          payType: PayType.hourly, basic: 15, other: [Allowance('Tools', 40)]);
      final back = SalaryPackage.fromMap(p.toMap());
      expect(back.payType, PayType.hourly);
      expect(back.basic, 15);
      expect(back.other.single.name, 'Tools');
    });
  });

  group('localization', () {
    test('every language has exactly the English keys', () {
      Set<String> keys(String loc) => (jsonDecode(
                  File('lib/l10n/app_$loc.arb').readAsStringSync())
              as Map<String, dynamic>)
          .keys
          .where((k) => !k.startsWith('@'))
          .toSet();
      final en = keys('en');
      for (final loc in ['ar', 'hi', 'ur']) {
        expect(keys(loc), en, reason: '$loc differs from en');
      }
    });

    test('durations and roles are translated', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final ar = await AppLocalizations.delegate.load(const Locale('ar'));
      const d = Duration(hours: 2, minutes: 5);
      expect(localizedDuration(en, d), '2h 5m');
      expect(localizedDuration(ar, d), '2 س 5 د');
      expect(AppRole.worker.localized(en), 'Mason');
      expect(AppRole.worker.localized(ar), 'عامل بناء');
    });
  });
}
