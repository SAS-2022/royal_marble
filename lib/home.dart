import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:background_geolocation_firebase/background_geolocation_firebase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:provider/provider.dart';
import 'package:royal_marble/mockups/mockup_grid.dart';
import 'package:royal_marble/mockups/mockup_status.dart';
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
import 'package:royal_marble/shared/location_requirement.dart';
import 'package:royal_marble/shared/snack_bar.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_builder/timer_builder.dart';

JsonEncoder encoder = const JsonEncoder.withIndent("     ");

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, this.currentUser}) : super(key: key);
  final UserData? currentUser;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DatabaseService();
  List<UserData> allUsers = [];
  SnackBarWidget _snackBarWidget = SnackBarWidget();
  SharedPreferences? _pref;
  UserData? userProvider;
  Map<String, dynamic>? timeSheetProvider;
  List<ProjectData> allProjectProvider = [];
  List<MockupData> allMockupProvider = [];
  Future? assignedProject;
  final Completer<GoogleMapController> _googleMapController = Completer();
  LatLng? currentLocation;
  LocationData? startLocation;
  Location _locationCurrent = Location();
  Location _locationStart = Location();
  double distanceCrossed = 0.0;
  double distanceToUpdate = 10;
  geo.Position? position;
  double? lat, lng;
  int tempCounter = 0;
  Size? _size;
  List<String> activeProjects = [];
  List<String> potentialProjects = [];
  List<String> activeMockups = [];
  List<dynamic> messages = [];
  Future? _getAssignedProjects;
  Future? _getAssignedMockup;
  //required for location tracking
  bool? _isMoving;
  bool? _enabled;
  bool? _persistEnabled;
  String? _motionActivity;
  String? _odometer;
  String? _content;
  String? _distanceLocation;
  String? _distanceMotion;
  String? _locationJSON;
  Timer? _timer;
  bool _loadingPermission = true;
  bool _isDialogShowing = false;
  ph.PermissionStatus? permissionActivity;
  ph.PermissionStatus? permissionStatus;
  var timeSheetData;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubsciption;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(
          () => _loadingPermission = false,
        );
      }
    });
    _snackBarWidget.context = context;
    _enabled = true;
    _persistEnabled = true;
    _content = '';
    _motionActivity = 'UNKNOWN';
    _odometer = '0';
    _getLocationPermission();
    Future.delayed(const Duration(seconds: 5), () => _setUserId());
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (permissionStatus == null ||
          permissionStatus!.isDenied ||
          permissionStatus!.isLimited ||
          permissionStatus!.isPermanentlyDenied ||
          permissionStatus!.isRestricted) {
        _getLocationPermission();
      }

      if (permissionActivity == null ||
          permissionActivity!.isDenied ||
          permissionActivity!.isLimited ||
          permissionActivity!.isPermanentlyDenied ||
          permissionActivity!.isRestricted) {
        _requestMotionPermission();
      }
      _getAssignedProjects = getUserAssignedProject();
      _getAssignedMockup = getUserAssignedMockup();
    });
    //Initiate connectivity
    initConnectivity();
    _connectivitySubsciption =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    super.dispose();
    _connectivitySubsciption!.cancel();
  }

  String getSystemTime() {
    var now = DateTime.now();
    DateTime startingTime;
    DateTime leavingTime;
    var difference = 'Good Morning';
    if (userProvider != null) {
      difference =
          'Good Morning,\n${userProvider!.firstName} ${userProvider!.lastName}';
    }
    if (timeSheetProvider != null &&
        timeSheetProvider!.containsKey(userProvider!.uid)) {
      if (timeSheetProvider![userProvider!.uid]['arriving_at'] != null &&
          timeSheetProvider![userProvider!.uid]['leaving_at'] == null) {
        startingTime = DateTime.parse(
            timeSheetProvider![userProvider!.uid]['arriving_at']);

        difference = now.difference(startingTime).toString().split('.')[0];
      }
      if (timeSheetProvider![userProvider!.uid]['arriving_at'] != null &&
          timeSheetProvider![userProvider!.uid]['leaving_at'] != null) {
        startingTime = DateTime.parse(
            timeSheetProvider![userProvider!.uid]['arriving_at']);
        leavingTime =
            DateTime.parse(timeSheetProvider![userProvider!.uid]['leaving_at']);

        if (leavingTime.isAfter(startingTime)) {
          var totalHours =
              leavingTime.difference(startingTime).toString().split('.')[0];
          difference = 'You completed: $totalHours\nHave A Nice Day';
        } else {
          difference =
              'Already checked In and Checked Out, you are checking in again';
        }
      }
      if (timeSheetProvider![userProvider!.uid]['arriving_at'] == null &&
          timeSheetProvider![userProvider!.uid]['leaving_at'] == null) {
        difference = 'Please contact admin: ERR001 (null values)';
      }
    }

    return difference;
  }

  //Will check user connectivity to the internet
  Future<void> initConnectivity() async {
    ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return;
    }
    //if result was removed from the tree while their is no connection we want
    //to discard the reply rather than calling setState
    if (!mounted) {
      return Future.value(null);
    }
    return _updateConnectionStatus(result);
  }

  //Moniture and list to connection status
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
      if (_connectionStatus == ConnectivityResult.none) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (builder) {
              return Dialog(
                backgroundColor: const Color.fromARGB(255, 218, 223, 88),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                child: SizedBox(
                  height: _size!.height / 5,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            flex: 1,
                            child: Text(
                              'No Internet',
                              style: textStyle10,
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: Text(
                              'Please check your connection in order to proceed',
                              textAlign: TextAlign.center,
                              style: textStyle5,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: TextButton(
                              onPressed: () async {
                                _connectionStatus != ConnectivityResult.none
                                    ? Navigator.pop(context)
                                    : null;
                              },
                              child: const Text(
                                'Retry',
                                style: textStyle3,
                              ),
                            ),
                          )
                        ]),
                  ),
                ),
              );
            });
      }
    });
  }

  //platform massages are asynchrones so we initialize in an async method
  Future<void> initPlatformState() async {
    _pref = await SharedPreferences.getInstance();
    String userId;
    if (userProvider == null) {
      userId = _pref!.getString('userId').toString();
    } else {
      userId = userProvider!.uid.toString();
    }

    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      if (mounted) {
        setState(() {
          _locationJSON = encoder.convert(location.toMap());
        });
      }
      Future.delayed(const Duration(seconds: 1), (() => getCurrentLocation()));
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
    userProvider = Provider.of<UserData?>(context);
    allUsers = Provider.of<List<UserData>>(context);
    allProjectProvider = Provider.of<List<ProjectData>>(context);
    allMockupProvider = Provider.of<List<MockupData>>(context);
    timeSheetProvider = Provider.of<Map<String, dynamic>>(context);
    _size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      drawer: allUsers != null && allUsers.isNotEmpty ||
              permissionStatus == null ||
              permissionActivity == null ||
              permissionActivity!.isPermanentlyDenied ||
              permissionStatus!.isPermanentlyDenied
          ? ProfileDrawer(
              currentUser: userProvider!,
              allUsers: allUsers,
            )
          : const Loading(),
      body: _loadingPermission
          ? const Center(
              child: Loading(),
            )
          : permissionStatus == null ||
                  permissionActivity == null ||
                  permissionActivity!.isPermanentlyDenied ||
                  permissionStatus!.isDenied ||
                  permissionStatus!.isLimited ||
                  permissionStatus!.isRestricted
              ? const LocationRequirement()
              : _selectView(),
      resizeToAvoidBottomInset: false,
    );
  }

  Widget _selectView() {
    var role;
    if (userProvider != null && userProvider!.roles != null) {
      if (userProvider!.roles!.contains('isAdmin')) {
        role = 'admin';
      } else if (userProvider!.roles!.contains('isSales')) {
        role = 'sales';
      } else if (userProvider!.roles!.contains('isSupervisor')) {
        role = 'supervisor';
      } else {
        role = 'worker';
      }

      if (role != null) {
        switch (role) {
          case 'admin':
            return _buildAdminHomeScreen();
          case 'sales':
            return _buildAdminHomeScreen();
          case 'supervisor':
            return _buildSupervisorHomeScreen();
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
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          //Project Section Adding and viewing project
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            child: SizedBox(
              height: _size!.height / 2.4,
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                const Text(
                  'Active Projects',
                  style: textStyle10,
                ),
                const Text(
                  'Current projects and the team working in each on of them',
                  style: textStyle6,
                ),
                const SizedBox(
                  height: 15,
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  height: _size!.height / 3.5,
                  width: _size!.width - 20,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allProjectProvider.length,
                    itemBuilder: ((context, index) {
                      if (allProjectProvider[index].projectStatus == 'active') {
                        if (!activeProjects
                            .contains(allProjectProvider[index].uid)) {
                          activeProjects.add(allProjectProvider[index].uid!);
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: GestureDetector(
                            onTap: userProvider!.roles!.contains('isAdmin')
                                ? () async {
                                    //once tapped shall navigate to a page that will show assigned workers
                                    //will present a dialog on the things that could be done
                                    await _showProjectDialog(
                                        projectData: allProjectProvider[index]);
                                  }
                                : userProvider!.roles!.contains('isSales')
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
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              width: _size!.width / 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color.fromARGB(255, 148, 218, 83),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.grey[500]!,
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
                                          .projectName!
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
                                                .assignedWorkers!
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
          //Builds the list of potential project
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            child: SizedBox(
              height: _size!.height / 2.5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Potential Projects',
                    style: textStyle10,
                  ),
                  const Text(
                    'Potential Project that are still under negotiation',
                    style: textStyle6,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    height: _size!.height / 3.8,
                    width: _size!.width - 20,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: allProjectProvider.length,
                      itemBuilder: ((context, index) {
                        if (allProjectProvider[index].projectStatus ==
                            'potential') {
                          if (!potentialProjects
                              .contains(allProjectProvider[index].uid)) {
                            potentialProjects
                                .add(allProjectProvider[index].uid!);
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: GestureDetector(
                              onTap: userProvider!.roles!.contains('isAdmin')
                                  ? () async {
                                      //once tapped shall navigate to a page that will show assigned workers
                                      //will present a dialog on the things that could be done
                                      await _showProjectDialog(
                                          projectData:
                                              allProjectProvider[index]);
                                    }
                                  : userProvider!.roles!.contains('isSales')
                                      ? () async {
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => ProjectGrid(
                                                        currentUser:
                                                            userProvider,
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
                                width: _size!.width / 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color.fromARGB(255, 214, 163, 238),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.grey[500]!,
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
                                            .projectName!
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
                                                  .assignedWorkers!
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
                    child: Text('Total Projects: ${potentialProjects.length}'),
                  )
                ],
              ),
            ),
          ),
          const Divider(
            height: 2,
            thickness: 3,
          ),
          //Builds the list of mockup samples
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            child: SizedBox(
              height: _size!.height / 2.5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Active Mock-Ups',
                    style: textStyle10,
                  ),
                  const Text(
                    'Mock-Up samples that needs to be installed',
                    style: textStyle6,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    height: _size!.height / 3.8,
                    width: _size!.width - 20,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: allMockupProvider.length,
                      itemBuilder: ((context, index) {
                        if (allMockupProvider[index].mockupStatus == 'active') {
                          if (!activeMockups
                              .contains(allMockupProvider[index].uid)) {
                            activeMockups.add(allMockupProvider[index].uid!);
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: GestureDetector(
                              onTap: userProvider!.roles!.contains('isAdmin')
                                  ? () async {
                                      //once tapped shall navigate to a page that will show assigned workers
                                      //will present a dialog on the things that could be done
                                      await _showProjectDialog(
                                          mockupData: allMockupProvider[index]);
                                    }
                                  : userProvider!.roles!.contains('isSales')
                                      ? () async {
                                          // await Navigator.push(
                                          //     context,
                                          //     MaterialPageRoute(
                                          //         builder: (_) => ProjectGrid(
                                          //               currentUser: userProvider,
                                          //               selectedProject:
                                          //                   allProjectProvider[
                                          //                       index],
                                          //             )));
                                        }
                                      : null,
                              onLongPress: () {
                                //if long pressed it will show a dialog that will allow you to edit or delete project
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                width: _size!.width / 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color.fromARGB(255, 214, 163, 238),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.grey[500]!,
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
                                        allMockupProvider[index]
                                            .mockupName!
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
                                          allMockupProvider[index]
                                                      .assignedWorkers !=
                                                  null
                                              ? allMockupProvider[index]
                                                  .assignedWorkers!
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
                    child: Text('Total Mock-Ups: ${activeMockups.length}'),
                  )
                ],
              ),
            ),
          ),
          userProvider!.isActive != null && userProvider!.isActive!
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
      ),
    );
  }

  Widget _buildWorkerHomeScreen() {
    return SizedBox(
      height: _size!.height,
      child: SingleChildScrollView(
          child: userProvider!.isActive != null && userProvider!.isActive!
              ? Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Assigned Projects',
                        style: textStyle10,
                      ),
                      //List of projects assigned two
                      FutureBuilder(
                          future: _getAssignedProjects,
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
                                    width: _size!.width,
                                    height: (_size!.height / 3) - 100,
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
                                                        currentUser:
                                                            userProvider,
                                                        selectedProject:
                                                            snapshot.data,
                                                      )));
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          height: 80,
                                          width: _size!.width / 2,
                                          decoration: BoxDecoration(
                                              color: userProvider!
                                                              .distanceToProject !=
                                                          null &&
                                                      userProvider!
                                                          .assignedProject
                                                          .isNotEmpty &&
                                                      userProvider!
                                                              .distanceToProject <=
                                                          userProvider!
                                                                  .assignedProject[
                                                              'radius']
                                                  ? Colors.green
                                                  : Colors.yellowAccent,
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.grey[500]!,
                                                    offset: const Offset(-4, 4),
                                                    spreadRadius: 1)
                                              ],
                                              border: Border.all(width: 2),
                                              borderRadius:
                                                  BorderRadius.circular(15)),
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
                                                        : Text(snapshot.data
                                                            .projectDetails),
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
                                                      userProvider!.distanceToProject !=
                                                                  null &&
                                                              userProvider!
                                                                  .assignedProject
                                                                  .isNotEmpty &&
                                                              userProvider!
                                                                      .distanceToProject <=
                                                                  userProvider!
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
                                width: _size!.width,
                                height: (_size!.height / 3) - 100,
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
                      //List of assigned mockup projcects
                      const Text(
                        'Assigned Mock-Up',
                        style: textStyle10,
                      ),
                      //List of projects assigned two
                      FutureBuilder(
                          future: _getAssignedMockup,
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
                                    width: _size!.width,
                                    height: (_size!.height / 3) - 100,
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
                                                  builder: (_) => MockupGrid(
                                                        currentUser:
                                                            userProvider,
                                                        selectedMockup:
                                                            snapshot.data,
                                                      )));
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          height: 80,
                                          width: _size!.width / 2,
                                          decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                  255, 12, 182, 197),
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.grey[500]!,
                                                    offset: const Offset(-4, 4),
                                                    spreadRadius: 1)
                                              ],
                                              border: Border.all(width: 2),
                                              borderRadius:
                                                  BorderRadius.circular(15)),
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
                                                      snapshot.data.mockupName
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
                                                                .mockupDetails
                                                                .length >
                                                            60
                                                        ? Text(
                                                            '${snapshot.data.mockupDetails.toString().characters.take(60)}...',
                                                            style: textStyle5,
                                                          )
                                                        : Text(snapshot.data
                                                            .mockupDetails),
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
                                width: _size!.width,
                                height: (_size!.height / 3) - 100,
                                child: const Center(
                                  child: Text(
                                    'No Assigned Mockups',
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
                      //Timer for when work starts
                      Padding(
                        padding: const EdgeInsets.only(top: 20, left: 15),
                        child: Container(
                          height: _size!.height / 6,
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(20)),
                          child: Center(
                            child: TimerBuilder.periodic(
                                const Duration(seconds: 1), builder: (context) {
                              return Text(
                                getSystemTime(),
                                style: getSystemTime().length > 25
                                    ? timer2TextStyle
                                    : timerTextStyle,
                                softWrap: true,
                                textAlign: TextAlign.center,
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25, top: 150),
                  child: SizedBox(
                    height: _size!.height,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
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
                )),
    );
  }

  Widget _buildSupervisorHomeScreen() {
    return SizedBox(
      height: _size!.height,
      child: SingleChildScrollView(
          child: userProvider!.isActive != null && userProvider!.isActive!
              ? Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Projects',
                        style: textStyle10,
                      ),
                      //List of projects assigned two
                      FutureBuilder(
                          future: _getAssignedProjects,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: Loading(),
                                );
                              } else {
                                return SizedBox(
                                    width: _size!.width,
                                    height: (_size!.height / 3) - 100,
                                    child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: snapshot.data.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                top: 10,
                                                bottom: 10,
                                                left: 5,
                                                right: 15),
                                            child: GestureDetector(
                                              onTap: () async {
                                                //once tapped shall navigate to a page that will show assigned workers
                                                //will present a dialog on the things that could be done
                                                await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            ProjectGrid(
                                                              currentUser:
                                                                  userProvider,
                                                              selectedProject:
                                                                  snapshot.data[
                                                                      index],
                                                            )));
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                height: 80,
                                                width: _size!.width / 1.5,
                                                decoration: BoxDecoration(
                                                    color: userProvider!
                                                                    .distanceToProject !=
                                                                null &&
                                                            userProvider!
                                                                .assignedProject
                                                                .isNotEmpty &&
                                                            userProvider!
                                                                    .distanceToProject <=
                                                                snapshot
                                                                    .data[index]
                                                                    .radius
                                                        ? Colors.green
                                                        : Colors.yellowAccent,
                                                    boxShadow: [
                                                      BoxShadow(
                                                          color:
                                                              Colors.grey[500]!,
                                                          offset: const Offset(
                                                              -4, 4),
                                                          spreadRadius: 1)
                                                    ],
                                                    border:
                                                        Border.all(width: 2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            55)),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
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
                                                            snapshot.data[index]
                                                                .projectName
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
                                                                      .data[
                                                                          index]
                                                                      .projectDetails
                                                                      .length >
                                                                  60
                                                              ? Text(
                                                                  '${snapshot.data.projectDetails.toString().characters.take(60)}...',
                                                                  style:
                                                                      textStyle5,
                                                                )
                                                              : Text(snapshot
                                                                  .data[index]
                                                                  .projectDetails),
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
                                                            userProvider!.distanceToProject !=
                                                                        null &&
                                                                    userProvider!
                                                                            .distanceToProject <=
                                                                        snapshot
                                                                            .data[index]
                                                                            .radius
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
                                                            '${snapshot.data[index].assignedWorkers.length} workers',
                                                            style: textStyle5,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }));
                              }
                            } else {
                              return SizedBox(
                                width: _size!.width,
                                height: (_size!.height / 3) - 100,
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
                      //Assigned mockup sections
                      //List of assigned mockup projcects
                      const Text(
                        'Assigned Mock-Up',
                        style: textStyle10,
                      ),
                      //List of projects assigned two
                      FutureBuilder(
                          future: _getAssignedMockup,
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
                                    width: _size!.width,
                                    height: (_size!.height / 3) - 100,
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
                                                  builder: (_) => MockupGrid(
                                                        currentUser:
                                                            userProvider,
                                                        selectedMockup:
                                                            snapshot.data,
                                                      )));
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          height: 80,
                                          width: _size!.width / 2,
                                          decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                  255, 12, 182, 197),
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.grey[500]!,
                                                    offset: const Offset(-4, 4),
                                                    spreadRadius: 1)
                                              ],
                                              border: Border.all(width: 2),
                                              borderRadius:
                                                  BorderRadius.circular(15)),
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
                                                      snapshot.data
                                                                  .mockupName !=
                                                              null
                                                          ? snapshot
                                                              .data.mockupName
                                                              .toUpperCase()
                                                          : '',
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
                                                                .mockupDetails
                                                                .length >
                                                            60
                                                        ? Text(
                                                            '${snapshot.data.mockupDetails.toString().characters.take(60)}...',
                                                            style: textStyle5,
                                                          )
                                                        : Text(snapshot.data
                                                            .mockupDetails),
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
                                width: _size!.width,
                                height: (_size!.height / 3) - 100,
                                child: const Center(
                                  child: Text(
                                    'No Assigned Mockups',
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
                      //Timer for when work starts
                      Padding(
                        padding: const EdgeInsets.only(top: 20, left: 15),
                        child: Container(
                          height: _size!.height / 6,
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(20)),
                          child: Center(
                            child: TimerBuilder.periodic(
                                const Duration(seconds: 1), builder: (context) {
                              return Text(
                                getSystemTime(),
                                style: getSystemTime().length > 25
                                    ? timer2TextStyle
                                    : timerTextStyle,
                                softWrap: true,
                                textAlign: TextAlign.center,
                              );
                            }),
                          ),
                        ),
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
                                  height: (_size!.height / 2) - 50,
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
                    height: _size!.height,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
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
                )),
    );
  }

  //For supervisors
  Future<List<ProjectData>> getSupervisorAssignedProjects() async {
    List<ProjectData> allProjects = [];
    if (userProvider != null && userProvider!.assignedProject != null) {
      for (var project in userProvider!.assignedProject) {
        var result = await db.getPorjectByIdFuture(projectId: project['id']);
        if (result != null) {
          allProjects.add(result);
        }
      }
    }

    return allProjects;
  }

  Future<List<ProjectData>> getSupervisorAssignedMockups() async {
    List<ProjectData> allProjects = [];
    if (userProvider != null && userProvider!.assignedProject != null) {
      for (var project in userProvider!.assignedProject) {
        var result = await db.getPorjectByIdFuture(projectId: project['id']);
        if (result != null) {
          allProjects.add(result);
        }
      }
    }

    return allProjects;
  }

  //Get user assigned project
  Future<ProjectData> getUserAssignedProject() async {
    var result;

    if (userProvider != null && userProvider!.assignedProject != null) {
      if (userProvider!.roles!.contains('isSupervisor')) {
        for (var project in userProvider!.assignedProject) {
          result = await db.getPorjectByIdFuture(projectId: project['id']);
        }
      } else {
        if (userProvider!.assignedProject['id'] != null) {
          result = await db.getPorjectByIdFuture(
              projectId: userProvider!.assignedProject['id']);
        }
      }
    }
    return result;
  }

  //Get user assigned mockup
  Future<MockupData> getUserAssignedMockup() async {
    var result;

    if (userProvider != null && userProvider!.assignedMockups != null) {
      if (userProvider!.roles!.contains('isSupervisor')) {
        for (var mockup in userProvider!.assignedMockups) {
          result = await db.getMockupByIdFuture(mockupId: mockup['id']);
        }
      } else {
        if (userProvider!.assignedMockups != null &&
            userProvider!.assignedMockups.isNotEmpty) {
          for (var mockup in userProvider!.assignedMockups) {
            result = await db.getMockupByIdFuture(mockupId: mockup['id']);
          }
        }
      }
    }
    return result;
  }

  //will get the permission to access the location
  Future<void> _getLocationPermission() async {
    try {
      if (await ph.Permission.location.serviceStatus != null &&
          await ph.Permission.location.serviceStatus.isEnabled &&
          await ph.Permission.locationAlways.isGranted) {
        permissionStatus = await ph.Permission.location.status;

        if (permissionStatus!.isGranted) {
          //update database with permission status
          if (userProvider != null && userProvider!.uid != null) {
            await db.updateUserPermissionStatus(
                uid: userProvider!.uid, permissionStatus: permissionStatus);
          }
          _onClickEnable(_enabled);
          _requestMotionPermission();
          Future.delayed(
              const Duration(seconds: 2), (() => getCurrentLocation()));
        } else {
          //update data base with permission status
          if (userProvider != null) {
            await db.updateUserPermissionStatus(
                uid: userProvider!.uid, permissionStatus: permissionStatus);
          }
          //Will show an alert dialog to request User Access Permission
          requestUserAccessPermission();
          _snackBarWidget.content = 'Location Permission: $permissionStatus';
          _snackBarWidget.showSnack();
        }
      } else {
        //Will show an alert dialog to request User Access Permission if location is not always enabled
        requestUserAccessPermission();
      }
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  Future<void> _requestMotionPermission() async {
    permissionActivity = await ph.Permission.activityRecognition.status;

    if (permissionActivity!.isDenied ||
        permissionActivity!.isLimited ||
        permissionActivity!.isPermanentlyDenied ||
        permissionActivity!.isRestricted) {
      if (Platform.isAndroid) {
        var status = await [ph.Permission.activityRecognition]
            .request()
            .then((value) => value)
            .onError((error, stackTrace) {
          print('error obtaining permission: $error');
          return {};
        }).whenComplete(() => print('Permssion activity completed'));

        if (status[ph.Permission.activityRecognition] ==
            ph.PermissionStatus.permanentlyDenied) {
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                    title: const Text('Motion Sensor'),
                    content: const Text(
                        'Royal Marble requires access to fitness and activity permission in order to function properly'),
                    backgroundColor: const Color.fromARGB(255, 60, 111, 125),
                    actions: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 7, 45, 97),
                            fixedSize: Size(_size!.width - 100, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () async {
                            await ph.openAppSettings();
                          },
                          child: const Text(
                            'Open Phone Settings',
                            style: textStyle2,
                          )),
                    ],
                  ));
          ph.openAppSettings();
        }
      } else {
        await ph.Permission.sensors.request().then((value) => value);
      }
    }
  }

  //Alert Dialog
  requestUserAccessPermission() {
    //will check if the dialog is showing or not
    if (!_isDialogShowing) {
      setState(() {
        _isDialogShowing = true;
      });

      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: const Text(
                  'Requesting Location Permission',
                  style: textStyle15,
                  textAlign: TextAlign.center,
                ),
                content: const Text(
                  'Royal Marble collects location and motion data to make tracking, check In, check Out features possible even when the app is closed or not in use',
                  style: textStyle3,
                  textAlign: TextAlign.center,
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: _size!.width / 3,
                        child: TextButton(
                            style: TextButton.styleFrom(
                                elevation: 3,
                                shadowColor: Colors.black,
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                )),
                            onPressed: () async {
                              var result = await [
                                ph.Permission.location,
                                ph.Permission.locationAlways,
                                ph.Permission.activityRecognition
                              ].request().then((value) {
                                return value;
                              }).onError((error, stackTrace) {
                                print(
                                    'Error obtaining permssion Location: $error');
                                return {};
                              });
                              if (result != null &&
                                  result[ph.Permission.location] ==
                                      ph.PermissionStatus.granted) {
                                await ph.openAppSettings();
                              }
                              setState(() {
                                _isDialogShowing = false;
                              });

                              Navigator.of(context, rootNavigator: true).pop();
                            },
                            child: const Text(
                              'Allow',
                              style: textStyle2,
                            )),
                      ),
                      SizedBox(
                        width: _size!.width / 3,
                        child: TextButton(
                            style: TextButton.styleFrom(
                                elevation: 3,
                                shadowColor: Colors.black,
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                )),
                            onPressed: () {
                              setState(() {
                                _isDialogShowing = false;
                              });
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                            child: const Text(
                              'Deny',
                              style: textStyle2,
                            )),
                      )
                    ],
                  ),
                ],
              ));
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
      currentLocation = LatLng(position!.latitude, position!.longitude);
      //check if user is assgined to a project
      if (userProvider!.assignedProject != null &&
          userProvider!.assignedProject.isNotEmpty &&
          currentLocation != null) {
        distance = (CalculateDistance().distanceBetweenTwoPoints(
                    currentLocation!.latitude,
                    currentLocation!.longitude,
                    userProvider!.assignedProject['projectAddress']['Lat'],
                    userProvider!.assignedProject['projectAddress']['Lng'])) *
                1000 -
            userProvider!.assignedProject['radius'];
        if (userProvider!.uid != null &&
            currentLocation!.latitude != null &&
            currentLocation!.longitude != null) {
          db
              .updateUserLiveLocation(
                  uid: userProvider!.uid,
                  currentLocation: currentLocation,
                  distance: distance)
              .then((value) {})
              .catchError((err) {
            if (err) {
              _snackBarWidget.content = 'Error getting location: $err';
              _snackBarWidget.showSnack();
            }
          });
        } else {
          _snackBarWidget.context = context;
          _snackBarWidget.content =
              'Please refresh the app, or connect to the internet!';
          _snackBarWidget.showSnack();
        }
      } else {
        if (userProvider!.uid != null &&
            currentLocation!.latitude != null &&
            currentLocation!.longitude != null) {
          db
              .updateUserLiveLocation(
                  uid: userProvider!.uid, currentLocation: currentLocation)
              .then((value) {
            print('Location updated without Distance');
          }).catchError((err) {
            if (err) {
              _snackBarWidget.content = 'Error getting location: $err';
              _snackBarWidget.showSnack();
            }
          });
        } else {
          _snackBarWidget.context = context;
          _snackBarWidget.content =
              'Please refresh the app, or connect to the internet!';
          _snackBarWidget.showSnack();
        }
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
    String userId = _pref!.getString('userId')!;
    if (userId == null) {
      if (userProvider!.uid != null && _pref != null) {
        _pref!.setString('userId', userProvider!.uid!);
        Future.delayed(const Duration(seconds: 7), () => detectMotion());
        Future.delayed(const Duration(seconds: 10), () => initPlatformState());
      }
    } else {
      _getAssignedProjects = getUserAssignedProject();
      _getAssignedMockup = getUserAssignedMockup();

      setState(() {});

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

  Future<void> _showProjectDialog(
      {ProjectData? projectData, MockupData? mockupData}) async {
    if (projectData != null) {
      await showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text('Project Options'),
              content: SizedBox(
                height: _size!.height / 3.5,
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
                                  width: _size!.width / 2,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(25.0),
                                      ),
                                    ),
                                    onPressed: () async {
                                      //Navigate to a page to assign workers
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ProjectGrid(
                                                    selectedProject:
                                                        projectData,
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
                                  width: _size!.width / 2,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[400],
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(25.0),
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
                          width: _size!.width / 2,
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
    if (mockupData != null) {
      await showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text('Mock-Up Options'),
              content: SizedBox(
                height: _size!.height / 3.5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 15),
                      child: Text(
                        'The following options will allow you to assgin and remove workers from a mockup',
                        style: textStyle6,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        mockupData.mockupStatus == 'active'
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: SizedBox(
                                  width: _size!.width / 2,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(25.0),
                                      ),
                                    ),
                                    onPressed: () async {
                                      //Navigate to a page to assign workers
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => MockupGrid(
                                                    selectedMockup: mockupData,
                                                    currentUser: userProvider,
                                                  )));
                                    },
                                    child: const Text('Assign Workers'),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        mockupData.mockupStatus == 'active'
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: SizedBox(
                                  width: _size!.width / 2,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[400],
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(25.0),
                                      ),
                                    ),
                                    onPressed: () async {
                                      //Navigate to a page to assign workers
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WorkerCurrentStream(
                                            selectedProject: null,
                                            selectedMockup: mockupData,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('View Workers State'),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        //define mockup status
                        SizedBox(
                          width: _size!.width / 2,
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
                                  builder: (_) => MockupStatus(
                                    selectedMockup: mockupData,
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
}
