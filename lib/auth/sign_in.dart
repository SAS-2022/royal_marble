import 'package:flutter/material.dart';
import 'package:royal_marble/auth/forgot_pass.dart';
import 'package:royal_marble/auth/register.dart';
import 'package:royal_marble/services/auth.dart';
import 'package:royal_marble/shared/loading.dart';

import '../shared/constants.dart';
import '../wrapper.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInState();
}

class _SignInState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();
  String emailAddress;
  String password;
  bool _isObsecure = true;
  bool showEmailVerification = false;
  dynamic result;
  String error;
  bool _isLoading = false;
  Size size;
  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _buildSignInBody(),
    );
  }

  Widget _buildSignInBody() {
    return _isLoading
        ? const Loading()
        : SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 35, horizontal: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //We will add the logo on top
                    Image.asset(
                      'assets/images/logo_2.jpg',
                      height: size.height / 3,
                    ),
                    const SizedBox(
                      height: 25.0,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'example@royalMarble.com',
                        labelText: 'Email Address',
                        filled: true,
                        fillColor: Colors.grey[100],
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.blue)),
                      ),
                      validator: (val) =>
                          val.isEmpty ? 'Email Address cannot be empty' : null,
                      onChanged: (val) {
                        setState(() {
                          emailAddress = val.trim().toString();
                        });
                      },
                    ),

                    const SizedBox(
                      height: 15.0,
                    ),
                    //Password
                    TextFormField(
                      obscureText: _isObsecure,
                      decoration: textInputDecoration.copyWith(
                        suffixIcon: IconButton(
                          onPressed: () async {
                            setState(() {
                              _isObsecure = !_isObsecure;
                            });
                          },
                          icon: Icon(!_isObsecure
                              ? Icons.visibility
                              : Icons.visibility_off),
                        ),
                        labelText: 'Password',
                        filled: true,
                        fillColor: Colors.grey[100],
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.blue)),
                      ),
                      validator: (val) =>
                          val.isEmpty ? 'Password cannot be left empty' : null,
                      onChanged: (val) {
                        setState(() {
                          password = val;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),

                    error != null && error.isNotEmpty
                        ? Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          )
                        : const SizedBox(
                            height: 1.0,
                          ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    showEmailVerification
                        ? GestureDetector(
                            child:
                                const Text('Verify Account', style: textStyle7),
                            onTap: () => emailAddress.isNotEmpty
                                ? _verifyAccount(emailAddress)
                                : error = 'Email is Empty')
                        : const SizedBox.shrink(),
                    const SizedBox(
                      height: 15.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            child: const Text('Forgot Password,',
                                style: textStyle7),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPassScreen(
                                  emailAddress: emailAddress,
                                ),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: const Text('New User', style: textStyle8),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    //A sign in button to sign in new users
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) {
                                return const Color.fromARGB(255, 103, 48, 11);
                              }
                              return const Color.fromARGB(255, 37, 36, 25);
                            },
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: buttonStyle,
                        ),
                        onPressed: () async {
                          if (_formKey.currentState.validate()) {
                            setState(() {
                              _isLoading = true;
                            });

                            result = 'not null';

                            result = await _auth.signInWithUserNameandPassword(
                                emailAddress, password);

                            if (result != null) {
                              await Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Wrapper(),
                                ),
                                ModalRoute.withName('/home'),
                              );
                            } else {
                              setState(() {
                                _isLoading = false;

                                error = 'Wrong user name or password';
                              });
                            }
                          } //end form validation
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  _verifyAccount(String emailAddress) {
    _auth.userFromFirebaseVerification(emailAddress);
  }
}
