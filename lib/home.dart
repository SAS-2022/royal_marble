import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/format.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/core/roles.dart';
import 'package:royal_marble/mockups/mockup_grid.dart';
import 'package:royal_marble/mockups/mockup_status.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/device_status.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/projects/project_grid.dart';
import 'package:royal_marble/projects/project_status.dart';
import 'package:royal_marble/projects/worker_current_state.dart';
import 'package:royal_marble/sales_pipeline/visit_forms.dart/visit_form_streams.dart';
import 'package:royal_marble/screens/profile_drawer.dart';
import 'package:royal_marble/screens/team_status_screen.dart';
import 'package:royal_marble/services/checkin_service.dart';
import 'package:royal_marble/services/tracking_service.dart';
import 'package:royal_marble/shared/loading.dart';
import 'package:royal_marble/widgets/checkin_card.dart';
import 'package:royal_marble/widgets/status_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.currentUser});
  final UserData? currentUser;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _offline = false;
  String? _trackingStartedFor;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    final connectivity = Connectivity();
    connectivity.checkConnectivity().then(_onConnectivity);
    _connectivitySub = connectivity.onConnectivityChanged.listen(_onConnectivity);
  }

  void _onConnectivity(List<ConnectivityResult> r) {
    final offline = r.isEmpty || r.every((c) => c == ConnectivityResult.none);
    if (mounted && offline != _offline) setState(() => _offline = offline);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  /// Everyone except admins is tracked; restarting is cheap, but only do it
  /// when the user or their assignment changes.
  void _ensureTracking(UserData user) {
    if (user.uid == null || user.isActive != true) return;
    final track = primaryRole(user.roles) != AppRole.admin;
    final key = '${user.uid}|$track|${user.assignedProject}';
    if (_trackingStartedFor == key) return;
    _trackingStartedFor = key;
    // Older versions tracked admins too and set the service to start on boot.
    track ? TrackingService.start(user) : TrackingService.stop();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserData?>(context);
    final allUsers = Provider.of<List<UserData>>(context);

    if (user == null || user.uid == null || user.roles == null) {
      return const Scaffold(body: Center(child: Loading()));
    }
    _ensureTracking(user);
    final role = primaryRole(user.roles);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Royal Marble'),
        actions: [
          if (role.canMonitor) _AlertsAction(users: allUsers),
        ],
      ),
      drawer: ProfileDrawer(currentUser: user, allUsers: allUsers),
      body: Column(
        children: [
          if (_offline)
            Container(
              width: double.infinity,
              color: AppColors.warnSoft,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(children: [
                const Icon(Icons.cloud_off, size: 18, color: AppColors.warn),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(context.l10n.offlineBanner,
                      style: const TextStyle(color: AppColors.warn)),
                ),
              ]),
            ),
          Expanded(
            child: user.isActive != true
                ? const _PendingApproval()
                : switch (role) {
                    AppRole.admin => _AdminHome(user: user),
                    AppRole.sales => _SalesHome(user: user),
                    AppRole.supervisor => _SupervisorHome(user: user),
                    _ => _WorkerHome(user: user),
                  },
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── shared pieces ─────────────────────────

String _greeting(BuildContext context, String name) {
  final l = context.l10n;
  final h = DateTime.now().hour;
  return h < 12
      ? l.greetingMorning(name)
      : h < 17
          ? l.greetingAfternoon(name)
          : l.greetingEvening(name);
}

class _Greeting extends StatelessWidget {
  const _Greeting(this.user);
  final UserData user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            DateFormat('EEEE, d MMMM', context.l10n.localeName)
                .format(DateTime.now()),
            style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(_greeting(context, user.firstName ?? ''),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// A user's assignment field is a single map for workers and a list for
/// supervisors; normalise both to a list of non-empty maps.
List<Map<String, dynamic>> _assignments(dynamic value) {
  final list = value is List ? value : [value];
  return [
    for (final v in list)
      if (v is Map && v['id'] != null) Map<String, dynamic>.from(v),
  ];
}

Widget _cardFor(BuildContext context, UserData user, Map<String, dynamic> a,
    SiteKind kind) {
  final address = a['projectAddress'] as Map?;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: CheckInCard(
      user: user,
      kind: kind,
      siteId: a['id'],
      siteName: '${a['name'] ?? context.l10n.site}',
      details: prettyAddress(address?['addressName']),
      lat: (address?['Lat'] as num?)?.toDouble(),
      lng: (address?['Lng'] as num?)?.toDouble(),
      radius: (a['radius'] as num?)?.toDouble(),
      onOpen: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => kind == SiteKind.project
              ? ProjectGrid(
                  currentUser: user, selectedProject: ProjectData(uid: a['id']))
              : MockupGrid(
                  currentUser: user, selectedMockup: MockupData(uid: a['id'])),
        ),
      ),
    ),
  );
}

class _PendingApproval extends StatelessWidget {
  const _PendingApproval();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.hourglass_top, size: 56, color: AppColors.gold),
          const SizedBox(height: 16),
          Text(context.l10n.pendingTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            context.l10n.pendingBody,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ]),
      ),
    );
  }
}

