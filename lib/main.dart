import 'dart:async';
import 'dart:io';
import 'package:background_geolocation_firebase/background_geolocation_firebase.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/services/auth.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/calculate_distance.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/loading.dart';
import 'package:royal_marble/wrapper.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user_model.dart';
import 'package:background_fetch/background_fetch.dart';

void backgroundGeolocationHeadlessTask(bg.HeadlessEvent headlessEvent) async {
  final db = DatabaseService();
  print('[BackgroundGeolocation HeadlessTask]: $headlessEvent');
  // Implement a 'case' for only those events you're interested in.
  switch (headlessEvent.name) {
    case bg.Event.BOOT:
      bg.State state = await bg.BackgroundGeolocation.state;
      print("didDeviceReboot: ${state.didDeviceReboot}");
      break;
    case bg.Event.MOTIONCHANGE:
      bg.Location location = headlessEvent.event;
      await FirebaseFunctions.instance.httpsCallable('updateMotion').call();
      break;
    case bg.Event.LOCATION:
      bg.Location location = headlessEvent.event;
      SharedPreferences _pref = await SharedPreferences.getInstance();
      if (_pref.getString('userId') != null) {
        var userId = _pref.getString('userId');
        //get the current location of the user when they are moving
        var currentLocation =
            LatLng(location.coords.latitude, location.coords.longitude);
        await db
            .updateUserLiveLocation(
                uid: userId, currentLocation: currentLocation)
            .then((value) {})
            .catchError((err) async {
          if (err) {}
        });
      }
      break;

    case bg.Event.ACTIVITYCHANGE:
      bg.ActivityChangeEvent activity = headlessEvent.event;
      print('Activity Changed: $activity');
      break;
  }
}

//Receive information in backgroundFetch in headless state
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;

  //if background fetch timeout event? finish and bail out
  if (task.timeout) {
    print('[BackgroundFetch] - Headless Task Timeout: $taskId');
    BackgroundFetch.finish(taskId);
    return;
  }

  try {
    var location =
        await bg.BackgroundGeolocation.getCurrentPosition(samples: 1, extras: {
      'event': 'background-fetch',
      'headless': true,
    });
    print('[Location] - $location');
  } catch (e) {
    print('[Location] Error - $e');
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  int count = 0;
  if (prefs.get('fetch-count') != null) {
    count = prefs.getInt('fetch-count');
  }
  prefs.setInt('fetch-count', ++count);
  print('[BackgroundFetch] - count: $count');

  BackgroundFetch.finish(taskId);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
  bg.BackgroundGeolocation.registerHeadlessTask(
      backgroundGeolocationHeadlessTask);

  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
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
        title: 'Royal Marble',
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
    var status;
    if (await Permission.location.serviceStatus.isEnabled) {
      await Geolocator.requestPermission();
    } else {
      status = await Permission.location.status;
      if (status.isGranted) {
      } else {
        status =
            await [Permission.location, Permission.locationAlways].request();
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
