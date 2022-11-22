import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/account_settings/users_list.dart';
import 'package:royal_marble/services/database.dart';

import '../models/user_model.dart';

class UserGrid extends StatefulWidget {
  const UserGrid({Key key, this.currentUser}) : super(key: key);
  final UserData currentUser;
  @override
  State<UserGrid> createState() => _UserGridState();
}

class _UserGridState extends State<UserGrid> {
  DatabaseService db = DatabaseService();
  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<UserData>>.value(
      value: db.getNonAdminUsers(),
      initialData: const [],
      child: const UserList(),
    );
  }
}
