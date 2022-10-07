import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/auth/sign_in.dart';
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

  @override
  void initState() {
    super.initState();
    _checkIfUserVerified();
  }

  @override
  Widget build(BuildContext context) {
    var userData = Provider.of<UserData>(context);
    if (userData == null) {
      return const SignInScreen();
    } else {
      return StreamProvider<UserData>.value(
        value: db.getUserPerId(uid: userData.uid),
        initialData: UserData(),
        catchError: (context, err) {
          print('the error: $err');
          return UserData(error: err);
        },
        child: const HomeScreen(),
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
