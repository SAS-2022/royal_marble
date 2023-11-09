import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/mockups/mockup_list.dart';
import 'package:royal_marble/models/business_model.dart';

import '../models/user_model.dart';
import '../services/database.dart';

class MockupGrid extends StatelessWidget {
  const MockupGrid({Key? key, this.currentUser, this.selectedMockup})
      : super(key: key);
  final UserData? currentUser;
  final MockupData? selectedMockup;

  @override
  Widget build(BuildContext context) {
    var db = DatabaseService();
    return MultiProvider(
      providers: [
        selectedMockup == null
            ? StreamProvider<List<MockupData>>.value(
                value: db.getAllMockups(),
                initialData: const [],
                catchError: (context, err) {
                  return [MockupData(error: err.toString())];
                },
              )
            : StreamProvider<MockupData>.value(
                value: db.getMockupById(mockupId: selectedMockup!.uid),
                initialData: MockupData(),
                catchError: (context, err) {
                  return MockupData(error: err.toString());
                },
              ),
        StreamProvider<List<UserData>>.value(
          value: db.getAllWorkers(),
          initialData: [],
          catchError: (context, error) {
            return [UserData(error: error.toString())];
          },
        )
      ],
      child: MockupList(
        currentUser: currentUser!,
        singleMockup: selectedMockup == null ? false : true,
      ),
    );
  }
}
