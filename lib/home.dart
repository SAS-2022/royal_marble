import 'dart:async';
import 'dart:math';
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
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const fetchBackGround = 'fetchBackground';

void callbackDispatcher() async {
  Workmanager().executeTask((taskName, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      switch (taskName) {
        case fetchBackGround:
          geo.Position userLocation = await geo.Geolocator.getCurrentPosition(
              desiredAccuracy: geo.LocationAccuracy.high);
          print('the current Location: $userLocation- $userId');

          break;
      }
    }

    return Future.value(true);
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final db = DatabaseService();

  UserData userProvider;
  final Completer<GoogleMapController> _googleMapController = Completer();
  LocationData currentLocation;
  LocationData startLocation;
  Location _locationCurrent = Location();
  Location _locationStart = Location();
  double distanceCrossed = 0.0;
  double distanceToUpdate = 10;
  geo.Position position;

  @override
  void initState() {
    super.initState();
    _getLocationPermission();
    _locationCurrent.onLocationChanged.listen((event) {
      getCurrentLocation();
    });

    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    Workmanager().registerPeriodicTask('1', fetchBackGround,
        frequency: const Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserData>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      drawer: ProfileDrawer(currentUser: userProvider),
      body: _buildHomeScreen(),
    );
  }

  Widget _buildHomeScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        //will display the location of the user
        FutureBuilder(
            future: getCurrentLocation(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
                  child: Column(
                    children: [
                      Text('The Longitude: ${currentLocation.longitude}'),
                      Text('The Latitdue: ${currentLocation.latitude}'),
                      Text('Distance: $distanceCrossed'),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }),

        userProvider.isActive != null && userProvider.isActive
            ? Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await _authService.signOut();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (route) => false);
                  },
                  child: const Text('Sign Out'),
                ),
              )
            : const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Center(
                    child: Text(
                  'Current User is still not active, please contact your admin to activate your account!',
                  style: textStyle4,
                )),
              ),
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

    geo.Position userLocation = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high);
    setState(() {
      position = userLocation;
    });
  }

  //fetch location while running in background

  Future<LocationData> getCurrentLocation() async {
    final _sharePref = await SharedPreferences.getInstance();

    _locationCurrent.getLocation().then((location) {
      startLocation ??= location;

      if (startLocation != location) {
        currentLocation = location;
      }
      if (distanceCrossed > distanceToUpdate) {
        //will update the database
        db.updateUserLiveLocation(
            uid: userProvider.uid, currentLocation: currentLocation);

        distanceToUpdate += 10;
      }
    });

    if (startLocation != null && currentLocation != null) {
      distanceCrossed = _calculateDistanceTraveled(
          startLat: startLocation.latitude,
          startLng: startLocation.longitude,
          currentLat: currentLocation.latitude,
          currentLng: currentLocation.longitude);

      distanceCrossed *= (1000).floor();
    }

    //set the user id in the shared pref
    if (userProvider != null) {
      await _sharePref.setString('userId', userProvider.uid);
    }

    setState(() {});
    return currentLocation;
  }

  double _calculateDistanceTraveled(
      {double startLat,
      double startLng,
      double currentLat,
      double currentLng}) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((currentLat - startLat) * p) / 2 +
        cos(startLat * p) *
            cos(currentLat * p) *
            (1 - cos((currentLng - startLng) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }
}
