import 'package:flutter/material.dart';
import 'package:royal_marble/core/l10n_helpers.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/account_settings/users_grid.dart';
import 'package:royal_marble/clients/clients_form.dart';
import 'package:royal_marble/clients/clients_grid.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/error_reporter.dart';
import 'package:royal_marble/core/roles.dart';
import 'package:royal_marble/location/map_providers.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/reports/reports_screen.dart';
import 'package:royal_marble/sales_pipeline/visit_forms.dart/visit_form_streams.dart';
import 'package:royal_marble/screens/my_profile_screen.dart';
import 'package:royal_marble/screens/salary_screens.dart';
import 'package:royal_marble/screens/site_form_screen.dart';
import 'package:royal_marble/screens/sites_screen.dart';
import 'package:royal_marble/services/checkin_service.dart' show SiteKind;
import 'package:royal_marble/screens/team_status_screen.dart';
import 'package:royal_marble/services/auth.dart';
import 'package:royal_marble/services/tracking_service.dart';
import 'package:royal_marble/widgets/language_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key, this.currentUser, this.allUsers});
  final UserData? currentUser;
  final List<UserData>? allUsers;

  @override
  Widget build(BuildContext context) {
    final user = currentUser;
    if (user == null || user.roles == null) return const Drawer();
    final role = primaryRole(user.roles);
    final admin = role == AppRole.admin;
    final supervisor = role == AppRole.supervisor;
    final sales = role == AppRole.sales;

    void open(Widget page) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }

    final l = context.l10n;
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          _Header(user: user, role: role),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _Item(Icons.person_outline, l.myProfile,
                    () => open(MyProfileScreen(user: user))),
                if (!admin)
                  _Item(Icons.payments_outlined, l.myPay,
                      () => open(MyPayScreen(user: user))),
                if (admin || supervisor) ...[
                  _Group(l.sectionTeam),
                  _Item(Icons.notifications_active_outlined,
                      l.teamStatusAlerts,
                      () => open(TeamStatusScreen(users: allUsers ?? const []))),
                  _Item(Icons.map_outlined, l.liveMap,
                      () => open(MapProviders(
                            allUsers: allUsers,
                            currentUser: user,
                            listOfMarkers: 'users',
                            addNewProject: false,
                            addNewMockup: false,
                          ))),
                  _Item(Icons.people_outline, l.users,
                      () => open(UserGrid(currentUser: user))),
                ],
                if (admin || sales || supervisor) ...[
                  _Group(l.sectionSites),
                  _Item(Icons.location_city_outlined, l.allSites,
                      () => open(SitesScreen(currentUser: user))),
                  _Item(Icons.add_business_outlined, l.newProject,
                      () => open(SiteFormScreen(
                          kind: SiteKind.project,
                          createdBy: user.uid,
                          currentUser: user))),
                  _Item(Icons.view_in_ar_outlined, l.newMockup,
                      () => open(SiteFormScreen(
                          kind: SiteKind.mockup,
                          createdBy: user.uid,
                          currentUser: user))),
                ],
                if (admin || sales) ...[
                  _Group(l.sectionSales),
                  _Item(Icons.storefront_outlined, l.clients,
                      () => open(ClientGrid(currentUser: user))),
                  _Item(Icons.person_add_alt, l.addClient,
                      () => open(
                          ClientForm(isNewClient: true, currentUser: user))),
                  _Item(Icons.edit_calendar_outlined, l.newVisit,
                      () => open(VisitFormStreams(
                          currentUser: user, viewingVisit: false))),
                  _Item(Icons.event_note_outlined, l.visits,
                      () => open(VisitFormStreams(
                          currentUser: user, viewingVisit: true))),
                ],
                if (admin || supervisor) ...[
                  _Group(l.sectionReports),
                  _Item(Icons.schedule_outlined, l.attendance,
                      () => open(ReportsScreen(canCorrect: admin))),
                  _Item(Icons.sell_outlined, l.salesActivity,
                      () => open(
                          const ReportsScreen(initial: ReportKind.sales))),
                ],
                const Divider(height: 24),
                _Item(Icons.language, l.language,
                    () => showLanguagePicker(context)),
              ],
            ),
          ),
          const Divider(),
          SafeArea(
            top: false,
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.bad),
              title: Text(l.signOut,
                  style: const TextStyle(
                      color: AppColors.bad, fontWeight: FontWeight.w600)),
              onTap: () => _signOut(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.signOutTitle),
        content: Text(l.signOutBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.signOut)),
        ],
      ),
    );
    if (confirmed != true) return;
    await TrackingService.stop();
    await ErrorReporter.setUser();
    await AuthService().signOut();
    // Clear session data but keep the device's language choice.
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('appLocale');
    await prefs.clear();
    if (lang != null) await prefs.setString('appLocale', lang);
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.role});
  final UserData user;
  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final initials =
        '${user.firstName?.characters.firstOrNull ?? ''}${user.lastName?.characters.firstOrNull ?? ''}';
    final hasImage = user.imageUrl?.startsWith('http') == true;
    return Container(
      width: double.infinity,
      color: AppColors.charcoal,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 24, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.gold,
          foregroundImage: hasImage ? NetworkImage(user.imageUrl!) : null,
          child: Text(initials,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal)),
        ),
        const SizedBox(height: 14),
        Text('${user.firstName ?? ''} ${user.lastName ?? ''}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(role.localized(context.l10n),
            style: const TextStyle(color: AppColors.gold, fontSize: 14)),
        if (user.emailAddress != null)
          Text(user.emailAddress!,
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
      ]),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: AppColors.muted)),
      );
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        leading: Icon(icon, color: AppColors.ink),
        title: Text(label, style: const TextStyle(fontSize: 15)),
        onTap: onTap,
      );
}