class _AlertsAction extends StatelessWidget {
  const _AlertsAction({required this.users});
  final List<UserData> users;

  @override
  Widget build(BuildContext context) {
    final count = users
        .where((u) =>
            u.isActive == true &&
            !primaryRole(u.roles).canMonitor &&
            DeviceStatus.fromMap(u.deviceStatus).problems.isNotEmpty)
        .length;
    return IconButton(
      tooltip: context.l10n.teamStatus,
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TeamStatusScreen(users: users))),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

// ───────────────────────── worker ─────────────────────────

class _WorkerHome extends StatelessWidget {
  const _WorkerHome({required this.user});
  final UserData user;

  @override
  Widget build(BuildContext context) {
    final projects = _assignments(user.assignedProject);
    final mockups = _assignments(user.assignedMockups);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _Greeting(user),
        const DeviceStatusBanner(),
        SectionTitle(context.l10n.yourSite),
        if (projects.isEmpty && mockups.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Icon(Icons.location_city, size: 40, color: AppColors.muted),
                const SizedBox(height: 8),
                Text(context.l10n.noSiteTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(context.l10n.noSiteBody,
                    style: const TextStyle(color: AppColors.muted)),
              ]),
            ),
          ),
        for (final p in projects) _cardFor(context, user, p, SiteKind.project),
        for (final m in mockups) _cardFor(context, user, m, SiteKind.mockup),
      ],
    );
  }
}

// ───────────────────────── supervisor ─────────────────────────

class _SupervisorHome extends StatelessWidget {
  const _SupervisorHome({required this.user});
  final UserData user;

  @override
  Widget build(BuildContext context) {
    final allUsers = Provider.of<List<UserData>>(context);
    final timesheet = Provider.of<Map<String, dynamic>>(context);
    final projects = _assignments(user.assignedProject);
    final mockups = _assignments(user.assignedMockups);
    final siteIds = {...projects.map((p) => p['id']), ...mockups.map((m) => m['id'])};
    final team = allUsers
        .where((u) =>
            u.uid != user.uid &&
            u.isActive == true &&
            (_assignments(u.assignedProject).any((a) => siteIds.contains(a['id'])) ||
                _assignments(u.assignedMockups).any((a) => siteIds.contains(a['id']))))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _Greeting(user),
        const DeviceStatusBanner(),
        SectionTitle(context.l10n.yourSites),
        if (projects.isEmpty && mockups.isEmpty)
          Text(context.l10n.noSitesAssigned, style: const TextStyle(color: AppColors.muted)),
        for (final p in projects) _cardFor(context, user, p, SiteKind.project),
        for (final m in mockups) _cardFor(context, user, m, SiteKind.mockup),
        SectionTitle(context.l10n.yourTeam(team.length)),
        _TeamList(users: team, timesheet: timesheet),
      ],
    );
  }
}

