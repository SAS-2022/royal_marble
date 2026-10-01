import 'package:flutter/material.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/format.dart';
import 'package:royal_marble/core/roles.dart';
import 'package:royal_marble/models/device_status.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/screens/salary_screens.dart';
import 'package:royal_marble/screens/team_status_screen.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/widgets/status_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// What an admin/supervisor sees when opening another user: contact details,
/// role, access, phone health and recent alerts.
class AdminUserView extends StatelessWidget {
  const AdminUserView({
    super.key,
    required this.user,
    required this.viewer,
    required this.db,
    required this.onBusy,
  });

  final UserData user;
  final UserData viewer;
  final DatabaseService db;
  final ValueChanged<bool> onBusy;

  void _toast(BuildContext context, String msg, {bool ok = true}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: ok ? AppColors.ok : AppColors.bad,
          content: Text(msg)));

  Future<void> _setRole(BuildContext context, AppRole role) async {
    onBusy(true);
    final result =
        await db.assignUserRole(selectedRole: role.label, uid: user.uid);
    onBusy(false);
    if (!context.mounted) return;
    result == 'Completed'
        ? _toast(context, 'Role changed to ${role.label}')
        : _toast(context, 'Could not change the role: $result', ok: false);
  }

  Future<void> _setActive(BuildContext context, bool active) async {
    onBusy(true);
    final result =
        await db.activateDeactivateUser(uid: user.uid, active: active);
    onBusy(false);
    if (!context.mounted) return;
    result == 'Completed'
        ? _toast(context, active ? 'Account activated' : 'Account deactivated')
        : _toast(context, 'Could not update access: $result', ok: false);
  }

  Future<void> _delete(BuildContext context) async {
    final name = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text(
            'Their profile is removed permanently. Past timesheets are kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.bad),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    onBusy(true);
    await db.deleteUser(uid: user.uid);
    onBusy(false);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final role = primaryRole(user.roles);
    final viewerIsAdmin = primaryRole(viewer.roles) == AppRole.admin;
    final status = DeviceStatus.fromMap(user.deviceStatus);
    final active = user.isActive == true;
    final hasImage = user.imageUrl?.startsWith('http') == true;
    final site = user.assignedProject is Map
        ? (user.assignedProject as Map)['name']
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Identity
          Row(children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.gold.withValues(alpha: 0.2),
              foregroundImage: hasImage ? NetworkImage(user.imageUrl!) : null,
              child: Text(
                '${user.firstName?.characters.firstOrNull ?? ''}${user.lastName?.characters.firstOrNull ?? ''}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldDeep),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user.firstName ?? ''} ${user.lastName ?? ''}',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    StatusPill(role.label, icon: Icons.badge_outlined),
                    active
                        ? const StatusPill('Active', tone: Tone.ok)
                        : const StatusPill('Pending / inactive',
                            tone: Tone.warn),
                  ]),
                ],
              ),
            ),
          ]),
          if (!active) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.warnSoft,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.how_to_reg, color: AppColors.warn),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('This account is waiting for access.',
                      style: TextStyle(color: AppColors.ink)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      backgroundColor: AppColors.ok),
                  onPressed: () => _setActive(context, true),
                  child: const Text('Approve'),
                ),
              ]),
            ),
          ],

          // Contact
          const SectionTitle('Contact'),
          Card(
            child: Column(children: [
              if (user.phoneNumber?.isNotEmpty == true)
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(user.phoneNumber!),
                  trailing: const Icon(Icons.call, color: AppColors.ok),
                  onTap: () =>
                      launchUrl(Uri(scheme: 'tel', path: user.phoneNumber)),
                ),
              if (user.emailAddress?.isNotEmpty == true)
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: Text(user.emailAddress!),
                  onTap: () =>
                      launchUrl(Uri(scheme: 'mailto', path: user.emailAddress)),
                ),
              if (user.nationality?['countryName'] != null)
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text('${user.nationality!['countryName']}'),
                ),
              if (user.company?.isNotEmpty == true)
                ListTile(
                  leading: const Icon(Icons.business_outlined),
                  title: Text(user.company!),
                ),
              if (user.homeAddress?['addressName'] != null)
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: Text(prettyAddress(user.homeAddress!['addressName'])),
                ),
            ]),
          ),

          // Work and phone health
          if (active && !role.canMonitor) ...[
            const SectionTitle('Work'),
            Card(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.apartment_outlined),
                  title: Text(site != null ? '$site' : 'No site assigned'),
                  subtitle: const Text('Assigned site'),
                ),
                ListTile(
                  leading: Icon(
                      status.healthy
                          ? Icons.check_circle_outline
                          : Icons.phonelink_erase,
                      color: !status.hasData
                          ? AppColors.muted
                          : status.healthy
                              ? AppColors.ok
                              : AppColors.bad),
                  title: Text(!status.hasData
                      ? 'Not on the new app version yet'
                      : status.healthy
                          ? 'Phone is reporting normally'
                          : status.problems.join(' · ')),
                  subtitle: Text('Last seen ${timeAgo(status.lastSeen)}'),
                ),
              ]),
            ),
            const SectionTitle('Recent alerts'),
            Card(
              child: SizedBox(
                height: 260,
                child: AlertsFeed(uid: user.uid, limit: 100),
              ),
            ),
          ],

          // Pay (admins only; supervisors don't see salaries)
          if (viewerIsAdmin && active) ...[
            const SectionTitle('Pay'),
            SalaryCard(user: user, canEdit: true),
          ],

          // Role
          const SectionTitle('Role'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in AppRole.values)
              if (viewerIsAdmin || r != AppRole.admin)
                ChoiceChip(
                  label: Text(r.label),
                  selected: role == r,
                  onSelected: role == r ? null : (_) => _setRole(context, r),
                ),
          ]),

          // Access
          const SectionTitle('Access'),
          if (active)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.bad),
              onPressed: () => _setActive(context, false),
              icon: const Icon(Icons.block),
              label: const Text('Deactivate account'),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.ok),
              onPressed: () => _setActive(context, true),
              icon: const Icon(Icons.check),
              label: const Text('Activate account'),
            ),
          if (viewerIsAdmin) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.bad),
              onPressed: active ? null : () => _delete(context),
              icon: const Icon(Icons.delete_outline),
              label: Text(active
                  ? 'Deactivate before deleting'
                  : 'Delete account permanently'),
            ),
          ],
        ],
      ),
    );
  }
}
