import 'package:flutter_test/flutter_test.dart';
import 'package:royal_marble/models/attendance.dart';
import 'package:royal_marble/services/checkin_service.dart' show SiteKind;

void main() {
  group('DayEntry.fromMap', () {
    test('reads per-site sessions written by the server', () {
      final day = DayEntry.fromMap({
        'sessions': [
          {
            'siteId': 'm1',
            'siteKind': 'mockup',
            'siteName': 'Mock-up',
            'in': '2026-10-03 13:00:00.000',
            'out': null,
          },
          {
            'siteId': 'p1',
            'siteKind': 'project',
            'siteName': 'Villa',
            'in': '2026-10-03 07:00:00.000',
            'out': '2026-10-03 12:30:00.000',
            'switched': true,
            'work': {'workType': 'Installing Tiles', 'squareMeters': 12},
          },
        ],
      });
      expect(day.sessions.map((s) => s.siteId), ['p1', 'm1'],
          reason: 'sorted by check-in time');
      expect(day.open?.siteId, 'm1');
      expect(day.sessions.first.kind, SiteKind.project);
      expect(day.sessions.first.squareMeters, 12);
      expect(day.sessions.first.worked(), const Duration(hours: 5, minutes: 30));
      expect(day.atSite('p1').length, 1);
    });

    test('turns a 2023-app entry into one session', () {
      final open = DayEntry.fromMap({
        'projectId': 'p1',
        'projectName': 'Villa',
        'arriving_at': '2026-10-03 07:00:00.000',
        'leaving_at': null,
        'isOnSite': true,
      });
      expect(open.sessions.single.isOpen, isTrue);

      final crashed = DayEntry.fromMap({
        'projectId': 'p1',
        'arriving_at': '2026-10-03 07:00:00.000',
        'leaving_at': null,
        'isOnSite': false,
        'workCompleted': {'workType': 'Others', 'sqaureMeters': 3},
      });
      final s = crashed.sessions.single;
      expect(s.isOpen, isFalse);
      expect(s.noCheckout, isTrue);
      expect(s.squareMeters, 3, reason: 'old misspelt key');
      expect(crashed.needsReview, isTrue);
    });

    test('an empty or unknown entry has no sessions', () {
      expect(DayEntry.fromMap(null).isEmpty, isTrue);
      expect(DayEntry.fromMap({'firstName': 'A'}).isEmpty, isTrue);
    });

    test('auto check-outs need review until an admin has looked', () {
      Map<String, dynamic> entry({bool reviewed = false}) => {
            'sessions': [
              {
                'siteId': 'p1',
                'in': '2026-10-03 07:00:00.000',
                'out': '2026-10-03 15:00:00.000',
                'auto': 'left_site',
              }
            ],
            if (reviewed) 'reviewed': {'by': 'admin'},
          };
      expect(DayEntry.fromMap(entry()).needsReview, isTrue);
      expect(DayEntry.fromMap(entry(reviewed: true)).needsReview, isFalse);
    });
  });

  group('WorkSession presence', () {
    WorkSession session(List<PresenceEvent> events, {DateTime? end}) =>
        WorkSession(
          siteId: 'p1',
          kind: SiteKind.project,
          siteName: 'Villa',
          start: DateTime(2026, 10, 3, 7),
          end: end,
          events: events,
        );

    test('adds up time outside the site', () {
      final s = session([
        PresenceEvent(true, DateTime(2026, 10, 3, 10)),
        PresenceEvent(false, DateTime(2026, 10, 3, 10, 20)),
        PresenceEvent(true, DateTime(2026, 10, 3, 12)),
        PresenceEvent(false, DateTime(2026, 10, 3, 12, 45)),
      ], end: DateTime(2026, 10, 3, 16));
      expect(s.away(), const Duration(hours: 1, minutes: 5));
      expect(s.outsideSince, isNull);
    });

    test('an exit without return counts until check-out or now', () {
      final s = session([PresenceEvent(true, DateTime(2026, 10, 3, 15))]);
      expect(s.outsideSince, DateTime(2026, 10, 3, 15));
      expect(s.away(DateTime(2026, 10, 3, 15, 30)),
          const Duration(minutes: 30));
    });
  });

  test('siteAssignments accepts the old single map and the list', () {
    final site = {'id': 'p1', 'name': 'Villa'};
    expect(siteAssignments(site).single['id'], 'p1');
    expect(siteAssignments([site, {'id': 'p2'}]).length, 2);
    expect(siteAssignments({}), isEmpty, reason: 'removed by older versions');
    expect(siteAssignments(null), isEmpty);
  });

  test('stamp matches the server format', () {
    expect(stamp(DateTime(2026, 1, 5, 7, 3, 9, 42)), '2026-01-05 07:03:09.042');
  });
}
