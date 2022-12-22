import 'package:flutter/material.dart';

class SnackBarWidget {
  BuildContext context;
  String content;
  void showSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          content,
          style: const TextStyle(color: Colors.yellowAccent),
        ),
        duration: const Duration(seconds: 4),
        elevation: 15,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 50, left: 5, right: 5),
        backgroundColor: Colors.black,
        shape: const StadiumBorder(),
      ),
    );
  }
}
