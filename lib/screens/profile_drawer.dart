import 'package:flutter/material.dart';
import 'package:royal_marble/account_settings/users_details.dart';
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
import 'package:royal_marble/screens/salary_screens.dart';
import 'package:royal_marble/screens/team_status_screen.dart';
import 'package:royal_marble/services/auth.dart';
import 'package:royal_marble/services/tracking_service.dart';
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

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          _Header(user: user, role: role),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _Item(Icons.person_outline, 'My profile',
                    () => open(UserDetails(currentUser: user, myAccount: true))),
                if (!admin)
                  _Item(Icons.payments_outlined, 'My pay',
                      () => open(MyPayScreen(user: user))),
                if (admin || supervisor) ...[
                  const _Group('Team'),
                  _Item(Icons.notifications_active_outlined,
                      'Team status & alerts',
                      () => open(TeamStatusScreen(users: allUsers ?? const []))),
                  _Item(Icons.map_outlined, 'Live map',
                      () => open(MapProviders(
                            allUsers: allUsers,
                            currentUser: user,
                            listOfMarkers: 'users',
                            addNewProject: false,
                            addNewMockup: false,
                          ))),
                  _Item(Icons.people_outline, 'Users',
                      () => open(UserGrid(currentUser: user))),
                ],
                if (admin || sales || supervisor) ...[
                  const _Group('Sites'),
                  _Item(Icons.add_business_outlined, 'New project',
                      () => open(MapProviders(
                            currentUser: user,
                            addNewProject: true,
                            addNewMockup: false,
                            listOfMarkers: 'Add Project',
                          ))),
                  _Item(Icons.view_in_ar_outlined, 'New mock-up',
                      () => open(MapProviders(
                            currentUser: user,
                            addNewProject: false,
                            addNewMockup: true,
                            listOfMarkers: 'Add Mockup',
                          ))),
                ],
                if (admin || sales) ...[
                  const _Group('Sales'),
                  _Item(Icons.storefront_outlined, 'Clients',
                      () => open(ClientGrid(currentUser: user))),
                  _Item(Icons.person_add_alt, 'Add client',
                      () => open(
                          ClientForm(isNewClient: true, currentUser: user))),
                  _Item(Icons.edit_calendar_outlined, 'New visit',
                      () => open(VisitFormStreams(
                          currentUser: user, viewingVisit: false))),
                  _Item(Icons.event_note_outlined, 'Visits',
                      () => open(VisitFormStreams(
                          currentUser: user, viewingVisit: true))),
                ],
                if (admin || supervisor) ...[
                  const _Group('Reports'),
                  _Item(Icons.schedule_outlined, 'Attendance',
                      () => open(const ReportsScreen())),
                  _Item(Icons.sell_outlined, 'Sales activity',
                      () => open(
                          const ReportsScreen(initial: ReportKind.sales))),
                ],
              ],
            ),
          ),
          const Divider(),
          SafeArea(
            top: false,
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.bad),
              title: const Text('Sign out',
                  style: TextStyle(
                      color: AppColors.bad, fontWeight: FontWeight.w600)),
              onTap: () => _signOut(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'Location tracking stops and you won\'t be able to check in until you sign in again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out')),
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
        Text(role.label,
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
