import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/auth/sign_in.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/services/database.dart';

import 'home.dart';
import 'models/user_model.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({Key key}) : super(key: key);

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool _isUserVerified = false;
  DatabaseService db = DatabaseService();
  String message;
  String today;
  @override
  void initState() {
    super.initState();
    _checkIfUserVerified();
    today =
        '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}';
  }

  @override
  Widget build(BuildContext context) {
    var userData = Provider.of<UserData>(context);
    if (userData == null || userData.uid == null) {
      return const SignInScreen();
    } else {
      return MultiProvider(
        providers: [
          //a provider to show current user
          StreamProvider<UserData>.value(
            value: db.getUserPerId(uid: userData.uid),
            initialData: UserData(),
            catchError: (context, err) {
              return UserData();
            },
          ),
          //a provider to show all projects
          StreamProvider<List<ProjectData>>.value(
            value: db.getAllProjects(),
            initialData: [],
            catchError: (context, err) {
              return [];
            },
          ),
          //a provider to get mockups
          StreamProvider<List<MockupData>>.value(
            value: db.getAllMockups(),
            initialData: [],
            catchError: ((context, error) => [MockupData(error: error)]),
          ),
          //a provider to show all users
          StreamProvider<List<UserData>>.value(
              value: db.getAllUsers(),
              initialData: [],
              catchError: (context, err) => [UserData(error: err.toString())]),
          //a provider for the timesheet
          StreamProvider<Map<String, dynamic>>.value(
            value: db.getTimeSheetData(uid: today),
            initialData: null,
            catchError: (context, err) {
              return null;
            },
          )
        ],
        child: HomeScreen(
          currentUser: userData,
        ),
      );
    }
  }

  Future<void> _checkIfUserVerified() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.emailVerified) {
        setState(() {
          _isUserVerified = true;
        });
      }
    }
  }
}
