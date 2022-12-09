import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:royal_marble/location/http_navigation.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/snack_bar.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../location/google_map_navigation.dart';
import '../models/business_model.dart';

class ClientForm extends StatefulWidget {
  const ClientForm({Key key, this.client, this.currentUser, this.isNewClient})
      : super(key: key);
  final ClientData client;
  final UserData currentUser;
  final bool isNewClient;

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  HttpNavigation _httpNavigation = HttpNavigation();
  final db = DatabaseService();
  final _snackBarWidget = SnackBarWidget();
  ClientData newClient = ClientData();
  bool _editContent = false;
  Map<String, dynamic> _myLocation = {};
  PhoneNumber phoneNumber = PhoneNumber(isoCode: 'AE');
  TextEditingController _phoneController = TextEditingController();
  Size _size;

  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;
    newClient.userId = widget.currentUser.uid;
    if (widget.client != null) {
      newClient = widget.client;

      if (widget.client.phoneNumber != null) {
        print('the phoneNumber: ${widget.client.phoneNumber}');
        phoneNumber = PhoneNumber(
          phoneNumber: widget.client.phoneNumber.phoneNumber,
          dialCode: widget.client.phoneNumber.dialCode,
          isoCode: widget.client.phoneNumber.isoCode,
        );
      }

      if (widget.client.clientAddress != null) {
        _myLocation = {
          'addressName': newClient.clientAddress['addressName'],
          'Lat': newClient.clientAddress['Lat'],
          'Lng': newClient.clientAddress['Lng'],
        };
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _phoneController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Form'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
        actions: [
          !widget.isNewClient
              ? TextButton(
                  onPressed: () {
                    setState(() {
                      _editContent = !_editContent;
                    });
                  },
                  child: const Text(
                    'Edit',
                    style: buttonStyle,
                  ))
              : const SizedBox.shrink()
        ],
      ),
      body: widget.isNewClient
          ? _buildNewClientForm()
          : _buildSelectedClientDetails(),
    );
  }

  //This form will allow to add a new client
  Widget _buildNewClientForm() {
    return Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'The following form will allow you to add a new client, all required field should be filled before you can proceed',
                  style: textStyle6,
                ),
                const SizedBox(
                  height: 15,
                ),
                TextFormField(
                  autofocus: false,
                  initialValue: '',
                  style: textStyle5,
                  decoration: InputDecoration(
                    filled: true,
                    label: const Text('Client Name'),
                    hintText: 'Ex: The Granite Co.',
                    fillColor: Colors.grey[100],
                    enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        borderSide: BorderSide(color: Colors.green)),
                  ),
                  validator: (val) =>
                      val.isEmpty ? 'Client name cannot be empty' : null,
                  onChanged: (val) {
                    setState(() {
                      newClient.clientName = val.trim();
                    });
                  },
                ),
                const SizedBox(
                  height: 15,
                ),
                TextFormField(
                  autofocus: false,
                  initialValue: '',
                  style: textStyle5,
                  decoration: InputDecoration(
                    filled: true,
                    label: const Text('Contact Person'),
                    hintText: 'Ex: John Martin',
                    fillColor: Colors.grey[100],
                    enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        borderSide: BorderSide(color: Colors.green)),
                  ),
                  validator: (val) =>
                      val.isEmpty ? 'Contact person cannot be empty' : null,
                  onChanged: (val) {
                    setState(() {
                      newClient.contactPerson = val.trim();
                    });
                  },
                ),
                const SizedBox(
                  height: 15,
                ),
                InternationalPhoneNumberInput(
                  onInputChanged: (PhoneNumber number) {
                    print('${number.phoneNumber} - ${number.isoCode}');
                  },
                  onInputValidated: (bool value) {
                    print(value);
                  },
                  selectorConfig: const SelectorConfig(
                    selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                  ),
                  ignoreBlank: false,
                  autoValidateMode: AutovalidateMode.disabled,
                  selectorTextStyle: const TextStyle(color: Colors.black),
                  initialValue: phoneNumber,
                  textFieldController: _phoneController,
                  formatInput: false,
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  inputBorder: const OutlineInputBorder(),
                  onSaved: (PhoneNumber number) {
                    print('the number: $number');
                    newClient.phoneNumber = number;
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    _formKey.currentState?.save();
                    if (_formKey.currentState.validate()) {}
                  },
                  child: Text('Save'),
                ),
                // TextFormField(
                //   autofocus: false,
                //   initialValue: '',
                //   style: textStyle5,
                //   keyboardType: TextInputType.number,
                //   inputFormatters: <TextInputFormatter>[
                //     FilteringTextInputFormatter.digitsOnly,
                //   ],
                //   decoration: InputDecoration(
                //     filled: true,
                //     label: const Text('Client Phone'),
                //     hintText: 'Ex: 05 123 12345',
                //     fillColor: Colors.grey[100],
                //     enabledBorder: const OutlineInputBorder(
                //         borderRadius: BorderRadius.all(Radius.circular(15.0)),
                //         borderSide: BorderSide(color: Colors.grey)),
                //     focusedBorder: const OutlineInputBorder(
                //         borderRadius: BorderRadius.all(Radius.circular(15.0)),
                //         borderSide: BorderSide(color: Colors.green)),
                //   ),
                //   validator: (val) {
                //     Pattern pattern = r'^(?:[05]8)?[0-9]{10}$';
                //     var regexp = RegExp(pattern.toString());
                //     if (val.isEmpty) {
                //       return 'Phone cannot be empty';
                //     }
                //     if (!regexp.hasMatch(val)) {
                //       return 'Phone number does not match a UAE number';
                //     } else {
                //       return null;
                //     }
                //   },
                //   onChanged: (val) {
                //     setState(() {
                //       newClient.phoneNumber = val.trim();
                //     });
                //   },
                // ),
                const SizedBox(
                  height: 15,
                ),
                TextFormField(
                  autofocus: false,
                  initialValue: '',
                  style: textStyle5,
                  decoration: InputDecoration(
                    filled: true,
                    label: const Text('Email Address'),
                    hintText: 'example@email.com',
                    fillColor: Colors.grey[100],
                    enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        borderSide: BorderSide(color: Colors.green)),
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
                      newClient.emailAddress = val.trim();
                    });
                  },
                ),
                const SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GoogleMapNavigation(
                                  getLocation: selecteMapLocation,
                                  navigate: false,
                                )));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(15)),
                    height: 50,
                    child: Center(
                      child: Text(
                        _myLocation.isNotEmpty
                            ? 'Change Address'
                            : 'Add Address',
                        style: textStyle5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                _myLocation.isNotEmpty
                    ? SizedBox(
                        height: 40,
                        child: Center(
                            child: Text('${_myLocation['addressName']}')),
                      )
                    : const SizedBox.shrink(),
                const SizedBox(
                  height: 15,
                ),
                //Submit button will allow you add the entered data into the database
                Center(
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 191, 180, 66),
                          fixedSize: Size(_size.width / 2, 45),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25))),
                      onPressed: () async {
                        if (_formKey.currentState.validate()) {
                          _formKey.currentState.save();
                          var result =
                              await db.addNewClients(client: newClient);
                          if (result == 'Completed') {
                            Navigator.pop(context);
                          } else {
                            _snackBarWidget.content =
                                'failed to update account, please contact developer';
                            _snackBarWidget.showSnack();
                          }
                        }
                      },
                      child: const Text(
                        'Submit',
                        style: textStyle2,
                      )),
                ),
              ],
            ),
          ),
        ));
  }

  //This form will allow to view and update a current client
  Widget _buildSelectedClientDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'The following form will allow you to update a current client, all required field should be filled before you can proceed',
                style: textStyle6,
              ),
              const SizedBox(
                height: 15,
              ),
              _editContent
                  ? TextFormField(
                      autofocus: false,
                      initialValue: newClient.clientName,
                      style: textStyle5,
                      decoration: InputDecoration(
                        filled: true,
                        label: const Text('Client Name'),
                        hintText: 'Ex: The Granite Co.',
                        fillColor: Colors.grey[100],
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.green)),
                      ),
                      validator: (val) =>
                          val.isEmpty ? 'Client name cannot be empty' : null,
                      onChanged: (val) {
                        setState(() {
                          newClient.clientName = val.trim();
                        });
                      },
                    )
                  : Row(children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Client Name',
                          style: textStyle5,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          widget.client.clientName,
                          style: textStyle3,
                        ),
                      )
                    ]),
              const SizedBox(
                height: 15,
              ),
              _editContent
                  ? TextFormField(
                      autofocus: false,
                      initialValue: newClient.contactPerson,
                      style: textStyle5,
                      decoration: InputDecoration(
                        filled: true,
                        label: const Text('Contact Person'),
                        hintText: 'Ex: John Martin',
                        fillColor: Colors.grey[100],
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.green)),
                      ),
                      validator: (val) =>
                          val.isEmpty ? 'Contact person cannot be empty' : null,
                      onChanged: (val) {
                        setState(() {
                          newClient.contactPerson = val.trim();
                        });
                      },
                    )
                  : Row(children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Contact Name',
                          style: textStyle5,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          widget.client.contactPerson,
                          style: textStyle3,
                        ),
                      )
                    ]),
              const SizedBox(
                height: 15,
              ),
              _editContent
                  ? InternationalPhoneNumberInput(
                      onInputChanged: (PhoneNumber number) {
                        print('${number.phoneNumber} - ${number.isoCode}');
                      },
                      onInputValidated: (bool value) {
                        print(value);
                      },
                      selectorConfig: const SelectorConfig(
                        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                      ),
                      ignoreBlank: false,
                      autoValidateMode: AutovalidateMode.disabled,
                      selectorTextStyle: const TextStyle(color: Colors.black),
                      initialValue: phoneNumber,
                      textFieldController: _phoneController,
                      formatInput: false,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      inputBorder: const OutlineInputBorder(),
                      onSaved: (PhoneNumber number) {
                        newClient.phoneNumber = number;
                      },
                    )
                  : Row(children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Phone Number',
                          style: textStyle5,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          phoneNumber != null ? phoneNumber.phoneNumber : '',
                          style: textStyle3,
                        ),
                      )
                    ]),
              const SizedBox(
                height: 15,
              ),
              _editContent
                  ? TextFormField(
                      autofocus: false,
                      initialValue: newClient.emailAddress,
                      style: textStyle5,
                      decoration: InputDecoration(
                        filled: true,
                        label: const Text('Email Address'),
                        hintText: 'example@email.com',
                        fillColor: Colors.grey[100],
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.green)),
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
                          newClient.emailAddress = val.trim();
                        });
                      },
                    )
                  : Row(children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Client Email',
                          style: textStyle5,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          widget.client.emailAddress,
                          style: textStyle3,
                        ),
                      )
                    ]),
              const SizedBox(
                height: 15,
              ),
              _editContent
                  ? GestureDetector(
                      onTap: () async {
                        if (Platform.isIOS) {
                          _httpNavigation.context = context;
                          _httpNavigation.lat = _myLocation['Lat'];
                          _httpNavigation.lng = _myLocation['Lng'];
                          await _httpNavigation.startNaviagtionGoogleMap();
                        } else {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => GoogleMapNavigation(
                                        getLocation: selecteMapLocation,
                                        navigate: false,
                                      )));
                        }
                      },
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(15)),
                            height: 50,
                            child: Center(
                              child: Text(
                                _myLocation.isNotEmpty
                                    ? 'Change Address'
                                    : 'Add Address',
                                style: textStyle5,
                              ),
                            ),
                          ),
                          _myLocation.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: SizedBox(
                                    height: 40,
                                    child: Center(
                                        child: Text(
                                            '${_myLocation['addressName']}')),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                    )
                  : Row(children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Location',
                          style: textStyle5,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () async {
                            if (Platform.isIOS) {
                              _httpNavigation.context = context;
                              _httpNavigation.lat = _myLocation['Lat'];
                              _httpNavigation.lng = _myLocation['Lng'];
                              await _httpNavigation.startNaviagtionGoogleMap();
                            } else {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => GoogleMapNavigation(
                                            getLocation: selecteMapLocation,
                                            lat: _myLocation['Lat'],
                                            lng: _myLocation['Lng'],
                                            navigate: true,
                                          )));
                            }
                          },
                          child: Text(
                            _myLocation['addressName'].toString(),
                            style: textStyle3,
                          ),
                        ),
                      )
                    ]),
              const SizedBox(
                height: 15,
              ),
              //Submit button will allow you add the entered data into the database
              _editContent
                  ? Center(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 191, 180, 66),
                              fixedSize: Size(_size.width / 2, 45),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25))),
                          onPressed: () async {
                            if (_formKey.currentState.validate()) {
                              _formKey.currentState.save();
                              var result =
                                  await db.updateClientData(client: newClient);
                              if (result == 'Completed') {
                                Navigator.pop(context);
                              } else {
                                _snackBarWidget.content =
                                    'failed to update account, please contact developer';
                                _snackBarWidget.showSnack();
                              }
                            }
                          },
                          child: const Text(
                            'Submit',
                            style: textStyle2,
                          )),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(
                height: 15,
              ),
              //Delete button will allow you to delete the current client
              _editContent && widget.currentUser.roles.contains('isAdmin')
                  ? Center(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            fixedSize: Size(_size.width / 2, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () async {
                            await showDialog(
                                context: context,
                                builder: (_) {
                                  return AlertDialog(
                                    backgroundColor: Colors.red[100],
                                    title: const Text(
                                      'Delete',
                                      textAlign: TextAlign.center,
                                    ),
                                    content: const Text(
                                      'Are you sure you want to delete this client, this action cannot be undone!',
                                      textAlign: TextAlign.center,
                                    ),
                                    actions: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text(
                                              'No',
                                              style: textStyle3,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () async =>
                                                await db.deleteClient(
                                                    clientId:
                                                        widget.client.uid),
                                            child: const Text(
                                              'Yes',
                                              style: textStyle3,
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  );
                                });
                          },
                          child: const Text(
                            'Delete',
                            style: textStyle2,
                          )),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Future selecteMapLocation(
      {String locationName, LatLng locationAddress}) async {
    if (locationAddress != null && locationName != null) {
      _myLocation = {
        'addressName': locationName,
        'Lat': locationAddress.latitude,
        'Lng': locationAddress.longitude,
      };
      newClient.clientAddress = _myLocation;
    } else {
      _myLocation = {'Lat': '', 'Lng': ''};
    }
    setState(() {});
  }
}
