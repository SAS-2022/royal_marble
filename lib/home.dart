import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/screens/profile_drawer.dart';
import 'package:royal_marble/services/auth.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:royal_marble/shared/snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

JsonEncoder encoder = new JsonEncoder.withIndent("     ");

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final db = DatabaseService();
  SnackBarWidget _snackBarWidget = SnackBarWidget();
  SharedPreferences _pref;
  UserData userProvider;
  final Completer<GoogleMapController> _googleMapController = Completer();
  LatLng currentLocation;
  LocationData startLocation;
  Location _locationCurrent = Location();
  Location _locationStart = Location();
  double distanceCrossed = 0.0;
  double distanceToUpdate = 10;
  geo.Position position;
  double lat, lng;
  int tempCounter = 0;

  bool _isMoving;
  bool _enabled;
  String _motionActivity;
  String _odometer;
  String _content;
  String _distanceLocation;
  String _distanceMotion;

  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;
    _isMoving = false;
    _enabled = true;
    _content = '';
    _motionActivity = 'UNKNOWN';
    _odometer = '0';
    _getLocationPermission();

    Future.delayed(const Duration(seconds: 10), () => detectMotion());
    Future.delayed(const Duration(seconds: 5), () => _setUserId());
  }

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserData>(context);
    return Scaffold(
      appBar: AppBar(
          title: const Text('Main Page'),
          backgroundColor: const Color.fromARGB(255, 191, 180, 66),
          actions: <Widget>[
            Switch(value: _enabled, onChanged: _onClickEnable),
          ]),
      drawer: ProfileDrawer(currentUser: userProvider),
      body: _buildHomeScreen(),
    );
  }

  Widget _buildHomeScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Times Updated: $tempCounter'),
        const SizedBox(
          height: 20,
        ),
        IconButton(
          icon: Icon(Icons.gps_fixed),
          onPressed: _onClickGetCurrentPosition,
        ),
        userProvider.currentLocation != null
            ? Text('Lat: ${userProvider.currentLocation['Lat']}')
            : const Text(''),
        userProvider.currentLocation != null
            ? Text('Lng: ${userProvider.currentLocation['Lng']}')
            : const Text(''),
        Text('Distance Location: $_distanceLocation m'),
        Text('Distance Motion: $_motionActivity · $_distanceMotion m'),
        MaterialButton(
            minWidth: 50.0,
            child: Icon((_isMoving) ? Icons.pause : Icons.play_arrow,
                color: Colors.white),
            color: (_isMoving) ? Colors.red : Colors.green,
            onPressed: _onClickChangePace),
        userProvider.isActive != null && userProvider.isActive
            ? const SizedBox.shrink()
            : const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Center(
                    child: Text(
                  'Current User is still not active, please contact your admin to activate your account!',
                  style: textStyle4,
                )),
              ),
        Center(
          child: ElevatedButton(
            onPressed: () async {
              await _authService.signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false);
            },
            child: const Text('Sign Out'),
          ),
        )
      ],
    );
  }

  Future<void> _getLocationPermission() async {
    if (await Permission.location.serviceStatus.isEnabled) {
      var status = await Permission.location.status;
      if (status.isGranted) {
        if (Permission.location == Permission.locationWhenInUse ||
            Permission.location == Permission.location) {
          await [Permission.location, Permission.locationAlways].request();
        }
      } else if (status.isDenied) {
        await openAppSettings();
      } else {
        print('$status');
      }
    }
    getCurrentLocation();
  }

  //fetch location while running in background
  Future<void> getCurrentLocation() async {
    geo.Position userLocation = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high);
    if (mounted) {
      setState(() {
        position = userLocation;
      });
    }
    if (position != null) {
      currentLocation = LatLng(position.latitude, position.longitude);
      db
          .updateUserLiveLocation(
              uid: userProvider.uid, currentLocation: currentLocation)
          .then((value) {
        setState(() {
          tempCounter++;
        });
      }).catchError((err) {
        if (err) {
          _snackBarWidget.content = 'Error getting location: $err';
          _snackBarWidget.showSnack();
        }
      });
    }
  }

  void detectMotion() async {
    bg.BackgroundGeolocation.onLocation(_onLocation);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
    bg.BackgroundGeolocation.ready(bg.Config(
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
            distanceFilter: 2.0,
            stopOnTerminate: false,
            startOnBoot: true,
            debug: false,
            logLevel: bg.Config.LOG_LEVEL_VERBOSE,
            notification: bg.Notification(
              priority: bg.Config.NOTIFICATION_PRIORITY_LOW,
              sticky: false,
            ),
            enableHeadless: true,
            reset: true))
        .then((bg.State state) {
      if (mounted) {
        setState(() {
          _enabled = state.enabled;
          _isMoving = state.isMoving;
        });
      }

      print('the state: Enabled: $_enabled - Moving: $_isMoving');
    });
  }

  void _onClickEnable(enabled) {
    if (enabled) {
      bg.BackgroundGeolocation.start().then((bg.State state) {
        print('[start] success $state');
        setState(() {
          _enabled = state.enabled;
          _isMoving = state.isMoving;
        });
      });
    } else {
      bg.BackgroundGeolocation.stop().then((bg.State state) {
        print('[stop] success: $state');
        // Reset odometer.
        bg.BackgroundGeolocation.setOdometer(0.0);

        setState(() {
          _odometer = '0.0';
          _enabled = state.enabled;
          _isMoving = state.isMoving;
        });
      });
    }
  }

  void _onClickGetCurrentPosition() {
    bg.BackgroundGeolocation.getCurrentPosition(
            persist: false, // <-- do not persist this location
            desiredAccuracy: 0, // <-- desire best possible accuracy
            timeout: 30000, // <-- wait 30s before giving up.
            samples: 3 // <-- sample 3 location before selecting best.
            )
        .then((bg.Location location) {
      print('[getCurrentPosition] - $location');
    }).catchError((error) {
      print('[getCurrentPosition] ERROR: $error');
    });
  }

  void _onClickChangePace() {
    setState(() {
      _isMoving = !_isMoving;
    });
    print("[onClickChangePace] -> $_isMoving");

    bg.BackgroundGeolocation.changePace(_isMoving).then((bool isMoving) {
      print('[changePace] success $isMoving');
    }).catchError((e) {
      print('[changePace] ERROR: ' + e.code.toString());
    });
  }

  void _onLocation(bg.Location location) {
    String odometerKM = (location.odometer / 1000.0).toStringAsFixed(1);
    double odometerME = (location.odometer);
    print('The distance Meter: $odometerME');
    if (mounted) {
      setState(() {
        _content = encoder.convert(location.toMap());
        _odometer = odometerKM;
        _distanceLocation = odometerME.toStringAsFixed(2);
        lat = location.coords.longitude;
        lng = location.coords.latitude;
      });
    }
    if (odometerME > 50) {
      //update the database with the new coordinated
      getCurrentLocation();
    }
  }

  void _onMotionChange(bg.Location location) {
    String odometerKM = (location.odometer / 1000.0).toStringAsFixed(1);
    double odometerMEd = location.odometer;
    String odometerME = (location.odometer).toStringAsFixed(2);
    print('The distance Motion: $odometerME');
    if (mounted) {
      setState(() {
        _odometer = odometerKM;
        _distanceMotion = odometerME;
        lat = location.coords.longitude;
        lng = location.coords.latitude;
      });
    }
    if (odometerMEd > 50.0) {}
  }

  //set user id
  void _setUserId() async {
    _pref = await SharedPreferences.getInstance();
    String userId = _pref.getString('userId');
    if (userId == null) {
      if (userProvider != null) {
        _pref.setString('userId', userProvider.uid);
      }
    }
  }
}
