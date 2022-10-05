import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/services/auth.dart';
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

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
    Timer(
      const Duration(seconds: 5),
      () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Wrapper()),
          ModalRoute.withName('/home')),
    );
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.purpleAccent[100],
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
                    Container(),
                    Container(),
                    const Padding(
                      padding: EdgeInsets.only(top: 10.0),
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
