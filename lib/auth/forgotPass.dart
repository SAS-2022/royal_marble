import 'package:flutter/material.dart';

class ForgotPassScreen extends StatelessWidget {
  const ForgotPassScreen({Key key, this.emailAddress}) : super(key: key);
  final String emailAddress;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: const Color.fromARGB(255, 169, 157, 16),
      ),
      body: _buildForgotPassBody(),
    );
  }

  Widget _buildForgotPassBody() {
    return SingleChildScrollView();
  }
}
