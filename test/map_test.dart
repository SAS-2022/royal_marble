import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:royal_marble/models/attendance.dart';
import 'package:royal_marble/models/device_status.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/screens/live_map_screen.dart';
import 'package:royal_marble/screens/site_form_screen.dart' show addressFromPlacemark;

void main() {
  final now = DateTime.now();
  String at(DateTime d) => stamp(d);
  Map<String, dynamic> status({int minutesAgo = 5, bool powerSave = false}) => {
        'lastSeen': Timestamp.fromDate(now.subtract(Duration(minutes: minutesAgo))),
        'permission': 'always',
        'powerSave': powerSave,
      };
  MapWorker worker({Map<String, dynamic>? device, Map? day, Map<String, dynamic>? loc}) =>
      MapWorker(UserData(uid: 'u', currentLocation: loc),
          DeviceStatus.fromMap(device ?? status()), DayEntry.fromMap(day));
  Map session(List<Map> events) => {
        'sessions': [
          {
            'siteId': 's1',
            'siteName': 'Villa',
            'in': at(now.subtract(const Duration(hours: 2))),
            'events': events,
          }
        ]
      };

  group('MapWorker.state', () {
    test('checked in and inside the site is on site', () {
      expect(worker(day: session([])).state, WorkerState.onSite);
    });

    test('checked in but left the site is outside', () {
      final w = worker(day: session([
        {'type': 'exit', 'at': at(now.subtract(const Duration(minutes: 20)))}
      ]));
      expect(w.state, WorkerState.outside);
    });

    test('a phone problem wins over attendance', () {
      expect(worker(device: status(powerSave: true), day: session([])).state,
          WorkerState.phoneProblem);
    });

    test('no timesheet entry is not checked in', () {
      expect(worker().state, WorkerState.notCheckedIn);
    });
  });

  test('a location is stale after two hours or when missing', () {
    expect(worker(device: status(minutesAgo: 30)).stale, isFalse);
    expect(worker(device: status(minutesAgo: 150)).stale, isTrue);
    expect(worker(device: {}).stale, isTrue);
  });

  test('only a numeric location is placed on the map', () {
    expect(worker(loc: {'Lat': 25.08, 'Lng': 55.14}).position, isNotNull);
    expect(worker(loc: {'Lat': '', 'Lng': ''}).position, isNull);
    expect(worker().position, isNull);
  });

  test('addresses drop a leading separator', () {
    expect(
        addressFromPlacemark(const Placemark(
            thoroughfare: '- Hor Al Anz', locality: 'Dubai')),
        'Hor Al Anz, Dubai');
  });
}
