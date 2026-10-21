import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../core/page_access.dart';
import '../core/roles.dart';
import '../l10n/app_localizations.dart';
import '../models/user_model.dart';
import '../shared/loading.dart';
import '../widgets/status_widgets.dart';

extension AppPageLabel on AppPage {
  String label(AppLocalizations l) => switch (this) {
        AppPage.teamStatus => l.teamStatusAlerts,
        AppPage.liveMap => l.liveMap,
        AppPage.users => l.users,
        AppPage.sites => l.sectionSites,
        AppPage.clients => l.clients,
        AppPage.visits => l.visits,
        AppPage.reports => l.sectionReports,
        AppPage.overtime => l.overtime,
        AppPage.payroll => l.payroll,
        AppPage.leaveRequests => l.leaveRequests,
      };

  IconData get icon => switch (this) {
        AppPage.teamStatus => Icons.notifications_active_outlined,
        AppPage.liveMap => Icons.map_outlined,
        AppPage.users => Icons.people_outline,
        AppPage.sites => Icons.location_city_outlined,
        AppPage.clients => Icons.storefront_outlined,
        AppPage.visits => Icons.event_note_outlined,
        AppPage.reports => Icons.bar_chart_outlined,
        AppPage.overtime => Icons.more_time,
        AppPage.payroll => Icons.account_balance_wallet_outlined,
        AppPage.leaveRequests => Icons.beach_access_outlined,
      };
}

/// Admins only: which menu pages each role sees. Saved as each switch
/// changes; the Firestore rules read the same settings.
class PageAccessScreen extends StatefulWidget {
  const PageAccessScreen({super.key, required this.viewer});
  final UserData viewer;

  @override
  State<PageAccessScreen> createState() => _PageAccessScreenState();
}

class _PageAccessScreenState extends State<PageAccessScreen> {
  late final _access = PageAccess.watch();

  /// Every role but admin, who always sees everything.
  static final _roles = AppRole.values.where((r) => r != AppRole.admin);

  Future<void> _run(Future<void> Function() write) async {
    try {
      await write();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.bad, content: Text(context.l10n.pageAccessSaveFailed)));
    }
  }

  void _toggle(PageAccess access, AppRole role, AppPage page, bool on) {
    final pages = {...access.pagesFor(role)};
    on ? pages.add(page) : pages.remove(page);
    _run(() => PageAccess.save(role, pages, byUid: widget.viewer.uid!));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.pageAccess)),
      body: StreamBuilder<PageAccess>(
        stream: _access,
        builder: (context, snap) {
          final access = snap.data;
          if (access == null) return const Loading();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(l.pageAccessIntro, style: const TextStyle(color: AppColors.muted)),
              for (final role in _roles) ...[
                SectionTitle(role.localized(l),
                    trailing: access.isDefault(role)
                        ? StatusPill(l.pageAccessDefault)
                        : TextButton(
                            onPressed: () => _run(
                                () => PageAccess.reset(role, byUid: widget.viewer.uid!)),
                            child: Text(l.pageAccessReset))),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final page in AppPage.values)
                        FilterChip(
                          avatar: Icon(page.icon, size: 18),
                          // The fill shows the choice; a check would hide the icon.
                          showCheckmark: false,
                          label: Text(page.label(l)),
                          selected: access.sees(role, page),
                          onSelected: (on) => _toggle(access, role, page, on),
                        ),
                    ]),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
