import 'package:flutter_test/flutter_test.dart';
import 'package:royal_marble/models/business_model.dart';

void main() {
  group('ProjectData.fromMap', () {
    test('accepts a whole-number radius and a missing phone', () {
      final p = ProjectData.fromMap('p1', {
        'projectName': 'Villa',
        'selectedAddress': {'Lat': 25.08, 'Lng': 55.14, 'addressName': 'Marina'},
        'radius': 150,
        'status': 'active',
      });
      expect(p.radius, 150.0);
      expect(p.phoneNumber, isNull);
      expect(p.projectAddress?['Lat'], 25.08);
      expect(p.projectStatus, 'active');
      expect(p.error, isNull);
    });

    test('a deleted document is reported, not thrown', () {
      expect(ProjectData.fromMap('gone', null).error, 'not-found');
      expect(MockupData.fromMap('gone', null).error, 'not-found');
    });
  });

  test('MockupData.fromMap reads the mock-up field names', () {
    final m = MockupData.fromMap('m1', {
      'name': 'Mock-up',
      'address': {'Lat': 1, 'Lng': 2},
      'radius': '200',
      'phoneNumber': {'phoneNumber': '+971500000000', 'isoCode': 'AE'},
    });
    expect(m.mockupName, 'Mock-up');
    expect(m.radius, 200.0);
    expect(m.phoneNumber?.phoneNumber, '+971500000000');
  });
}
