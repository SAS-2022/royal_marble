import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:royal_marble/core/l10n_helpers.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/format.dart';
import 'package:royal_marble/core/roles.dart';
import 'package:royal_marble/core/maps.dart';
import 'package:royal_marble/models/attendance.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/device_status.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/checkin_service.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/screens/site_form_screen.dart';
import 'package:royal_marble/shared/loading.dart';
import 'package:royal_marble/widgets/checkin_card.dart';
import 'package:royal_marble/widgets/status_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Projects and mock-ups share a screen; this adapts both models.
class SiteRef {
  SiteRef.project(ProjectData p)
      : kind = SiteKind.project,
        project = p,
        mockup = null;
  SiteRef.mockup(MockupData m)
      : kind = SiteKind.mockup,
        project = null,
        mockup = m;

  final SiteKind kind;
  final ProjectData? project;
  final MockupData? mockup;

  String get id => project?.uid ?? mockup!.uid!;
  String? get error => project?.error ?? mockup?.error;
  String get name => project?.projectName ?? mockup?.mockupName ?? '';
  String get details => project?.projectDetails ?? mockup?.mockupDetails ?? '';
  String? get status => project?.projectStatus ?? mockup?.mockupStatus;
  Map<String, dynamic>? get address =>
      project?.projectAddress ?? mockup?.mockupAddress;
  double? get radius => project?.radius ?? mockup?.radius;
  String? get contractor =>
      project?.contactorCompany ?? mockup?.contactorCompany;
  String? get contactPerson => project?.contactPerson ?? mockup?.contactPerson;
  String? get phone =>
      (project?.phoneNumber ?? mockup?.phoneNumber)?.phoneNumber;
  String? get email => project?.emailAddress ?? mockup?.emailAddress;
  List<String> get workerIds => [
        for (final w in project?.assignedWorkers ?? mockup?.assignedWorkers ?? [])
          '$w'
      ];
}

/// Opens a site by id and keeps it live: edits, status changes and team
/// changes show up without leaving the screen. Managers also get the roster
/// for the team list; workers never load other users.
class SiteDetailsLoader extends StatelessWidget {
  const SiteDetailsLoader(
      {super.key, required this.kind, required this.id, required this.currentUser});
  final SiteKind kind;
  final String id;
  final UserData currentUser;

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final role = primaryRole(currentUser.roles);
    final manages = role == AppRole.admin || role == AppRole.supervisor;
    final Stream<SiteRef> site = kind == SiteKind.project
        ? db.getProjectById(projectId: id).map(SiteRef.project)
        : db.getMockupById(mockupId: id).map(SiteRef.mockup);
    return StreamBuilder<SiteRef>(
      stream: site,
      builder: (context, siteSnap) => StreamBuilder<List<UserData>>(
        stream: manages ? db.getAllWorkers() : Stream.value(const <UserData>[]),
        builder: (context, usersSnap) {
          final s = siteSnap.data;
          if (siteSnap.hasError || s?.error != null) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(context.l10n.siteNotFound)),
            );
          }
          if (s == null || (manages && !usersSnap.hasData)) {
            return const Scaffold(body: Loading());
          }
          return SiteDetailsScreen(
              site: s, currentUser: currentUser, allWorkers: usersSnap.data!);
        },
      ),
    );
  }
}

/// Read-only overview of a project or mock-up with its team. Admins and
/// supervisors can manage the team; workers get their check-in card.
class SiteDetailsScreen extends StatelessWidget {
  const SiteDetailsScreen(
      {super.key,
      required this.site,
      required this.currentUser,
      required this.allWorkers});

  SiteDetailsScreen.project({
    super.key,
    required ProjectData project,
    required this.currentUser,
    required this.allWorkers,
  }) : site = SiteRef.project(project);

  SiteDetailsScreen.mockup({
    super.key,
    required MockupData mockup,
    required this.currentUser,
    required this.allWorkers,
  }) : site = SiteRef.mockup(mockup);

  final SiteRef site;
  final UserData currentUser;
  final List<UserData> allWorkers;

