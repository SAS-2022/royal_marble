import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/sales_pipeline/visit_forms.dart/visit_form_one.dart';
import 'package:royal_marble/services/database.dart';

class VisitFormStreams extends StatelessWidget {
  const VisitFormStreams({Key key, this.currentUser}) : super(key: key);
  final UserData currentUser;

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return MultiProvider(
      providers: [
        StreamProvider<List<ClientData>>.value(
          value: db.getClientsPerUser(userId: currentUser.uid),
          initialData: const [],
          catchError: (context, err) {
            //print('Error getting clients: $err');
            return [];
          },
        )
      ],
      child: VisitFormOne(),
    );
  }
}
