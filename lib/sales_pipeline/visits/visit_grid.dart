import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/sales_pipeline/visits/visit_list.dart';
import 'package:royal_marble/services/database.dart';

class VisitsGrid extends StatelessWidget {
  const VisitsGrid({Key key, this.currentUser}) : super(key: key);
  final UserData currentUser;

  @override
  Widget build(BuildContext context) {
    DatabaseService db = DatabaseService();

    return MultiProvider(
      providers: [
        StreamProvider<List<VisitDetails>>.value(
          value: db.getSalesVisitDetailsStream(),
          initialData: [],
          catchError: (context, error) {
            return [];
          },
        )
      ],
      child: VisitList(
        currentUser: currentUser,
      ),
    );
  }
}