  void _edit(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SiteFormScreen(kind: site.kind, site: site)),
      );

  Future<void> _changeStatus(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(context.l10n.changeStatus,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          for (final st in siteStatuses)
            ListTile(
              leading: Icon(
                  st == site.status ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: siteStatusTone(st).fg),
              title: Text(siteStatusLabel(context, st)),
              onTap: () => Navigator.pop(context, st),
            ),
        ]),
      ),
    );
    if (picked == null || picked == site.status) return;
    await DatabaseService().setSiteStatus(
        mockup: site.kind == SiteKind.mockup, id: site.id, status: picked);
  }

  @override
  Widget build(BuildContext context) {
    final role = primaryRole(currentUser.roles);
    final manages = role == AppRole.admin || role == AppRole.supervisor;
    final team = allWorkers.where((u) => site.workerIds.contains(u.uid)).toList();
    final lat = (site.address?['Lat'] as num?)?.toDouble();
    final lng = (site.address?['Lng'] as num?)?.toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(site.kind == SiteKind.project ? context.l10n.project : context.l10n.mockup),
        actions: [
          if (role == AppRole.admin)
            IconButton(
              tooltip: context.l10n.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(site.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800)),
            ),
            if (site.status != null)
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: role == AppRole.admin ? () => _changeStatus(context) : null,
                child: StatusPill(siteStatusLabel(context, site.status),
                    tone: siteStatusTone(site.status),
                    icon: role == AppRole.admin ? Icons.expand_more : null),
              ),
          ]),
          if (site.details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(site.details, style: const TextStyle(color: AppColors.muted)),
          ],
          const SizedBox(height: 16),

          // Where
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(prettyAddress(site.address?['addressName'])),
                subtitle: site.radius != null
                    ? Text(context.l10n.checkInRadius(site.radius!.round()))
                    : null,
              ),
              if (lat != null && lng != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: OutlinedButton.icon(
                    onPressed: () => openDirections(lat, lng),
                    icon: const Icon(Icons.directions),
                    label: Text(context.l10n.directions),
                  ),
                ),
            ]),
          ),

          if (!manages && role != AppRole.sales) ...[
            SectionTitle(context.l10n.today),
            CheckInCard(
              user: currentUser,
              kind: site.kind,
              siteId: site.id,
              siteName: site.name,
              lat: lat,
              lng: lng,
              radius: site.radius,
            ),
          ],

          // Contact
          if (site.contractor != null ||
              site.contactPerson != null ||
              site.phone != null) ...[
            SectionTitle(context.l10n.contractor),
            Card(
              child: Column(children: [
                if (site.contractor?.isNotEmpty == true)
                  ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: Text(site.contractor!),
                  ),
                if (site.contactPerson?.isNotEmpty == true)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(site.contactPerson!),
                  ),
                if (site.phone?.isNotEmpty == true)
                  ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: Text(site.phone!, textDirection: TextDirection.ltr),
                    trailing: const Icon(Icons.call, color: AppColors.ok),
                    onTap: () =>
                        launchUrl(Uri(scheme: 'tel', path: site.phone)),
                  ),
                if (site.email?.isNotEmpty == true)
                  ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: Text(site.email!),
                    onTap: () =>
                        launchUrl(Uri(scheme: 'mailto', path: site.email)),
                  ),
              ]),
            ),
          ],

          // Team
          SectionTitle(context.l10n.teamCount(site.workerIds.length),
              trailing: manages
                  ? TextButton.icon(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => _ManageTeamSheet(
                          site: site,
                          allWorkers: allWorkers,
                          viewerIsAdmin: role == AppRole.admin,
                        ),
                      ),
                      icon: const Icon(Icons.group_add_outlined, size: 18),
                      label: Text(context.l10n.manage),
                    )
                  : null),
          if (team.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  site.workerIds.isEmpty
                      ? context.l10n.nobodyAssigned
                      : context.l10n.peopleAssigned(site.workerIds.length),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('time_sheet')
                  .doc(timesheetDayId())
                  .snapshots(),
              builder: (context, snap) => Card(
                child: Column(children: [
                  for (final (i, u) in team.indexed) ...[
                    if (i > 0) const Divider(indent: 16, endIndent: 16),
                    _TeamMemberTile(
                      user: u,
                      siteId: site.id,
                      today: DayEntry.fromMap(snap.data?.data()?[u.uid] as Map?),
                    ),
                  ],
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

/// One team member: today's attendance (here, elsewhere, done, not yet) and
/// the phone's health.
class _TeamMemberTile extends StatelessWidget {
  const _TeamMemberTile(
      {required this.user, required this.siteId, required this.today});
  final UserData user;
  final String siteId;
  final DayEntry today;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = DeviceStatus.fromMap(user.deviceStatus);
    final open = today.open;
    final hm = DateFormat('HH:mm');
    final here = today.atSite(siteId).toList();
    final hereToday = here.fold(Duration.zero, (t, x) => t + x.worked());
    final (String state, Tone tone) = switch (null) {
      _ when open != null && open.siteId == siteId => (
          open.outsideSince != null
              ? l.outsideSiteSince(hm.format(open.outsideSince!))
              : l.onSiteSince(hm.format(open.start), localizedDuration(l, open.worked())),
          open.outsideSince != null ? Tone.warn : Tone.ok
        ),
      _ when open != null => (l.checkedInAtSite(open.siteName), Tone.neutral),
      _ when here.isNotEmpty => (l.doneToday(localizedDuration(l, hereToday)), Tone.neutral),
      _ => (l.notCheckedIn, Tone.neutral),
    };
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.gold.withValues(alpha: 0.2),
        child: Text(
          '${user.firstName?.characters.firstOrNull ?? ''}${user.lastName?.characters.firstOrNull ?? ''}',
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.goldDeep),
        ),
      ),
      title: Text('${user.firstName ?? ''} ${user.lastName ?? ''}'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(spacing: 6, runSpacing: 4, children: [
          Text(primaryRole(user.roles).localized(l)),
          StatusPill(state, tone: tone),
        ]),
      ),
      trailing: !s.hasData
          ? null
          : s.problems.isNotEmpty
              ? StatusPill(s.problems.first.text(l), tone: Tone.bad)
              : const Icon(Icons.check_circle, color: AppColors.ok),
    );
  }
}

