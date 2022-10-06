import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/services/auth.dart';
import 'package:royal_marble/shared/snack_bar.dart';

import '../shared/constants.dart';

class ForgotPassScreen extends StatefulWidget {
  const ForgotPassScreen({Key key, this.emailAddress}) : super(key: key);
  final String emailAddress;

  @override
  State<ForgotPassScreen> createState() => _ForgotPassScreenState();
}

class _ForgotPassScreenState extends State<ForgotPassScreen> {
  final _formKey = GlobalKey<FormState>();
  AuthService _auth = AuthService();
  bool _isLoading = false;
  String emailAddress;
  SnackBarWidget _snackBar = SnackBarWidget();
  @override
  Widget build(BuildContext context) {
    _snackBar.context = context;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: const Color.fromARGB(255, 169, 157, 16),
      ),
      body: _buildForgotPassBody(),
    );
  }

  Widget _buildForgotPassBody() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              'Enter you email in the empty field and select reset password, you should receive an email that will allow you to do so.',
              style: textStyle6,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 25.0, horizontal: 25.0),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: 'example@royalMarble.ae',
                labelText: 'Email Address',
                filled: true,
                fillColor: Colors.grey[100],
                enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    borderSide: BorderSide(color: Colors.blue)),
              ),
              validator: (val) {
                if (val.isEmpty) {
                  return 'Email Address is required';
                }
                if (!EmailValidator.validate(val)) {
                  return 'This is a non-valid email';
                }
                return null;
              },
              onChanged: (val) {
                setState(() {
                  emailAddress = val.trim();
                });
              },
            ),
          ),
          const SizedBox(
            height: 15.0,
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Colors.redAccent,
              shadowColor: Colors.brown[500],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
            child: const Text(
              'Reset Password',
              style: buttonStyle,
            ),
            onPressed: () async {
              if (_formKey.currentState.validate()) {
                setState(() {
                  _isLoading = true;
                });
                dynamic result = await _auth.resetPassword(emailAddress);
                if (result == null) {
                  _snackBar.content = 'Failed to send reset email';
                  _snackBar.showSnack();
                }
                setState(() {
                  _isLoading = false;
                });
                Navigator.pop(context);
              }
            },
          )
        ]),
      ),
    );
  }
}
