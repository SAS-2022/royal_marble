import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/reports/report_type_list.dart';
import 'package:royal_marble/services/database.dart';
import '../models/user_model.dart';

class ReportGrid extends StatelessWidget {
  const ReportGrid({Key key, this.reportType, this.currentUser})
      : super(key: key);
  final String reportType;
  final UserData currentUser;

  @override
  Widget build(BuildContext context) {
    DatabaseService db = DatabaseService();
    return MultiProvider(
        providers: [
          //stream provider for site workers
          reportType == 'site'
              ? StreamProvider<List<UserData>>.value(
                  value: db.getAllWorkers(),
                  initialData: [],
                  catchError: (context, error) => [],
                )
              :

              //stream provider for sales team
              StreamProvider<List<UserData>>.value(
                  value: db.getSalesUsers(),
                  initialData: [],
                  catchError: (context, error) => [],
                )
        ],
        child: ReportTypeList(
          reportType: reportType,
          currentUser: currentUser,
        ));
  }
}
