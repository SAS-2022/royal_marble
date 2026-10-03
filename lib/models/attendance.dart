import '../services/checkin_service.dart' show SiteKind;

/// A user's assignment field (`assignedProject` / `assignedMockup`) is a list
/// of site maps, or a single map for masons assigned by older app versions.
/// Normalises both to a list of non-empty maps.
List<Map<String, dynamic>> siteAssignments(dynamic value) {
  final list = value is List ? value : [value];
  return [
    for (final v in list)
      if (v is Map && v['id'] != null) Map<String, dynamic>.from(v),
  ];
}

/// A geofence transition recorded while the worker was checked in.
class PresenceEvent {
  final bool exit;
  final DateTime at;
  const PresenceEvent(this.exit, this.at);
}

/// One stay at one site, from `time_sheet/{day}.{uid}.sessions`.
/// Times are the worker's local wall clock, as written by the server.
class WorkSession {
  final String siteId;
  final SiteKind kind;
  final String siteName;
  final DateTime start;
  final DateTime? end;

  /// A legacy day closed without a check-out (the old checkout crash).
  final bool noCheckout;

  /// `left_site` or `end_of_day` when the system closed the session.
  final String? auto;
  final bool switched;
  final bool corrected;
  final List<PresenceEvent> events;
  final String? workType;
  final double? squareMeters;

  const WorkSession({
    required this.siteId,
    required this.kind,
    required this.siteName,
    required this.start,
    this.end,
    this.noCheckout = false,
    this.auto,
    this.switched = false,
    this.corrected = false,
    this.events = const [],
    this.workType,
    this.squareMeters,
  });

  bool get isOpen => end == null && !noCheckout;

  /// Time from check-in to check-out; for an open session, until [now].
  Duration worked([DateTime? now]) {
    final until = end ?? (isOpen ? now ?? DateTime.now() : null);
    if (until == null || until.isBefore(start)) return Duration.zero;
    return until.difference(start);
  }

  /// When the worker stepped outside the site and hasn't come back yet.
  DateTime? get outsideSince =>
      events.isNotEmpty && events.last.exit ? events.last.at : null;

  /// Total time spent outside the site area during the session.
  Duration away([DateTime? now]) {
    var total = Duration.zero;
    DateTime? left;
    for (final e in events) {
      if (e.exit) {
        left ??= e.at;
      } else if (left != null) {
        total += e.at.difference(left);
        left = null;
      }
    }
    if (left != null) {
      final until = end ?? now ?? DateTime.now();
      if (until.isAfter(left)) total += until.difference(left);
    }
    return total;
  }

  /// Fields `correctAttendance` takes for this session.
  Map<String, dynamic> toCorrection({int? from}) => {
        'siteId': siteId,
        'siteKind': kind.name,
        'siteName': siteName,
        'in': stamp(start),
        'out': end == null ? null : stamp(end!),
        'from': from,
      };

  WorkSession copyWith({String? siteId, SiteKind? kind, String? siteName,
          DateTime? start, DateTime? end, bool clearEnd = false}) =>
      WorkSession(
        siteId: siteId ?? this.siteId,
        kind: kind ?? this.kind,
        siteName: siteName ?? this.siteName,
        start: start ?? this.start,
        end: clearEnd ? null : end ?? this.end,
        noCheckout: false,
        auto: auto,
        switched: switched,
        corrected: corrected,
        events: events,
        workType: workType,
        squareMeters: squareMeters,
      );
}

/// The server's local time format: `yyyy-MM-dd HH:mm:ss.SSS`.
String stamp(DateTime d) {
  String p(int n, [int w = 2]) => '$n'.padLeft(w, '0');
  return '${d.year}-${p(d.month)}-${p(d.day)} '
      '${p(d.hour)}:${p(d.minute)}:${p(d.second)}.${p(d.millisecond, 3)}';
}

double? _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

/// One worker's day. Mirrors `sessionsOf` in `functions/src/attendance.ts`:
/// entries written by the 2023 app only have the flat fields and become a
/// single session.
class DayEntry {
  final List<WorkSession> sessions;
  final bool reviewed;
  final List<Map<String, dynamic>> corrections;

  const DayEntry(this.sessions,
      {this.reviewed = false, this.corrections = const []});

  static const empty = DayEntry([]);

  factory DayEntry.fromMap(Map? m) {
    if (m == null) return empty;
    final raw = m['sessions'];
    final legacyWork = m['workCompleted'] as Map?;
    List<WorkSession> sessions;
    if (raw is List &&
        raw.isNotEmpty &&
        raw.every((s) => s is Map && s['siteId'] != null)) {
      sessions = [
        for (final s in raw.cast<Map>())
          if (DateTime.tryParse('${s['in']}') case final start?)
            WorkSession(
              siteId: '${s['siteId']}',
              kind: s['siteKind'] == 'mockup' ? SiteKind.mockup : SiteKind.project,
              siteName: '${s['siteName'] ?? ''}',
              start: start,
              end: DateTime.tryParse('${s['out']}'),
              noCheckout: s['noCheckout'] == true,
              auto: s['auto'] as String?,
              switched: s['switched'] == true,
              corrected: s['corrected'] == true,
              events: [
                for (final e in (s['events'] as List? ?? const []).whereType<Map>())
                  if (DateTime.tryParse('${e['at']}') case final at?)
                    PresenceEvent(e['type'] == 'exit', at),
              ],
              workType: (s['work'] as Map?)?['workType'] as String?,
              squareMeters: _num((s['work'] as Map?)?['squareMeters']),
            ),
      ];
    } else {
      final start = DateTime.tryParse('${m['arriving_at']}');
      if (start == null || m['projectId'] == null) return empty;
      final open = m['isOnSite'] == true && m['leaving_at'] == null;
      final end = DateTime.tryParse('${m['leaving_at']}');
      sessions = [
        WorkSession(
          siteId: '${m['projectId']}',
          kind: m['siteKind'] == 'mockup' ? SiteKind.mockup : SiteKind.project,
          siteName: '${m['projectName'] ?? ''}',
          start: start,
          end: end,
          noCheckout: !open && end == null,
          workType: legacyWork?['workType'] as String?,
          squareMeters:
              _num(legacyWork?['squareMeters'] ?? legacyWork?['sqaureMeters']),
        ),
      ];
    }
    sessions.sort((a, b) => a.start.compareTo(b.start));
    return DayEntry(
      sessions,
      reviewed: m['reviewed'] is Map,
      corrections: [
        for (final c in (m['corrections'] as List? ?? const []).whereType<Map>())
          Map<String, dynamic>.from(c),
      ],
    );
  }

  bool get isEmpty => sessions.isEmpty;

  WorkSession? get open {
    for (final s in sessions) {
      if (s.isOpen) return s;
    }
    return null;
  }

  Iterable<WorkSession> atSite(String siteId) =>
      sessions.where((s) => s.siteId == siteId);

  Duration worked([DateTime? now]) =>
      sessions.fold(Duration.zero, (t, s) => t + s.worked(now));

  /// Closed by the system and not yet reviewed by an admin.
  bool get needsReview =>
      !reviewed && sessions.any((s) => s.auto != null || s.noCheckout);
}
