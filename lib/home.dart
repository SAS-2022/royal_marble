import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/projects/project_grid.dart';
import 'package:royal_marble/screens/profile_drawer.dart';
import 'package:royal_marble/services/auth.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:royal_marble/shared/loading.dart';
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
  List<ProjectData> allProjectProvider = [];
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
  Size _size;
  List<ProjectData> assignedProject = [];
  List<dynamic> messages = [];

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
    allProjectProvider = Provider.of<List<ProjectData>>(context);
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      drawer: ProfileDrawer(currentUser: userProvider),
      body: _selectView(),
    );
  }

  Widget _selectView() {
    var role;
    if (userProvider != null && userProvider.roles != null) {
      if (userProvider.roles.contains('isAdmin')) {
        role = 'admin';
      } else if (userProvider.roles.contains('isSales')) {
        role = 'sales';
      } else {
        role = 'worker';
      }

      if (role != null) {
        switch (role) {
          case 'admin':
            return _buildAdminHomeScreen();

          case 'sales':
            return _buildSalesHomeScreen();

          case 'worker':
            return _buildWorkerHomeScreen();
        }
      } else {
        return const Center(child: Loading());
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildAdminHomeScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        //Project Section Adding and viewing project
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
          child: SizedBox(
            height: _size.height / 3,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              const Text(
                'Current projects and the team working in each on of them',
                style: textStyle6,
              ),
              const SizedBox(
                height: 15,
              ),
              SizedBox(
                height: _size.height / 4,
                width: _size.width - 20,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: allProjectProvider.length,
                  itemBuilder: ((context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: GestureDetector(
                        onTap: () async {
                          //once tapped shall navigate to a page that will show assigned workers
                          //will present a dialog on the things that could be done
                          await _showProjectDialog(
                              projectData: allProjectProvider[index]);
                        },
                        onLongPress: () {
                          //if long pressed it will show a dialog that will allow you to edit or delete project
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          height: 80,
                          width: _size.width / 2,
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Name: ${allProjectProvider[index].projectName.toUpperCase()}',
                                style: textStyle5,
                              ),
                              Text(
                                'Details: ${allProjectProvider[index].projectDetails}',
                                style: textStyle5,
                              ),
                              Text(
                                'Contactor: ${allProjectProvider[index].contactorCompany}',
                                style: textStyle5,
                              ),
                              Text(
                                'Phone: ${allProjectProvider[index].phoneNumber}',
                                style: textStyle5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(
                  child: Text(
                      'Total Projects: ${allProjectProvider.length} project'),
                ),
              )
            ]),
          ),
        ),
        const Divider(
          height: 20,
          thickness: 3,
        ),
        //Sales team section

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
      ],
    );
  }

  Widget _buildWorkerHomeScreen() {
    return userProvider.isActive != null && userProvider.isActive
        ? SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 25, left: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  //List of projects assigned two
                  assignedProject.isEmpty
                      ? SizedBox(
                          height: (_size.height / 2) - 50,
                          child: ListView.builder(
                              itemCount: assignedProject.length,
                              itemBuilder: ((context, index) {
                                return const ListTile(
                                  title: Text('Project Name'),
                                  subtitle: Text('Project Details'),
                                );
                              })),
                        )
                      : const Center(
                          child: Text(
                            'You have not been assigned to any project',
                            style: textStyle3,
                          ),
                        ),
                  const Divider(
                    height: 25,
                    thickness: 3,
                  ),
                  //Messages from Admin
                  Padding(
                    padding: const EdgeInsets.only(top: 20, left: 15),
                    child: Column(children: [
                      const Text(
                        'Please note this section is dedicated for messages from your manager',
                        style: textStyle6,
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      messages.isEmpty
                          ? SizedBox(
                              height: (_size.height / 2) - 50,
                              child: ListView.builder(
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    return const ListTile(
                                      title: Text('Message Title'),
                                      subtitle: Text('Message Details'),
                                    );
                                  }),
                            )
                          : const Center(
                              child: Text(
                                'Currently you have no message',
                                style: textStyle3,
                              ),
                            )
                    ]),
                  )
                ],
              ),
            ),
          )
        : const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Center(
                child: Text(
              'Current User is still not active, please contact your admin to activate your account!',
              style: textStyle4,
            )),
          );
  }

  Widget _buildSalesHomeScreen() {}

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
    if (mounted) {
      setState(() {
        _content = encoder.convert(location.toMap());
        _odometer = odometerKM;
        _distanceLocation = odometerME.toStringAsFixed(2);
        lat = location.coords.longitude;
        lng = location.coords.latitude;
      });
    }
    if (odometerME > 150) {
      //update the database with the new coordinated
      getCurrentLocation();
      odometerME = 0.0;
    }
  }

  void _onMotionChange(bg.Location location) {
    String odometerKM = (location.odometer / 1000.0).toStringAsFixed(1);
    double odometerMEd = location.odometer;
    String odometerME = (location.odometer).toStringAsFixed(2);

    if (mounted) {
      setState(() {
        _odometer = odometerKM;
        _distanceMotion = odometerME;
        lat = location.coords.longitude;
        lng = location.coords.latitude;
      });
    }
    if (odometerMEd > 50.0) {
      odometerMEd = 0;
    }
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

  Future<void> _showProjectDialog({ProjectData projectData}) async {
    await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Project Options'),
            content: SizedBox(
              height: _size.height / 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Text(
                      'The following options will allow you to assgin and remove workers from a project',
                      style: textStyle6,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: SizedBox(
                      width: _size.width / 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 56, 52, 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                        ),
                        onPressed: () async {
                          //Navigate to a page to assign workers
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ProjectGrid(
                                        selectedProject: projectData,
                                        currentUser: userProvider,
                                      )));
                        },
                        child: const Text('Assign Workers'),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _size.width / 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                      ),
                      onPressed: () async {
                        //Navigate to a page to assign workers
                      },
                      child: const Text('Remove Workers'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
