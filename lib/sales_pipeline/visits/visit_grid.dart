import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/sales_pipeline/visits/visit_list.dart';
import 'package:royal_marble/services/database.dart';

class VisitsGrid extends StatelessWidget {
  const VisitsGrid(
      {Key key,
      this.currentUser,
      this.fromDate,
      this.toDate,
      this.selectedUser})
      : super(key: key);
  final UserData currentUser;
  final UserData selectedUser;
  final DateTime fromDate;
  final DateTime toDate;

  @override
  Widget build(BuildContext context) {
    DatabaseService db = DatabaseService();
    return MultiProvider(
      providers: [
        StreamProvider<List<VisitDetails>>.value(
          value: db.getSalesVisitDetailsStream(
              userId: selectedUser.uid, fromDate: fromDate, toDate: toDate),
          initialData: const [],
          catchError: (context, error) {
            return [];
          },
        )
      ],
      child: VisitList(
        currentUser: currentUser,
        selectedUser: selectedUser,
      ),
    );
  }
}