/// Compact roster: who is on site today and whether their phone is healthy.
class _TeamList extends StatelessWidget {
  const _TeamList({required this.users, required this.timesheet});
  final List<UserData> users;
  final Map<String, dynamic> timesheet;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Text(context.l10n.nobodyYet, style: const TextStyle(color: AppColors.muted));
    }
    return Card(
      child: Column(children: [
        for (final (i, u) in users.indexed) ...[
          if (i > 0) const Divider(indent: 16, endIndent: 16),
          _TeamRow(user: u, entry: timesheet[u.uid] as Map<String, dynamic>?),
        ],
      ]),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.user, this.entry});
  final UserData user;
  final Map<String, dynamic>? entry;

  @override
  Widget build(BuildContext context) {
    final status = DeviceStatus.fromMap(user.deviceStatus);
    final onSite = entry?['isOnSite'] == true && entry?['leaving_at'] == null;
    final arrived = DateTime.tryParse('${entry?['arriving_at']}');
    final problems = status.problems;
    return ListTile(
      title: Text('${user.firstName ?? ''} ${user.lastName ?? ''}'),
      subtitle: Text(onSite && arrived != null
          ? context.l10n.onSiteAtSince('${entry?['projectName']}', DateFormat('HH:mm').format(arrived))
          : entry?['leaving_at'] != null
              ? context.l10n.checkedOut
              : context.l10n.notCheckedIn),
      trailing: !status.hasData
          ? null
          : problems.isEmpty
              ? const Icon(Icons.check_circle, color: AppColors.ok)
              : StatusPill(problems.first, tone: Tone.bad),
    );
  }
}

// ───────────────────────── admin ─────────────────────────

class _AdminHome extends StatelessWidget {
  const _AdminHome({required this.user});
  final UserData user;

  @override
  Widget build(BuildContext context) {
    final allUsers = Provider.of<List<UserData>>(context);
    final projects = Provider.of<List<ProjectData>>(context);
    final mockups = Provider.of<List<MockupData>>(context);
    final timesheet = Provider.of<Map<String, dynamic>>(context);

    final tracked = allUsers
        .where((u) => u.isActive == true && !primaryRole(u.roles).canMonitor)
        .toList();
    final onSite = timesheet.values
        .whereType<Map>()
        .where((e) => e['isOnSite'] == true && e['leaving_at'] == null)
        .length;
    final attention = tracked
        .where((u) => DeviceStatus.fromMap(u.deviceStatus).problems.isNotEmpty)
        .toList();
    final pending = allUsers.where((u) => u.isActive != true && u.error == null).length;

    final active = projects.where((p) => p.projectStatus == 'active').toList();
    final potential = projects.where((p) => p.projectStatus == 'potential').toList();
    final activeMockups = mockups.where((m) => m.mockupStatus == 'active').toList();

    void openTeam([int tab = 0]) => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TeamStatusScreen(users: allUsers, initialTab: tab)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _Greeting(user),
        Row(children: [
          Expanded(
              child: _StatTile(
                  label: context.l10n.onSiteNow,
                  value: '$onSite',
                  icon: Icons.engineering,
                  tone: Tone.ok)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatTile(
                  label: context.l10n.phoneAlerts,
                  value: '${attention.length}',
                  icon: Icons.notifications_active,
                  tone: attention.isEmpty ? Tone.neutral : Tone.bad,
                  onTap: () => openTeam())),
          const SizedBox(width: 10),
          Expanded(
              child: _StatTile(
                  label: context.l10n.pendingLabel,
                  value: '$pending',
                  icon: Icons.person_add_alt,
                  tone: pending == 0 ? Tone.neutral : Tone.warn)),
        ]),
        if (attention.isNotEmpty) ...[
          SectionTitle(context.l10n.needsAttention,
              trailing: TextButton(
                  onPressed: () => openTeam(), child: Text(context.l10n.seeAll))),
          Card(
            child: Column(children: [
              for (final (i, u) in attention.take(5).indexed) ...[
                if (i > 0) const Divider(indent: 16, endIndent: 16),
                ListTile(
                  onTap: () => openTeam(),
                  title: Text('${u.firstName ?? ''} ${u.lastName ?? ''}'),
                  subtitle: Text(
                      DeviceStatus.fromMap(u.deviceStatus).problems.join(' · ')),
                  trailing: Text(
                      timeAgo(DeviceStatus.fromMap(u.deviceStatus).lastSeen),
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
              ],
            ]),
          ),
        ],
        SectionTitle(context.l10n.todaysAttendance,
            trailing: TextButton(
                onPressed: () => openTeam(1), child: Text(context.l10n.alertLog))),
        _Attendance(timesheet: timesheet),
        SectionTitle(context.l10n.activeProjects(active.length)),
        for (final p in active) _ProjectTile.project(p, user),
        if (activeMockups.isNotEmpty) ...[
          SectionTitle(context.l10n.activeMockups(activeMockups.length)),
          for (final m in activeMockups) _ProjectTile.mockup(m, user),
        ],
        if (potential.isNotEmpty) ...[
          SectionTitle(context.l10n.potentialProjects(potential.length)),
          for (final p in potential) _ProjectTile.project(p, user),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final Tone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: tone.fg, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      ),
    );
  }
}

class _Attendance extends StatelessWidget {
  const _Attendance({required this.timesheet});
  final Map<String, dynamic> timesheet;

