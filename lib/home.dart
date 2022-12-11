import 'dart:async';
import 'dart:convert';
import 'package:background_geolocation_firebase/background_geolocation_firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/projects/project_grid.dart';
import 'package:royal_marble/projects/project_status.dart';
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
  List<String> activeProjects = [];
  List<String> potentialProjects = [];
  // List<ProjectData> assignedProject = [];
  List<dynamic> messages = [];
  //required for location tracking
  bool _isMoving;
  bool _enabled;
  bool _persistEnabled;
  String _motionActivity;
  String _odometer;
  String _content;
  String _distanceLocation;
  String _distanceMotion;
  String _locationJSON;
  Timer _timer;
  ph.PermissionStatus permissionStatus;

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
    _onClickEnable(_enabled);
    Future.delayed(const Duration(seconds: 5), () => _setUserId());

    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (permissionStatus.isDenied ||
          permissionStatus.isLimited ||
          permissionStatus.isPermanentlyDenied ||
          permissionStatus.isRestricted) {
        _getLocationPermission();
      }
    });
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

    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      if (mounted) {
        setState(() {
          _locationJSON = encoder.convert(location.toMap());
        });
      }
      getCurrentLocation();
    });

    if (userId != null) {
      BackgroundGeolocationFirebase.configure(
          BackgroundGeolocationFirebaseConfig(
        locationsCollection: 'users/$userId/location/current',
        // geofencesCollection: 'geofence',
        updateSingleDocument: true,
      )).catchError((err) {
        print('An error occured: $err');
      }).then((value) => print('the location was updated: $value'));
    }

    if (!mounted) return;
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
      resizeToAvoidBottomInset: false,
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
            return _buildAdminHomeScreen();

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
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          child: SizedBox(
            height: _size.height / 2.6,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              const Text(
                'Current projects and the team working in each on of them',
                style: textStyle6,
              ),
              const SizedBox(
                height: 15,
              ),
              Container(
                padding: const EdgeInsets.all(10),
                height: _size.height / 3.5,
                width: _size.width - 20,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: allProjectProvider.length,
                  itemBuilder: ((context, index) {
                    if (allProjectProvider[index].projectStatus == 'active') {
                      if (!activeProjects
                          .contains(allProjectProvider[index].uid)) {
                        activeProjects.add(allProjectProvider[index].uid);
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: GestureDetector(
                          onTap: userProvider.roles.contains('isAdmin')
                              ? () async {
                                  //once tapped shall navigate to a page that will show assigned workers
                                  //will present a dialog on the things that could be done
                                  await _showProjectDialog(
                                      projectData: allProjectProvider[index]);
                                }
                              : userProvider.roles.contains('isSales')
                                  ? () async {
                                      print('we are here');
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ProjectGrid(
                                                    currentUser: userProvider,
                                                    selectedProject:
                                                        allProjectProvider[
                                                            index],
                                                  )));
                                    }
                                  : null,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            width: _size.width / 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color.fromARGB(255, 148, 218, 83),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey[500],
                                    offset: const Offset(-3, 3),
                                    spreadRadius: 2)
                              ],
                              border: Border.all(width: 1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  child: Text(
                                    allProjectProvider[index]
                                        .projectName
                                        .toUpperCase(),
                                    style: textStyle4,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(
                                  height: 15,
                                ),
                                Column(
                                  children: [
                                    const Text(
                                      'Workers: ',
                                      style: textStyle3,
                                    ),
                                    Text(
                                      allProjectProvider[index]
                                                  .assignedWorkers !=
                                              null
                                          ? allProjectProvider[index]
                                              .assignedWorkers
                                              .length
                                              .toString()
                                          : 'None',
                                      style: textStyle12,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              Center(
                child: Text(
                    'Total Active Projects: ${activeProjects.length} project'),
              )
            ]),
          ),
        ),
        const Divider(
          height: 2,
          thickness: 3,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          child: SizedBox(
            height: _size.height / 2.8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Potential Project that are still under negotiation',
                  style: textStyle6,
                ),
                const SizedBox(
                  height: 15,
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  height: _size.height / 3.8,
                  width: _size.width - 20,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allProjectProvider.length,
                    itemBuilder: ((context, index) {
                      if (allProjectProvider[index].projectStatus ==
                          'potential') {
                        if (!potentialProjects
                            .contains(allProjectProvider[index].uid)) {
                          potentialProjects.add(allProjectProvider[index].uid);
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: GestureDetector(
                            onTap: userProvider.roles.contains('isAdmin')
                                ? () async {
                                    //once tapped shall navigate to a page that will show assigned workers
                                    //will present a dialog on the things that could be done
                                    await _showProjectDialog(
                                        projectData: allProjectProvider[index]);
                                  }
                                : userProvider.roles.contains('isSales')
                                    ? () async {
                                        await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => ProjectGrid(
                                                      currentUser: userProvider,
                                                      selectedProject:
                                                          allProjectProvider[
                                                              index],
                                                    )));
                                      }
                                    : null,
                            onLongPress: () {
                              //if long pressed it will show a dialog that will allow you to edit or delete project
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              width: _size.width / 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color.fromARGB(255, 214, 163, 238),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.grey[500],
                                      offset: const Offset(-3, 3),
                                      spreadRadius: 2)
                                ],
                                border: Border.all(width: 1),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    child: Text(
                                      allProjectProvider[index]
                                          .projectName
                                          .toUpperCase(),
                                      style: textStyle4,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  Column(
                                    children: [
                                      const Text(
                                        'Workers: ',
                                        style: textStyle3,
                                      ),
                                      Text(
                                        allProjectProvider[index]
                                                    .assignedWorkers !=
                                                null
                                            ? allProjectProvider[index]
                                                .assignedWorkers
                                                .length
                                                .toString()
                                            : 'None',
                                        style: textStyle12,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }),
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                Center(
                  child: Text(
                      'Total Projects: ${potentialProjects.length} project'),
                )
              ],
            ),
          ),
        ),
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
                      height: 15,
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
                      height: 15,
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

  //will get the permission to access the location
  Future<void> _getLocationPermission() async {
    try {
      if (await ph.Permission.location.serviceStatus.isEnabled) {
        permissionStatus =
            await ph.Permission.location.status.onError((error, stackTrace) {
          return error;
        });
        print('the permission: ${permissionStatus}');
        if (permissionStatus.isGranted) {
          if (ph.Permission.location == ph.Permission.locationWhenInUse ||
              ph.Permission.location == ph.Permission.location) {
            await [ph.Permission.location, ph.Permission.locationAlways]
                .request();
          }
          //update database with permission status
          if (userProvider != null) {
            var result = await db.updateUserPermissionStatus(
                uid: userProvider.uid, permissionStatus: permissionStatus);
            print('the result: $result');
          }

          getCurrentLocation();
        } else if (permissionStatus.isDenied ||
            permissionStatus.isRestricted ||
            permissionStatus.isPermanentlyDenied ||
            permissionStatus.isLimited ||
            permissionStatus == PermissionStatus.denied) {
          await ph.openAppSettings();
          //update data base with permission status
          if (userProvider != null) {
            var result = await db.updateUserPermissionStatus(
                uid: userProvider.uid, permissionStatus: permissionStatus);
            print('the result: $result');
          }
        } else {
          _snackBarWidget.content = 'Location Permission: $permissionStatus';
          _snackBarWidget.showSnack();
        }
        print('the status: $permissionStatus');
      }
    } catch (e) {
      print('Error obtaining permission: $e');
    }
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

    print('the distance from the assigned project: $distance');
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
      if (userProvider.uid != null && _pref != null) {
        _pref.setString('userId', userProvider.uid);
        Future.delayed(const Duration(seconds: 7), () => detectMotion());
        Future.delayed(const Duration(seconds: 10), () => initPlatformState());
      }
    } else {
      Future.delayed(const Duration(seconds: 7), () => detectMotion());
      Future.delayed(const Duration(seconds: 10), () => initPlatformState());
    }
  }

  void _onClickEnable(enabled) async {
    if (enabled) {
      callback(bg.State state) async {
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
        setState(() {
          _enabled = state.enabled;
          _isMoving = state.isMoving;
        });
      }

      bg.BackgroundGeolocation.stop().then(callback);
    }
  }

  Future<void> _showProjectDialog({ProjectData projectData}) async {
    await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Project Options'),
            content: SizedBox(
              height: _size.height / 3.5,
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      projectData.projectStatus == 'active'
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SizedBox(
                                width: _size.width / 2,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
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
                            )
                          : const SizedBox.shrink(),
                      projectData.projectStatus == 'active'
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SizedBox(
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
                            )
                          : const SizedBox.shrink(),
                      //define project status
                      SizedBox(
                        width: _size.width / 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                          onPressed: () async {
                            //Navigate to a page to assign workers
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProjectStatus(
                                  selectedProject: projectData,
                                ),
                              ),
                            );
                          },
                          child: const Text('Change Status'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }
}
