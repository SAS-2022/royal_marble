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
import 'package:royal_marble/widgets/web_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer(
      {super.key, this.currentUser, this.allUsers, this.onOpen, this.current});
  final UserData? currentUser;
  final List<UserData>? allUsers;

  /// Set when the menu is the web dashboard's sidebar: pages open beside it.
  final OpenPage? onOpen;

  /// Sidebar only: the type of the page on show, to highlight its item.
  final Type? current;

  @override
  Widget build(BuildContext context) {
    final user = currentUser;
    if (user == null || user.roles == null) return const Drawer();
    final role = primaryRole(user.roles);
    final admin = role == AppRole.admin;
    final supervisor = role == AppRole.supervisor;
    final sales = role == AppRole.sales;
    final hr = role == AppRole.hr;

    void open(Widget page) {
      if (onOpen != null) return onOpen!(page);
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }

    final l = context.l10n;
    final sidebar = onOpen != null;
    return Drawer(
      backgroundColor: AppColors.surface,
      width: sidebar ? double.infinity : null,
      elevation: sidebar ? 0 : null,
      shape: sidebar ? const RoundedRectangleBorder() : null,
      child: Column(
        children: [
          _Header(user: user, role: role),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (sidebar)
                  _Item(Icons.dashboard_outlined, l.dashboard,
                      selected: current == null, () => onOpen!(null)),
                // Work first; the "new …" actions live as + buttons on
                // each list, and Reports switches between attendance and sales.
                if (admin || supervisor) ...[
                  _Item(Icons.notifications_active_outlined, l.teamStatusAlerts,
                      selected: sidebar && current == TeamStatusScreen,
                      () => open(TeamStatusScreen(users: allUsers ?? const [], viewer: user))),
                  _Item(Icons.map_outlined, l.liveMap,
                      selected: sidebar && current == LiveMapScreen,
                      () => open(LiveMapScreen(currentUser: user))),
                ],
                if (admin || supervisor || hr)
                  _Item(Icons.people_outline, l.users,
                      selected: sidebar && current == UserGrid,
                      () => open(UserGrid(currentUser: user))),
                if (admin || sales || supervisor)
                  _Item(Icons.location_city_outlined, l.sectionSites,
                      selected: sidebar && current == SitesScreen,
                      () => open(SitesScreen(currentUser: user))),
                if (admin || sales) ...[
                  _Item(Icons.storefront_outlined, l.clients,
                      selected: sidebar && current == ClientsScreen,
                      () => open(ClientsScreen(currentUser: user))),
                  _Item(Icons.event_note_outlined, l.visits,
                      selected: sidebar && current == VisitsScreen,
                      () => open(VisitsScreen(currentUser: user))),
                ],
                if (admin || supervisor || hr)
                  _Item(Icons.bar_chart_outlined, l.sectionReports,
                      selected: sidebar && current == ReportsScreen,
                      () => open(ReportsScreen(canCorrect: role.managesPay))),
                if (admin || supervisor || sales || hr) const Divider(height: 24),
                _Item(Icons.person_outline, l.myProfile,
                    selected: sidebar && current == MyProfileScreen,
                    () => open(MyProfileScreen(user: user))),
                if (!admin)
                  _Item(Icons.payments_outlined, l.myPay,
                      selected: sidebar && current == MyPayScreen,
                      () => open(MyPayScreen(user: user))),
                _Item(Icons.settings_outlined, l.settings,
                    selected: sidebar && current == SettingsScreen,
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
          // No connection or a deleted photo: show the fallback instead.
          onForegroundImageError: hasImage ? (_, __) {} : null,
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
  const _Item(this.icon, this.label, this.onTap, {this.selected = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        selected: selected,
        selectedColor: AppColors.charcoal,
        selectedTileColor: AppColors.gold.withValues(alpha: 0.18),
        leading: Icon(icon, color: AppColors.ink),
        title: Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        onTap: onTap,
      );
}