class _ManageTeamSheet extends StatefulWidget {
  const _ManageTeamSheet({
    required this.site,
    required this.allWorkers,
    required this.viewerIsAdmin,
  });
  final SiteRef site;
  final List<UserData> allWorkers;
  final bool viewerIsAdmin;

  @override
  State<_ManageTeamSheet> createState() => _ManageTeamSheetState();
}

class _ManageTeamSheetState extends State<_ManageTeamSheet> {
  late final Set<String> _selected = widget.site.workerIds.toSet();
  String _query = '';
  bool _saving = false;

  /// The worker's other sites of the same kind, if any. Adding them here
  /// keeps those assignments.
  String? _elsewhere(UserData u) {
    final others = siteAssignments(widget.site.kind == SiteKind.project
            ? u.assignedProject
            : u.assignedMockups)
        .where((a) => a['id'] != widget.site.id)
        .map((a) => '${a['name']}');
    return others.isEmpty ? null : others.join(', ');
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    final db = DatabaseService();
    final byId = {for (final u in widget.allWorkers) u.uid: u};
    final added = [for (final id in _selected) if (byId[id] != null) byId[id]!];
    final removed = [
      for (final id in widget.site.workerIds)
        if (!_selected.contains(id) && byId[id] != null) byId[id]!
    ];
    final ids = _selected.toList();
    final result = widget.site.kind == SiteKind.project
        ? await db.updateProjectWithWorkers(
            project: widget.site.project,
            selectedUserIds: ids,
            addedUsers: added,
            removedUsers: removed)
        : await db.updateMockupWithWorkers(
            mockup: widget.site.mockup,
            selectedUserIds: ids,
            addedUsers: added,
            removedUsers: removed);
    if (!mounted) return;
    setState(() => _saving = false);
    final ok = result == 'Completed';
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: ok ? AppColors.ok : AppColors.bad,
      content: Text(ok ? l10n.teamUpdated : l10n.teamUpdateFailed),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.allWorkers
        .where((u) =>
            u.isActive == true &&
            u.error == null &&
            (widget.viewerIsAdmin || primaryRole(u.roles) != AppRole.admin) &&
            '${u.firstName} ${u.lastName}'
                .toLowerCase()
                .contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) {
        final sa = _selected.contains(a.uid) ? 0 : 1;
        final sb = _selected.contains(b.uid) ? 0 : 1;
        return sa != sb
            ? sa - sb
            : '${a.firstName}'.compareTo('${b.firstName}');
      });

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(children: [
            Expanded(
              child: Text(context.l10n.teamOf(widget.site.name),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            Text(context.l10n.selectedCount(_selected.length),
                style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: context.l10n.searchPeople,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: candidates.length,
            itemBuilder: (context, i) {
              final u = candidates[i];
              final elsewhere = _elsewhere(u);
              final selected = _selected.contains(u.uid);
              return CheckboxListTile(
                value: selected,
                onChanged: (v) => setState(
                    () => v! ? _selected.add(u.uid!) : _selected.remove(u.uid)),
                title: Text('${u.firstName ?? ''} ${u.lastName ?? ''}'),
                subtitle: Text([
                  primaryRole(u.roles).localized(context.l10n),
                  if (elsewhere != null) context.l10n.currentlyAt(elsewhere),
                ].join(' · ')),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(context.l10n.saveTeam),
            ),
          ),
        ),
      ]),
    );
  }
}
