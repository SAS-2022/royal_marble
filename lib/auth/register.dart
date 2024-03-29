import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:royal_marble/location/http_navigation.dart';
import 'package:royal_marble/shared/snack_bar.dart';
import 'package:path/path.dart' as Path;
import '../location/google_map_navigation.dart';
import '../services/auth.dart';
import '../shared/constants.dart';
import '../shared/country_picker.dart';
import '../shared/loading.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final HttpNavigation _httpNavigation = HttpNavigation();
  bool loading = false;
  //text field state
  String firstName = '';
  String lastName = '';
  String company = '';
  String email = '';
  String confirmEmail = '';
  String phoneNumber = '';
  String password = '';
  Map<String, dynamic> nationality = {};
  String error = '';
  bool _isObsecure = true;
  Map<String, dynamic> myLocation = {};
  Size? size;
  final SnackBarWidget _snackBarWidget = SnackBarWidget();
  final ImagePicker _picker = ImagePicker();
  bool _imageRequested = false;
  XFile? pickedImage;

  ImageSource? _imageSource;
  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register User'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: loading ? const Center(child: Loading()) : _buildRegisterBody(),
      bottomNavigationBar: _imageRequested
          ? BottomAppBar(
              clipBehavior: Clip.hardEdge,
              elevation: 2,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.grey[600],
                    border: Border.all(color: Colors.grey[800]!),
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25))),
                height: size!.height / 10,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                            onPressed: () async {
                              _imageSource = ImageSource.gallery;
                              await _openImagePicker();
                            },
                            icon: const Icon(
                              Icons.photo_album,
                              size: 50,
                              color: Color.fromARGB(255, 191, 180, 66),
                            )),
                        IconButton(
                            onPressed: () async {
                              _imageSource = ImageSource.camera;
                              await _openImagePicker();
                            },
                            icon: const Icon(
                              Icons.camera,
                              size: 50,
                              color: Color.fromARGB(255, 191, 180, 66),
                            ))
                      ]),
                ),
              ))
          : null,
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
              //user photo
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: GestureDetector(
                  onTap: () async => _selectImageSource(),
                  child: Container(
                    height: size!.height / 5,
                    width: size!.width / 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(),
                    ),
                    child: pickedImage == null
                        ? const Center(
                            child: Text(
                              'Add Photo',
                              style: textStyle3,
                            ),
                          )
                        : CircleAvatar(
                            backgroundImage: FileImage(
                            File(pickedImage!.path),
                            scale: 2,
                          )),
                  ),
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
                      textCapitalization: TextCapitalization.sentences,
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
                          val!.isEmpty ? 'First name cannot be empty' : null,
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
                      textCapitalization: TextCapitalization.sentences,
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
                          val!.isEmpty ? 'Last Name cannot be empty' : null,
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
                      child: CountryDropDownPicker(
                        selectCountry: selectCountry,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 15.0),
              //Home Address
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Home Address'),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
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
                                myLocation.isNotEmpty
                                    ? 'Change Address'
                                    : 'Add Address',
                                style: textStyle5,
                              ),
                            ),
                          ),
                        ),
                        myLocation.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  myLocation['addressName'],
                                  style: textStyle5,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
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
                      textCapitalization: TextCapitalization.sentences,
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
                          val!.isEmpty ? 'Company cannot be empty' : null,
                      onChanged: (val) {
                        setState(() {
                          company = val.toString();
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
                          if (val!.isEmpty) {
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
                        if (val!.isEmpty) {
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
                      obscureText: _isObsecure,
                      decoration: InputDecoration(
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
                        if (val!.isEmpty) {
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
                width: size!.width - 50,
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
                      if (_formKey.currentState!.validate() &&
                          pickedImage != null) {
                        if (myLocation.isEmpty) {
                          _snackBarWidget.content =
                              'Home address needs to be assigned';
                          _snackBarWidget.showSnack();
                          return;
                        }
                        setState(() {
                          loading = true;
                        });
                        String imageUrl =
                            await _uploadImage(file: pickedImage!);

                        await _auth.registerWithEmailandPassword(
                            email: email.trim(),
                            password: password.trim(),
                            firstName: firstName.trim(),
                            lastName: lastName.trim(),
                            company: company.trim(),
                            phoneNumber: phoneNumber,
                            nationality: nationality,
                            homeAddress: myLocation,
                            isActive: false,
                            imageUrl: imageUrl,
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

  Future<String> _uploadImage({XFile? file}) async {
    FirebaseStorage storageReference;
    String folderName = 'profile_images';

    try {
      storageReference = FirebaseStorage.instance;
      var ref = storageReference
          .ref()
          .child('$folderName/${Path.basename(file!.path)}');
      var uploadTask = ref.putFile(File(file.path));
      var downloadUrl = await (await uploadTask).ref.getDownloadURL();
      return downloadUrl;
    } catch (e, stackTrace) {
      _snackBarWidget.content = 'Image Error: $e';
      _snackBarWidget.showSnack();
      return e.toString();
    }
  }

  void _selectImageSource() {
    setState(() {
      _imageRequested = !_imageRequested;
    });
  }

  Future _openImagePicker() async {
    try {
      if (_imageRequested) {
        pickedImage = await _picker.pickImage(
            preferredCameraDevice: CameraDevice.front,
            source: _imageSource!,
            maxHeight: size!.height - 10,
            maxWidth: size!.width - 10,
            imageQuality: 100);
      }
      _imageRequested = false;
      setState(() {});
      return pickedImage;
    } catch (e) {
      _snackBarWidget.content = 'Image could not be picked: $e';
      _snackBarWidget.showSnack();
    }
  }

  Future selecteMapLocation(
      {String? locationName, LatLng? locationAddress}) async {
    if (locationAddress != null && locationName != null) {
      myLocation = {
        'addressName': locationName,
        'Lat': locationAddress.latitude,
        'Lng': locationAddress.longitude,
      };
      setState(() {});
    }
    return myLocation;
  }

  selectCountry(Map<String, dynamic> country) {
    nationality = country;
  }
}
