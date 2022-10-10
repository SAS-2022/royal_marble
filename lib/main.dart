import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/services/auth.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/loading.dart';
import 'package:royal_marble/wrapper.dart';

import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<UserData>.value(
            value: AuthService().user,
            initialData: UserData(),
            catchError: (context, err) => UserData(error: err.toString())),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        routes: <String, WidgetBuilder>{'/home': (context) => const Wrapper()},
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  //Device info generator
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  String identifier;
  Size _size;

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
    _getLocationAccess();
    Timer(
      const Duration(seconds: 5),
      () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Wrapper()),
          ModalRoute.withName('/home')),
    );
  }

  //Check if location is enabled
  Future<void> _getLocationAccess() async {
    if (await Permission.location.serviceStatus.isEnabled) {
      await Geolocator.requestPermission();
    } else {
      var status = await Permission.location.status;
      if (status.isGranted) {
      } else {
        var status = await [Permission.location].request();
      }
    }
  }

  //Get device info
  Future _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        var build = await deviceInfoPlugin.androidInfo;
        identifier = build.id.toString();
      } else if (Platform.isIOS) {
        var data = await deviceInfoPlugin.iosInfo;
        identifier = data.identifierForVendor;
      }
    } on PlatformException {
      print('Failed to get platform version');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 105, 96, 15),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: _size.height / 4,
                      width: 2 * _size.width / 3,
                      child: Image.asset('assets/images/logo_2.jpg'),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(
                        top: 35.0,
                      ),
                      child: Center(
                          child: Text(
                        'Please wait...',
                        style: textStyle2,
                      )),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(
                        top: 35.0,
                      ),
                      child: Center(child: Loading()),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
