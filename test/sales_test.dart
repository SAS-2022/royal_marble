import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:royal_marble/core/format.dart';
import 'package:royal_marble/l10n/app_localizations.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/sales_visit.dart';
import 'package:royal_marble/screens/visits_screen.dart' show purposeLabel;

void main() {
  group('ClientData.fromMap', () {
    test('a client saved without a phone or address does not crash', () {
      final c = ClientData.fromMap('c1', {'clientName': 'Al Noor', 'userId': 'u1'});
      expect(c.name, 'Al Noor');
      expect(c.phone, isNull);
      expect(c.hasPin, isFalse);
      expect(c.userId, 'u1');
    });

    test('reads the phone and only counts a numeric pin', () {
      final c = ClientData.fromMap('c2', {
        'clientName': 'Gulf Tiles',
        'phoneNumber': {'phoneNumber': '+971501234567', 'isoCode': 'AE'},
        'clientAddress': {'addressName': 'Al Quoz', 'Lat': '', 'Lng': ''},
      });
      expect(c.phone, '+971501234567');
      expect(c.hasPin, isFalse);
      expect(ClientData.fromMap('x', null).error, 'not-found');
    });
  });

  test('contactPhoneMap stores UAE numbers in international form', () {
    expect(contactPhoneMap('050 123 4567')['phoneNumber'], '+971501234567');
    expect(contactPhoneMap('00971501234567')['phoneNumber'], '+971501234567');
    expect(contactPhoneMap('')['phoneNumber'], '');
    expect(contactPhoneMap('+919812345678')['isoCode'], isNull);
  });

  group('SalesVisit', () {
    test('round-trips the field names the report and old app read', () {
      final t = DateTime(2026, 10, 4, 11, 30);
      final v = SalesVisit(
        userId: 'u1',
        kind: VisitKind.client,
        targetId: 'c1',
        targetName: 'Al Noor',
        contact: 'Omar',
        purpose: 'New order',
        details: 'Agreed on 40 m2 of Carrara for the lobby.',
        time: t,
      );
      final m = v.toMap();
      expect(m.keys, containsAll(
          ['uid', 'name', 'contact', 'visitPurpose', 'visitDetails', 'visitTime', 'userId']));
      final back = SalesVisit.fromMap(
          VisitKind.client, 'v1', 'u1', {...m, 'visitTime': Timestamp.fromDate(t)});
      expect(back.targetName, 'Al Noor');
      expect(back.time, t);
      expect(back.hasComment, isFalse);
      expect(VisitKind.project.collection, 'projectVisits');
    });

    test('tolerates a visit with missing fields', () {
      final v = SalesVisit.fromMap(VisitKind.project, 'v2', 'u2', {});
      expect(v.targetName, '');
      expect(v.details, '');
      expect(v.time, isNull);
    });
  });

  testWidgets('every stored purpose has a translation in each language',
      (tester) async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      for (final p in visitPurposes) {
        final label = purposeLabel(l, p);
        expect(label, isNotEmpty);
        if (locale != const Locale('en')) expect(label, isNot(p), reason: '$locale $p');
      }
    }
  });
}
