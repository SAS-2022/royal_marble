import 'package:flutter/material.dart';
import 'package:royal_marble/core/l10n_helpers.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/format.dart';
import 'package:royal_marble/core/roles.dart';
import 'package:royal_marble/location/google_map_navigation.dart';
import 'package:royal_marble/mockups/mockup_form.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/device_status.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/projects/project_form.dart';
import 'package:royal_marble/services/checkin_service.dart';
import 'package:royal_marble/services/database.dart';
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

/// Read-only overview of a project or mock-up with its team. Admins and
/// supervisors can manage the team; workers get their check-in card.
class SiteDetailsScreen extends StatelessWidget {
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

  Tone get _statusTone => switch (site.status) {
        'active' => Tone.ok,
        'potential' => Tone.warn,
        'closed' => Tone.bad,
        _ => Tone.neutral,
      };

  void _edit(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => site.kind == SiteKind.project
              ? ProjectForm(
                  selectedProject: site.project,
                  isNewProject: false,
                  allWorkers: allWorkers,
                  currentUser: currentUser,
                )
              : MockupForm(
                  selectedMockUp: site.mockup,
                  isNewMockup: false,
                  allWorkers: allWorkers,
                  currentUser: currentUser,
                ),
        ),
      );

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
              StatusPill(site.status!.toUpperCase(), tone: _statusTone),
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
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GoogleMapNavigation(
                            lat: lat, lng: lng, navigate: true),
                      ),
                    ),
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
                    title: Text(site.phone!),
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
            Card(
              child: Column(children: [
                for (final (i, u) in team.indexed) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  _TeamMemberTile(user: u),
                ],
              ]),
            ),
        ],
      ),
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  const _TeamMemberTile({required this.user});
  final UserData user;

  @override
  Widget build(BuildContext context) {
    final s = DeviceStatus.fromMap(user.deviceStatus);
    final onSite = user.distanceToProject is num &&
        (user.distanceToProject as num) <= 0 &&
        s.lastSeen != null &&
        DateTime.now().difference(s.lastSeen!).inMinutes < 30;
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
      subtitle: Text(primaryRole(user.roles).localized(context.l10n)),
      trailing: !s.hasData
          ? null
          : s.problems.isNotEmpty
              ? StatusPill(s.problems.first.text(context.l10n), tone: Tone.bad)
              : onSite
                  ? StatusPill(context.l10n.onSite, tone: Tone.ok)
                  : StatusPill(context.l10n.away),
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

  /// Where a worker is currently assigned, if somewhere else.
  String? _elsewhere(UserData u) {
    final a = widget.site.kind == SiteKind.project
        ? u.assignedProject
        : u.assignedMockups;
    final list = a is List ? a : [a];
    for (final x in list) {
      if (x is Map && x['id'] != null && x['id'] != widget.site.id) {
        return '${x['name']}';
      }
    }
    return null;
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
                  if (elsewhere != null)
                    selected && primaryRole(u.roles) != AppRole.supervisor
                        ? context.l10n.willMoveFrom(elsewhere)
                        : context.l10n.currentlyAt(elsewhere),
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
