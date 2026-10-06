import 'package:flutter/material.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/screens/notification_settings_screen.dart';
import 'package:royal_marble/widgets/language_picker.dart';

/// App settings behind one drawer entry: language for everyone, and the
/// notification switches for people who receive alerts.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen(
      {super.key, required this.user, required this.getsAlerts, required this.isAdmin});
  final UserData user;
  final bool getsAlerts;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.goldDeep),
                title: Text(l.language),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLanguagePicker(context),
              ),
              if (getsAlerts) ...[
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined,
                      color: AppColors.goldDeep),
                  title: Text(l.notifications),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            NotificationSettingsScreen(user: user, isAdmin: isAdmin)),
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}
