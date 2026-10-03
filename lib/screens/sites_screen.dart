import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/locale_controller.dart';
import '../models/user_model.dart';
import '../services/checkin_service.dart' show SiteKind;
import '../services/database.dart';
import '../shared/loading.dart';
import '../widgets/status_widgets.dart';
import 'site_details_screen.dart';
import 'site_form_screen.dart';

/// Every project and mock-up, filtered by kind and status, with search and a
/// button to add a new one. Closed sites are only reachable from here.
class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key, required this.currentUser});
  final UserData currentUser;

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  SiteKind? _kind;
  String? _status = 'active';
  String _query = '';

  final _db = DatabaseService();
  late final _projects = _db.getAllProjects();
  late final _mockups = _db.getAllMockups();

  void _open(SiteRef s) => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SiteDetailsLoader(
                kind: s.kind, id: s.id, currentUser: widget.currentUser)),
      );

  Future<void> _add() async {
    final l = context.l10n;
    final kind = await showModalBottomSheet<SiteKind>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.apartment),
            title: Text(l.newProject),
            onTap: () => Navigator.pop(context, SiteKind.project),
          ),
          ListTile(
            leading: const Icon(Icons.view_in_ar),
            title: Text(l.newMockup),
            onTap: () => Navigator.pop(context, SiteKind.mockup),
          ),
        ]),
      ),
    );
    if (kind == null || !mounted) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                SiteFormScreen(
                kind: kind,
                createdBy: widget.currentUser.uid,
                currentUser: widget.currentUser)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.allSites)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(l.newSite),
      ),
      body: StreamBuilder(
        stream: _projects,
        builder: (context, p) => StreamBuilder(
          stream: _mockups,
          builder: (context, m) {
            if (!p.hasData || !m.hasData) return const Loading();
            final all = [
              for (final x in p.data!) if (x.error == null) SiteRef.project(x),
              for (final x in m.data!) if (x.error == null) SiteRef.mockup(x),
            ];
            int count(String? st) => all
                .where((s) => (_kind == null || s.kind == _kind) &&
                    (st == null || s.status == st))
                .length;
            final q = _query.toLowerCase();
            final shown = all
                .where((s) =>
                    (_kind == null || s.kind == _kind) &&
                    (_status == null || s.status == _status) &&
                    (q.isEmpty ||
                        s.name.toLowerCase().contains(q) ||
                        '${s.address?['addressName'] ?? ''}'.toLowerCase().contains(q) ||
                        (s.contractor ?? '').toLowerCase().contains(q)))
                .toList()
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: l.searchSites,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                const SizedBox(height: 10),
                SegmentedButton<SiteKind?>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: null, label: Text(l.everything)),
                    ButtonSegment(
                        value: SiteKind.project,
                        icon: const Icon(Icons.apartment, size: 18),
                        label: Text(l.projectsLabel)),
                    ButtonSegment(
                        value: SiteKind.mockup,
                        icon: const Icon(Icons.view_in_ar, size: 18),
                        label: Text(l.mockupsLabel)),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (v) => setState(() => _kind = v.first),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  for (final st in [...siteStatuses, null])
                    ChoiceChip(
                      label: Text(
                          '${st == null ? l.everything : siteStatusLabel(context, st)} (${count(st)})'),
                      selected: _status == st,
                      onSelected: (_) => setState(() => _status = st),
                    ),
                ]),
                const SizedBox(height: 12),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(l.noSitesFound,
                          style: const TextStyle(color: AppColors.muted)),
                    ),
                  ),
                for (final s in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        onTap: () => _open(s),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.gold.withValues(alpha: 0.18),
                          child: Icon(
                              s.kind == SiteKind.project
                                  ? Icons.apartment
                                  : Icons.view_in_ar,
                              color: AppColors.goldDeep),
                        ),
                        title: Text(s.name,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(prettyAddress(s.address?['addressName']),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusPill(siteStatusLabel(context, s.status),
                                tone: siteStatusTone(s.status)),
                            const SizedBox(height: 4),
                            Text(l.peopleCount(s.workerIds.length),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
