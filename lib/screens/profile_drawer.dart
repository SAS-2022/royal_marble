import 'package:flutter/material.dart';
import 'package:royal_marble/core/l10n_helpers.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/account_settings/users_grid.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/error_reporter.dart';
import 'package:royal_marble/core/roles.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/reports/reports_screen.dart';
import 'package:royal_marble/screens/clients_screen.dart';
import 'package:royal_marble/screens/live_map_screen.dart';
import 'package:royal_marble/screens/my_profile_screen.dart';
import 'package:royal_marble/screens/settings_screen.dart';
import 'package:royal_marble/screens/salary_screens.dart';
import 'package:royal_marble/screens/sites_screen.dart';
import 'package:royal_marble/services/push_service.dart';
import 'package:royal_marble/screens/team_status_screen.dart';
import 'package:royal_marble/screens/visits_screen.dart';
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
                // Work first; the "new …" actions live as + buttons on
                // each list, and Reports switches between attendance and sales.
                if (admin || supervisor) ...[
                  _Item(Icons.notifications_active_outlined, l.teamStatusAlerts,
                      () => open(TeamStatusScreen(users: allUsers ?? const []))),
                  _Item(Icons.map_outlined, l.liveMap,
                      () => open(LiveMapScreen(currentUser: user))),
                  _Item(Icons.people_outline, l.users,
                      () => open(UserGrid(currentUser: user))),
                ],
                if (admin || sales || supervisor)
                  _Item(Icons.location_city_outlined, l.sectionSites,
                      () => open(SitesScreen(currentUser: user))),
                if (admin || sales) ...[
                  _Item(Icons.storefront_outlined, l.clients,
                      () => open(ClientsScreen(currentUser: user))),
                  _Item(Icons.event_note_outlined, l.visits,
                      () => open(VisitsScreen(currentUser: user))),
                ],
                if (admin || supervisor)
                  _Item(Icons.bar_chart_outlined, l.sectionReports,
                      () => open(ReportsScreen(canCorrect: admin))),
                if (admin || supervisor || sales) const Divider(height: 24),
                _Item(Icons.person_outline, l.myProfile,
                    () => open(MyProfileScreen(user: user))),
                if (!admin)
                  _Item(Icons.payments_outlined, l.myPay,
                      () => open(MyPayScreen(user: user))),
                _Item(Icons.settings_outlined, l.settings,
                    () => open(SettingsScreen(
                        user: user,
                        getsAlerts: admin || supervisor,
                        isAdmin: admin))),
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
    await PushService.stop();
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
