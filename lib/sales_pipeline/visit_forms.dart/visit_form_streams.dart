import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/sales_pipeline/visits/sales_team_pipeline.dart';
import 'package:royal_marble/sales_pipeline/visit_forms.dart/visit_form_one.dart';
import 'package:royal_marble/services/database.dart';

class VisitFormStreams extends StatelessWidget {
  const VisitFormStreams({Key key, this.currentUser, this.viewingVisit})
      : super(key: key);
  final UserData currentUser;
  final bool viewingVisit;

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return MultiProvider(
      providers: [
        currentUser.roles.contains('isAdmin')
            ? StreamProvider<List<ClientData>>.value(
                value: db.getAllClients(),
                initialData: const [],
                catchError: (context, err) {
                  // print('Error getting client: $err');
                  return [];
                },
              )
            : StreamProvider<List<ClientData>>.value(
                value: db.getClientsPerUser(userId: currentUser.uid),
                initialData: const [],
                catchError: (context, err) {
                  print('Error getting client: $err');
                  return [];
                },
              ),
        //if visits are being viewed
        //create a stream to get current sales team
        viewingVisit
            ? StreamProvider<List<UserData>>.value(
                value: db.getSalesUsers(),
                initialData: const [],
                catchError: (context, err) {
                  return [];
                },
              )
            : StreamProvider<UserData>.value(
                value: db.getUserPerId(uid: currentUser.uid),
                initialData: UserData(),
                catchError: (context, err) {
                  return UserData();
                },
              )
      ],
      child: viewingVisit
          ? SalesTeamPipeline(
              currentUser: currentUser,
            )
          : VisitFormOne(
              currentUser: currentUser,
            ),
    );
  }
}
