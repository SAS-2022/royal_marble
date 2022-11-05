import 'dart:async';
import 'dart:convert';
import 'package:background_geolocation_firebase/background_geolocation_firebase.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/projects/project_form.dart';
import 'package:royal_marble/projects/project_grid.dart';
import 'package:royal_marble/projects/worker_current_state.dart';
import 'package:royal_marble/screens/profile_drawer.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/calculate_distance.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:royal_marble/shared/loading.dart';
import 'package:royal_marble/shared/snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

JsonEncoder encoder = const JsonEncoder.withIndent("     ");

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DatabaseService();
  List<UserData> allUsers = [];
  SnackBarWidget _snackBarWidget = SnackBarWidget();
  SharedPreferences _pref;
  UserData userProvider;
  List<ProjectData> allProjectProvider = [];
  Future assignedProject;
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
  // List<ProjectData> assignedProject = [];
  List<dynamic> messages = [];

  bool _isMoving;
  bool _enabled;
  bool _persistEnabled;
  String _motionActivity;
  String _odometer;
  String _content;
  String _distanceLocation;
  String _distanceMotion;
  String _locationJSON;

  @override
  void initState() {
    super.initState();

    _snackBarWidget.context = context;
    _enabled = true;
    _persistEnabled = true;
    _content = '';
    _motionActivity = 'UNKNOWN';
    _odometer = '0';
    _getLocationPermission();
    //_onClickEnable(_enabled);
    //_onClickChangePace();
    Future.delayed(const Duration(seconds: 5), () => _setUserId());
  }

  //platform massages are asynchrones so we initialize in an async method
  Future<void> initPlatformState() async {
    _pref = await SharedPreferences.getInstance();
    String userId;
    if (userProvider == null) {
      userId = _pref.getString('userId');
    } else {
      userId = userProvider.uid;
    }
    // bg.BackgroundGeolocation.onLocation((bg.Location location) {
    //   if (mounted) {
    //     setState(() {
    //       _locationJSON = encoder.convert(location.toMap());
    //     });
    //   }
    // });
    //First confirgure background adapter
    if (userId != null) {
      BackgroundGeolocationFirebase.configure(
          BackgroundGeolocationFirebaseConfig(
        locationsCollection: 'users/$userId/location/current',
        // geofencesCollection: 'geofence',
        updateSingleDocument: true,
      ));
    }

    // bg.BackgroundGeolocation.ready(bg.Config(
    //   debug: false,
    //   distanceFilter: 50,
    //   logLevel: bg.Config.LOG_LEVEL_VERBOSE,
    //   stopTimeout: 1,
    //   stopOnTerminate: false,
    //   enableHeadless: true,
    //   startOnBoot: true,
    // )).then((bg.State state) {
    //   if (mounted) {
    //     setState(() {
    //       _enabled = state.enabled;
    //       if (_enabled) {
    //         _persistEnabled = true;
    //         print('the geoloation started');
    //         bg.BackgroundGeolocation.start();
    //         _enablePersistMethod();
    //       } else {
    //         _persistEnabled = false;
    //         bg.BackgroundGeolocation.stop();
    //         print('the geolocation stopped');
    //         _enablePersistMethod();
    //       }
    //     });
    //   }
    // });
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  //enable persist
  void _enablePersistMethod() {
    if (_persistEnabled) {
      bg.BackgroundGeolocation.setConfig(
          bg.Config(persistMode: bg.Config.PERSIST_MODE_ALL));
    } else {
      bg.BackgroundGeolocation.setConfig(
          bg.Config(persistMode: bg.Config.PERSIST_MODE_NONE));
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    userProvider = Provider.of<UserData>(context);
    allUsers = Provider.of<List<UserData>>(context);
    allProjectProvider = Provider.of<List<ProjectData>>(context);
    _size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      drawer: allUsers != null && allUsers.isNotEmpty
          ? ProfileDrawer(
              currentUser: userProvider,
              allUsers: allUsers,
            )
          : const Loading(),
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
                height: _size.height / 4.5,
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
                          padding: const EdgeInsets.all(5),
                          height: _size.height / 4,
                          width: _size.width / 2,
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 186, 186, 130),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey[500],
                                    offset: const Offset(-4, 4),
                                    spreadRadius: 1)
                              ],
                              border: Border.all(width: 2),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Name: ',
                                    style: textStyle3,
                                  ),
                                  Expanded(
                                    child: Text(
                                      allProjectProvider[index]
                                          .projectName
                                          .toUpperCase(),
                                      style: textStyle5,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Details: ',
                                    style: textStyle3,
                                  ),
                                  Expanded(
                                    child: allProjectProvider[index]
                                                .projectDetails
                                                .length >
                                            30
                                        ? Text(
                                            '${allProjectProvider[index].projectDetails.characters.take(30)}...',
                                            style: textStyle5,
                                          )
                                        : Text(allProjectProvider[index]
                                            .projectDetails),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Contactor: ',
                                    style: textStyle3,
                                  ),
                                  Text(
                                    allProjectProvider[index].contactorCompany,
                                    style: textStyle5,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Phone: ',
                                    style: textStyle3,
                                  ),
                                  Text(
                                    allProjectProvider[index].phoneNumber,
                                    style: textStyle5,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Workers: ',
                                    style: textStyle3,
                                  ),
                                  Text(
                                    allProjectProvider[index].assignedWorkers !=
                                            null
                                        ? allProjectProvider[index]
                                            .assignedWorkers
                                            .length
                                            .toString()
                                        : 'None',
                                    style: textStyle5,
                                  ),
                                ],
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
    return SingleChildScrollView(
        child: userProvider.isActive != null && userProvider.isActive
            ? Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    //List of projects assigned two
                    FutureBuilder(
                        future: getUserAssignedProject(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting ||
                                snapshot.connectionState ==
                                    ConnectionState.none) {
                              return const Center(
                                child: Loading(),
                              );
                            } else {
                              return SizedBox(
                                  width: _size.width - 100,
                                  height: (_size.height / 2) - 100,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 15),
                                    child: GestureDetector(
                                      onTap: () async {
                                        //once tapped shall navigate to a page that will show assigned workers
                                        //will present a dialog on the things that could be done
                                        await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => ProjectGrid(
                                                      currentUser: userProvider,
                                                      selectedProject:
                                                          snapshot.data,
                                                    )));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        height: 80,
                                        width: _size.width / 2,
                                        decoration: BoxDecoration(
                                            color: userProvider
                                                            .distanceToProject !=
                                                        null &&
                                                    userProvider
                                                            .distanceToProject <=
                                                        userProvider
                                                                .assignedProject[
                                                            'radius']
                                                ? Colors.green
                                                : Colors.yellowAccent,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.grey[500],
                                                  offset: const Offset(-4, 4),
                                                  spreadRadius: 1)
                                            ],
                                            border: Border.all(width: 2),
                                            borderRadius:
                                                BorderRadius.circular(55)),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    'Name: ',
                                                    style: textStyle3,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    snapshot.data.projectName
                                                        .toUpperCase(),
                                                    style: textStyle5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    'Details: ',
                                                    style: textStyle3,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: snapshot
                                                              .data
                                                              .projectDetails
                                                              .length >
                                                          60
                                                      ? Text(
                                                          '${snapshot.data.projectDetails.toString().characters.take(60)}...',
                                                          style: textStyle5,
                                                        )
                                                      : Text(snapshot
                                                          .data.projectDetails),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    'On Site: ',
                                                    style: textStyle3,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    userProvider.distanceToProject !=
                                                                null &&
                                                            userProvider
                                                                    .distanceToProject <=
                                                                userProvider
                                                                        .assignedProject[
                                                                    'radius']
                                                        ? 'Yes'
                                                        : 'No',
                                                    style: textStyle5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    'Assigned Workers: ',
                                                    style: textStyle3,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    '${snapshot.data.assignedWorkers.length} workers',
                                                    style: textStyle5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ));
                            }
                          } else {
                            return SizedBox(
                              width: _size.width,
                              height: (_size.height / 2) - 100,
                              child: const Center(
                                child: Text(
                                  'No Assigned Projects',
                                  style: textStyle4,
                                ),
                              ),
                            );
                          }
                        }),

                    const Divider(
                      height: 25,
                      thickness: 3,
                    ),
                    //Messages from Admin
                    Padding(
                        padding: const EdgeInsets.only(top: 20, left: 15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Distance Location: $_distanceLocation',
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                          ],
                        )),

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
              )
            : Padding(
                padding: const EdgeInsets.only(left: 25, right: 25, top: 150),
                child: SizedBox(
                  height: _size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        'Thank you for creating an account',
                        style: textStyle1,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      Text(
                        'Your account is still under approval, you should be notified once it has been approved.',
                        style: textStyle4,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ));
  }

  Widget _buildSalesHomeScreen() {
    return SingleChildScrollView(
        child: userProvider.isActive != null && userProvider.isActive
            ? Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    //List of projects assigned two

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
              )
            : Padding(
                padding: const EdgeInsets.only(left: 25, right: 25, top: 150),
                child: SizedBox(
                  height: _size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        'Thank you for creating an account',
                        style: textStyle1,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      Text(
                        'Your account is still under approval, you should be notified once it has been approved.',
                        style: textStyle4,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ));
  }

  Future<ProjectData> getUserAssignedProject() async {
    if (userProvider != null && userProvider.assignedProject != null) {
      return await db.getPorjectByIdFuture(
          projectId: userProvider.assignedProject['id']);
    }

    return null;
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
    double distance;
    geo.Position userLocation = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high);
    if (mounted) {
      setState(() {
        position = userLocation;
      });
    }
    if (position != null) {
      currentLocation = LatLng(position.latitude, position.longitude);

      //check if user is assgined to a project
      if (userProvider.assignedProject != null && currentLocation != null) {
        distance = (CalculateDistance().distanceBetweenTwoPoints(
                    currentLocation.latitude,
                    currentLocation.longitude,
                    userProvider.assignedProject['projectAddress']['Lat'],
                    userProvider.assignedProject['projectAddress']['Lng'])) *
                1000 -
            userProvider.assignedProject['radius'];

        db
            .updateUserLiveLocation(
                uid: userProvider.uid,
                currentLocation: currentLocation,
                distance: distance)
            .then((value) {
          print('Location updated with Distance');
        }).catchError((err) {
          if (err) {
            _snackBarWidget.content = 'Error getting location: $err';
            _snackBarWidget.showSnack();
          }
        });
      } else {
        db
            .updateUserLiveLocation(
                uid: userProvider.uid, currentLocation: currentLocation)
            .then((value) {
          print('Location updated without Distance');
        }).catchError((err) {
          if (err) {
            _snackBarWidget.content = 'Error getting location: $err';
            _snackBarWidget.showSnack();
          }
        });
      }
    }
  }

  void detectMotion() async {
    bg.BackgroundGeolocation.onLocation(_onLocation);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
    bg.BackgroundGeolocation.ready(bg.Config(
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
            distanceFilter: 20.0,
            autoSync: true,
            isMoving: true,
            stopOnTerminate: false,
            startOnBoot: true,
            debug: false,
            backgroundPermissionRationale: bg.PermissionRationale(
              title: 'Allow Royal Marble to access location when in background',
              message:
                  'This app will monitor your location when it is in the background',
              positiveAction: 'Change to Background',
              negativeAction: 'Cancel',
            ),
            logLevel: bg.Config.LOG_LEVEL_VERBOSE,
            notification: bg.Notification(
              title: 'Royal Marble',
              text: 'Location Service',
              priority: bg.Config.NOTIFICATION_PRIORITY_LOW,
              sticky: false,
            ),
            enableHeadless: true,
            reset: true))
        .then((bg.State state) {
      if (mounted) {
        setState(() {
          //_enabled = state.enabled;
          //_isMoving = state.isMoving;
        });
      }
    });
  }

  void _onLocation(bg.Location location) async {
    print('[location] - $location');
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
    print('the odometerME: $odometerME');
    if (odometerME > 150) {
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('callingFunction');
      await callable.call(<String, dynamic>{
        'location': {
          'lat': location.coords.latitude,
          'lng': location.coords.longitude,
        }
      });
      //update the database with the new coordinated
      getCurrentLocation();
      odometerME = 0.0;
    }
  }

  void _onMotionChange(bg.Location location) {
    print('[motionchange] - $location');
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
      if (userProvider.uid != null && _pref != null) {
        _pref.setString('userId', userProvider.uid);
        // Future.delayed(const Duration(seconds: 7), () => detectMotion());
        Future.delayed(const Duration(seconds: 10), () => initPlatformState());
      }
    } else {
      // Future.delayed(const Duration(seconds: 7), () => detectMotion());
      Future.delayed(const Duration(seconds: 10), () => initPlatformState());
    }
  }

  void _onClickEnable(enabled) async {
    if (enabled) {
      callback(bg.State state) async {
        print('[start] success: $state');
        if (mounted) {
          setState(() {
            _enabled = state.enabled;
            _isMoving = state.isMoving;
          });
        }
      }

      bg.State state = await bg.BackgroundGeolocation.state;
      if (state.trackingMode == 1) {
        bg.BackgroundGeolocation.start().then(callback);
      } else {
        bg.BackgroundGeolocation.startGeofences().then(callback);
      }
    } else {
      callback(bg.State state) {
        print('[stop] success: $state');
        setState(() {
          _enabled = state.enabled;
          _isMoving = state.isMoving;
        });
      }

      bg.BackgroundGeolocation.stop().then(callback);
    }
  }

  // Manually toggle the tracking state:  moving vs stationary
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
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkerCurrentStream(
                              selectedProject: projectData,
                            ),
                          ),
                        );
                      },
                      child: const Text('View Workers State'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
