import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/services/database.dart';

import 'home.dart';

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
    return const HomeScreen();
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
