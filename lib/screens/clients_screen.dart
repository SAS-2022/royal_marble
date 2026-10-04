import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/maps.dart';
import '../core/locale_controller.dart';
import '../core/roles.dart';
import '../models/business_model.dart';
import '../models/sales_visit.dart';
import '../models/user_model.dart';
import '../services/database.dart';
import '../shared/loading.dart';
import '../widgets/status_widgets.dart';
import 'client_form_screen.dart';
import 'visit_form_screen.dart';
import 'visits_screen.dart' show VisitTile;

/// A salesperson's clients (admins see everyone's, with the owner's name),
/// with search and a button to add one.
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key, required this.currentUser});
  final UserData currentUser;

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  late final bool _admin = primaryRole(widget.currentUser.roles) == AppRole.admin;
  late final _db = DatabaseService();
  late final _clients =
      _db.streamClients(ownerId: _admin ? null : widget.currentUser.uid);
  late final Stream<List<UserData>>? _users = _admin ? _db.getAllUsers() : null;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.clients)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ClientFormScreen(ownerId: widget.currentUser.uid!))),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l.addClient),
      ),
      body: StreamBuilder<List<UserData>>(
        stream: _users,
        builder: (context, u) => StreamBuilder<List<ClientData>>(
          stream: _clients,
          builder: (context, s) {
            if (s.hasError) {
              return Center(
                  child: Text(l.noClientsFound,
                      style: const TextStyle(color: AppColors.muted)));
            }
            if (!s.hasData) return const Loading();
            final owners = {
              for (final x in u.data ?? const <UserData>[])
                x.uid: '${x.firstName ?? ''} ${x.lastName ?? ''}'.trim()
            };
            final q = _query.toLowerCase();
            final shown = s.data!
                .where((c) =>
                    c.error == null &&
                    (q.isEmpty ||
                        c.name.toLowerCase().contains(q) ||
                        (c.contactPerson ?? '').toLowerCase().contains(q) ||
                        (c.phone ?? '').contains(q) ||
                        prettyAddress(c.clientAddress?['addressName'])
                            .toLowerCase()
                            .contains(q) ||
                        (owners[c.userId] ?? '').toLowerCase().contains(q)))
                .toList()
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: l.searchClients,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                const SizedBox(height: 8),
                Text(l.clientsCount(shown.length),
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 8),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                          s.data!.isEmpty ? l.noClientsYet : l.noClientsFound,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted)),
                    ),
                  ),
                for (final c in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ClientDetailsScreen(
                                    clientId: c.uid!,
                                    currentUser: widget.currentUser))),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.gold.withValues(alpha: 0.18),
                          child: Text(
                              c.name.characters.firstOrNull?.toUpperCase() ?? '?',
                              style: const TextStyle(
                                  color: AppColors.goldDeep,
                                  fontWeight: FontWeight.w700)),
                        ),
                        title: Text(c.name,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          [
                            c.contactPerson ?? '',
                            prettyAddress(c.clientAddress?['addressName']),
                          ].where((x) => x.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _admin && owners[c.userId] != null
                            ? StatusPill(owners[c.userId]!, icon: Icons.badge_outlined)
                            : null,
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

/// A client, live: contact actions, address with directions, a button to
/// record a visit, and the owner's visits to this client.
class ClientDetailsScreen extends StatefulWidget {
  const ClientDetailsScreen(
      {super.key, required this.clientId, required this.currentUser});
  final String clientId;
  final UserData currentUser;

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  final _db = DatabaseService();
  late final _client = _db.streamClient(widget.clientId);
  Stream<List<SalesVisit>>? _visits;
  String? _visitsOwner;

  Stream<List<SalesVisit>> _visitsOf(String owner) {
    if (_visits == null || _visitsOwner != owner) {
      _visitsOwner = owner;
      _visits =
          _db.streamVisits(owner, VisitKind.client, targetId: widget.clientId);
    }
    return _visits!;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final admin = primaryRole(widget.currentUser.roles) == AppRole.admin;
    return StreamBuilder<ClientData>(
      stream: _client,
      builder: (context, s) {
        final c = s.data;
        final canEdit =
            c != null && (admin || c.userId == widget.currentUser.uid);
        return Scaffold(
          appBar: AppBar(
            title: Text(c?.name ?? l.clients),
            actions: [
              if (canEdit && c.error == null)
                IconButton(
                  tooltip: l.editClient,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ClientFormScreen(
                              client: c, ownerId: widget.currentUser.uid!))),
                ),
            ],
          ),
          floatingActionButton: c != null && c.error == null
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => VisitFormScreen(
                              currentUser: widget.currentUser,
                              initialClient: c))),
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: Text(l.newVisit),
                )
              : null,
          body: c == null
              ? const Loading()
              : c.error != null
                  ? Center(
                      child: Text(l.clientNotFound,
                          style: const TextStyle(color: AppColors.muted)))
                  : _body(c),
        );
      },
    );
  }

  Widget _body(ClientData c) {
    final l = context.l10n;
    final address = prettyAddress(c.clientAddress?['addressName']);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Card(
          child: Column(children: [
            if (c.contactPerson?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(c.contactPerson!),
              ),
            if (c.phone != null)
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(c.phone!, textDirection: TextDirection.ltr),
                trailing: const Icon(Icons.call, color: AppColors.ok),
                onTap: () => launchUrl(Uri(scheme: 'tel', path: c.phone)),
              ),
            if (c.emailAddress?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(c.emailAddress!),
                onTap: () =>
                    launchUrl(Uri(scheme: 'mailto', path: c.emailAddress)),
              ),
            if (address.isNotEmpty || c.hasPin)
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(address.isEmpty ? l.pinOnly : address),
                trailing: c.hasPin
                    ? TextButton.icon(
                        onPressed: () => openDirections(
                            c.clientAddress!['Lat'], c.clientAddress!['Lng']),
                        icon: const Icon(Icons.directions),
                        label: Text(l.directions),
                      )
                    : null,
              ),
          ]),
        ),
        if (c.userId == null)
          const SizedBox.shrink()
        else
          StreamBuilder<List<SalesVisit>>(
            stream: _visitsOf(c.userId!),
            builder: (context, v) {
              final visits = v.data;
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SectionTitle(l.visitsCount(visits?.length ?? 0)),
                if (visits == null && !v.hasError) const Loading(),
                if (visits != null && visits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(l.noVisitsYet,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted)),
                  ),
                for (final x in visits ?? const <SalesVisit>[])
                  VisitTile(visit: x, viewer: widget.currentUser, showDate: true),
              ]);
            },
          ),
      ],
    );
  }
}