  @override
  Widget build(BuildContext context) {
    final rows = timesheet.entries
        .where((e) => e.value is Map)
        .map((e) => Map<String, dynamic>.from(e.value as Map))
        .toList()
      ..sort((a, b) => '${a['arriving_at']}'.compareTo('${b['arriving_at']}'));
    if (rows.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(context.l10n.nobodyCheckedInToday,
              style: const TextStyle(color: AppColors.muted)),
        ),
      );
    }
    String t(dynamic s) {
      final d = DateTime.tryParse('$s');
      return d == null ? '—' : DateFormat('HH:mm').format(d);
    }

    return Card(
      child: Column(children: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) const Divider(indent: 16, endIndent: 16),
          ListTile(
            dense: true,
            title: Text('${r['firstName'] ?? ''} ${r['lastName'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${r['projectName'] ?? ''}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('${t(r['arriving_at'])} → ${t(r['leaving_at'])}'),
              const SizedBox(width: 8),
              Icon(Icons.circle,
                  size: 10,
                  color: r['isOnSite'] == true && r['leaving_at'] == null
                      ? AppColors.ok
                      : AppColors.line),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile.project(ProjectData this.project, this.user) : mockup = null;
  const _ProjectTile.mockup(MockupData this.mockup, this.user) : project = null;

  final ProjectData? project;
  final MockupData? mockup;
  final UserData user;

  String get _name => project?.projectName ?? mockup?.mockupName ?? '';
  String get _address => prettyAddress(
      (project?.projectAddress ?? mockup?.mockupAddress)?['addressName']);
  int get _workers =>
      (project?.assignedWorkers ?? mockup?.assignedWorkers ?? const []).length;

  void _options(BuildContext context) {
    void go(Widget page) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }

    final isAdmin = primaryRole(user.roles) == AppRole.admin;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(_name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          ListTile(
            leading: const Icon(Icons.group_add),
            title: Text(isAdmin ? context.l10n.detailsAssignWorkers : context.l10n.details),
            onTap: () => go(project != null
                ? ProjectGrid(currentUser: user, selectedProject: project)
                : MockupGrid(currentUser: user, selectedMockup: mockup)),
          ),
          if (isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.groups),
              title: Text(context.l10n.workersCurrentState),
              onTap: () => go(WorkerCurrentStream(
                  selectedProject: project, selectedMockup: mockup)),
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: Text(context.l10n.changeStatus),
              onTap: () => go(project != null
                  ? ProjectStatus(selectedProject: project)
                  : MockupStatus(selectedMockup: mockup)),
            ),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          onTap: () => _options(context),
          leading: CircleAvatar(
            backgroundColor: AppColors.gold.withValues(alpha: 0.18),
            child: Icon(project != null ? Icons.apartment : Icons.view_in_ar,
                color: AppColors.goldDeep),
          ),
          title: Text(_name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(_address, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: StatusPill('$_workers', icon: Icons.person),
        ),
      ),
    );
  }
}

// ───────────────────────── sales ─────────────────────────

class _SalesHome extends StatelessWidget {
  const _SalesHome({required this.user});
  final UserData user;

  @override
  Widget build(BuildContext context) {
    final projects = Provider.of<List<ProjectData>>(context);
    final active = projects.where((p) => p.projectStatus == 'active').toList();
    final potential = projects.where((p) => p.projectStatus == 'potential').toList();

    void visits(bool viewing) => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                VisitFormStreams(currentUser: user, viewingVisit: viewing)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _Greeting(user),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => visits(false),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.newVisit),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => visits(true),
              icon: const Icon(Icons.list_alt),
              label: Text(context.l10n.myVisits),
            ),
          ),
        ]),
        SectionTitle(context.l10n.potentialProjects(potential.length)),
        for (final p in potential) _ProjectTile.project(p, user),
        SectionTitle(context.l10n.activeProjects(active.length)),
        for (final p in active) _ProjectTile.project(p, user),
      ],
    );
  }
}
