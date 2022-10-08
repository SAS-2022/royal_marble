import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';

import '../models/business_model.dart';
import 'clients_list.dart';

class ClientGrid extends StatefulWidget {
  const ClientGrid({Key key, this.currentUser}) : super(key: key);
  final UserData currentUser;

  @override
  State<ClientGrid> createState() => _ClientGridState();
}

class _ClientGridState extends State<ClientGrid> {
  final db = DatabaseService();
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        widget.currentUser.roles.contains('isAdmin')
            ? StreamProvider<List<ClientData>>.value(
                value: db.getAllClients(), initialData: const [])
            : StreamProvider<List<ClientData>>.value(
                value: db.getClientsPerUser(), initialData: const []),
      ],
      child: ClientList(),
    );
  }
}
