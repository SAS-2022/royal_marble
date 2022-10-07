import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth.dart';
import '../shared/constants.dart';
import '../shared/country_picker.dart';
import '../shared/loading.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  //text field state
  String firstName = '';
  String lastName = '';
  String company = '';
  String email = '';
  String confirmEmail = '';
  String phoneNumber = '';
  String password = '';
  String nationality = '';
  String error = '';
  Size size;

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register User'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: loading ? const Center(child: Loading()) : _buildRegisterBody(),
    );
  }

  Widget _buildRegisterBody() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          child: Column(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(
                  'The following form allows you to register a user along Royal Marble app, please enter all the required information',
                  style: textStyle6,
                ),
              ),
              //First Name
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('First Name'),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      decoration: InputDecoration(
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
                          val.isEmpty ? 'First name cannot be empty' : null,
                      onChanged: (val) {
                        setState(() {
                          firstName = val.trim();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15.0),
              //Last Name
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Last Name'),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      decoration: InputDecoration(
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
                          val.isEmpty ? 'Last Name cannot be empty' : null,
                      onChanged: (val) {
                        setState(() {
                          lastName = val.trim();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15.0),
              //Nationality
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Nationality'),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: CountryDropDownPicker()),
                  )
                ],
              ),
              const Divider(
                height: 40,
                thickness: 3,
              ),
              //Company
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Company'),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      decoration: InputDecoration(
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
                      onChanged: (val) {
                        setState(() {
                          company = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15.0),
              //Mobile Number
              Row(
                children: [
                  const Expanded(flex: 1, child: Text('Phone Number')),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
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
                        validator: (val) {
                          Pattern pattern = r'^(?:[05]8)?[0-9]{10}$';
                          var regexp = RegExp(pattern.toString());
                          if (val.isEmpty) {
                            return 'Phone cannot be empty';
                          }
                          if (!regexp.hasMatch(val)) {
                            return 'Phone number does not match a UAE number';
                          } else {
                            return null;
                          }
                        },
                        onChanged: (val) {
                          setState(() {
                            phoneNumber = val;
                          });
                        }),
                  ),
                ],
              ),
              const SizedBox(height: 15.0),
              const Divider(
                height: 40,
                thickness: 3,
              ),
              //Email Address
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Email Address'),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      decoration: InputDecoration(
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
                      validator: (val) {
                        if (val.isEmpty) {
                          return 'Email Address cannot be empty';
                        }
                        if (!EmailValidator.validate(val)) {
                          return 'This is not a valid email address';
                        } else {
                          return null;
                        }
                      },
                      onChanged: (val) {
                        setState(() {
                          email = val.trim();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 15.0,
              ),
              //Confirm email address
              Row(
                children: [
                  const Expanded(flex: 1, child: Text('Confirm Email')),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      decoration: InputDecoration(
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
                          val != email ? 'Confirming email failed' : null,
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 15.0,
              ),
              //Password
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Password'),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
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
                      validator: (val) {
                        if (val.isEmpty) {
                          return 'Password cannot be empty';
                        }
                        if (val.length < 6) {
                          return 'Password should be more than 6 characters';
                        } else {
                          return null;
                        }
                      },
                      onChanged: (val) {
                        setState(() {
                          password = val.trim();
                        });
                      },
                    ),
                  ),
                ],
              ),
              //Error message container
              Text(error, style: const TextStyle(color: Colors.red)),
              const SizedBox(
                height: 25.0,
              ),
              //Submit button
              SizedBox(
                width: size.width - 50,
                child: ElevatedButton(
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed)) {
                            return const Color.fromARGB(255, 103, 48, 11);
                          }
                          return const Color.fromARGB(255, 37, 36, 25);
                        },
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: buttonStyle,
                    ),
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        setState(() {
                          loading = true;
                        });

                        await _auth.registerWithEmailandPassword(
                            email: email.trim(),
                            password: password.trim(),
                            firstName: firstName.trim(),
                            lastName: lastName.trim(),
                            company: company.trim(),
                            phoneNumber: phoneNumber,
                            nationality: nationality,
                            isActive: false,
                            roles: ['isNormalUser']);

                        setState(() {
                          loading = false;
                        });
                        await Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (route) => false);
                      }
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
