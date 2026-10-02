import 'package:flutter/material.dart';
import 'package:royal_marble/core/l10n_helpers.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/account_settings/users_details.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/roles.dart';
import 'package:royal_marble/models/device_status.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/widgets/status_widgets.dart';

class UserList extends StatefulWidget {
  const UserList({super.key, required this.currentUser});
  final UserData currentUser;

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  String _query = '';
  AppRole? _role;

  bool _matches(UserData u) {
    if (_role != null && primaryRole(u.roles) != _role) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return [u.firstName, u.lastName, u.emailAddress, u.phoneNumber, u.company]
        .any((f) => f?.toLowerCase().contains(q) == true);
  }

  @override
  Widget build(BuildContext context) {
    final users = Provider.of<List<UserData>>(context)
        .where((u) => u.error == null && u.uid != null)
        .toList()
      ..sort((a, b) => '${a.firstName} ${a.lastName}'
          .toLowerCase()
          .compareTo('${b.firstName} ${b.lastName}'.toLowerCase()));
    final active = users.where((u) => u.isActive == true).toList();
    final pending = users.where((u) => u.isActive != true).toList();

    return DefaultTabController(
      length: 2,
      // Land on pending approvals when there are any waiting.
      initialIndex: pending.isNotEmpty ? 1 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Users'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: AppColors.gold,
            tabs: [
              Tab(text: 'Active (${active.length})'),
              Tab(text: 'Pending (${pending.length})'),
            ],
          ),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search name, email or phone',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final r in [null, ...AppRole.values])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(r?.localized(context.l10n) ?? 'All'),
                      selected: _role == r,
                      onSelected: (_) => setState(() => _role = r),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(children: [
              _list(active.where(_matches).toList(), 'No active users match.'),
              _list(pending.where(_matches).toList(),
                  'Nobody is waiting for approval.'),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _list(List<UserData> users, String empty) {
    if (users.isEmpty) {
      return Center(
          child: Text(empty, style: const TextStyle(color: AppColors.muted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _UserTile(
        user: users[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetails(
              currentUser: widget.currentUser,
              selectedUser: users[i],
              myAccount: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onTap});
  final UserData user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final role = primaryRole(user.roles);
    final status = DeviceStatus.fromMap(user.deviceStatus);
    final hasImage = user.imageUrl?.startsWith('http') == true;
    final site = user.assignedProject is Map
        ? (user.assignedProject as Map)['name']
        : null;

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.gold.withValues(alpha: 0.2),
          foregroundImage: hasImage ? NetworkImage(user.imageUrl!) : null,
          child: Text(
            '${user.firstName?.characters.firstOrNull ?? ''}${user.lastName?.characters.firstOrNull ?? ''}',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.goldDeep),
          ),
        ),
        title: Text('${user.firstName ?? ''} ${user.lastName ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          [role.localized(context.l10n), if (site != null) '$site'].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: user.isActive != true
            ? const StatusPill('Review', tone: Tone.warn)
            : !status.hasData
                ? const Icon(Icons.chevron_right, color: AppColors.muted)
                : Icon(Icons.circle,
                    size: 12,
                    color: status.problems.isEmpty
                        ? AppColors.ok
                        : AppColors.bad),
      ),
    );
  }
}
