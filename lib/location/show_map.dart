import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/src/types/marker_updates.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:royal_marble/location/.env.dart';
import 'package:royal_marble/location/direction_repo.dart';
import 'package:royal_marble/mockups/mockup_form.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/projects/project_form.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/snack_bar.dart';

import '../models/directions.dart';
import '../models/user_model.dart';
import '../services/database.dart';
import '../shared/loading.dart';

class ShowMap extends StatefulWidget {
  const ShowMap({
    Key? key,
    this.currentUser,
    this.listOfMarkers,
    this.addProject,
    this.addMockup,
  }) : super(key: key);
  final UserData? currentUser;
  final String? listOfMarkers;
  final bool? addProject;
  final bool? addMockup;
  @override
  _ShowMapState createState() => _ShowMapState();
}

class _ShowMapState extends State<ShowMap> {
  Stream<List<CustomMarker>>? streamLocation;
  Map<String, dynamic>? futureLocation;
  final SnackBarWidget _snackBarWidget = SnackBarWidget();
  GoogleMapController? _mapController;
  Map<String, dynamic>? locationProvider;
  var projectProvider;
  var userProvider;
  var mockupProvider;
  List<ClientData>? clientProvider;
  Directions? _info;
  String title = '';
  var lat = 0.0, long = 0.0;
  var _getMyCurrentLocation;
  Set<Circle> _circules = HashSet<Circle>();
  SharedPreferences? _preferredTab;
  int _prefTab = 0;
  var db = DatabaseService();
  // PickResult selectedPlace;
  String? apiKey;
  LatLng? _center;
  final _elevation = 3.0;

  Map<String, Marker> listMarkers = {};
  Map<String, Marker> clientMarkers = {};
  Set<Marker> noMarkers = {};
  String? clientSector;
  Future? assignedMarkers;
  Size? _size;
  double radius = 1200;
  Set<Marker>? userMarkers;
  String? locationName;
  LatLng? _selectedLocation;
  Timer? _timer;
  bool _loading = true;
  double _mapZoom = 17.0;

  // var markerId = MarkerId('one');
  Marker marker1 = Marker(
      markerId: const MarkerId('No clients were loaded'),
      position: const LatLng(26.3650133, 50.19190929999999),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow));

  @override
  void initState() {
    super.initState();
    getSharedPreferences();

    _center = LatLng(widget.currentUser!.homeAddress!['Lat'],
        widget.currentUser!.homeAddress!['Lng']);
    _getApiKey();
    _getMyCurrentLocation = _determinePosition();
    _identifyMapMarkers();
    if (widget.listOfMarkers == 'users') {
      noMarkers.add(marker1);
      _snackBarWidget.context = context;
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _updateCurrentMarkers();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.listOfMarkers == 'users') {
      _timer!.cancel();
    }
  }

  Future<void> getSharedPreferences() async {
    _preferredTab = await SharedPreferences.getInstance();
    if (_preferredTab != null && _preferredTab!.getInt('tab') != null) {
      _prefTab = _preferredTab!.getInt('tab')!;
    } else {
      _prefTab = 0;
    }
  }

  Future<void> _identifyMapMarkers() async {
    switch (widget.listOfMarkers) {
      case 'users':
        title = 'Users';
        _getClientMarker();
        break;
      case 'Add Project':
        title = 'Add Project';
        break;
      case 'Add Mockup':
        title = 'Add Mockup';
        break;
    }
  }

  //Function will get the client markers assign by each sales depending on their previlage
  Future<Set<Marker>> _getClientMarker() async {
    //listMarkers.clear();
    if (widget.currentUser!.roles!.contains('isAdmin')) {
      var currentClients = await db.getClientFuture();
      if (currentClients.isNotEmpty) {
        for (var client in currentClients) {
          clientMarkers.putIfAbsent(
              client.uid!,
              () => Marker(
                    markerId: MarkerId(client.clientName!),
                    position: LatLng(client.clientAddress!['Lat'],
                        client.clientAddress!['Lng']),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen),
                    infoWindow: InfoWindow(
                        title: client.clientName,
                        snippet: client.phoneNumber!.phoneNumber,
                        onTap: () {}),
                  ));
        }
      }
    }
    if (widget.currentUser!.roles!.contains('isSales')) {
      var currentClients =
          await db.getSalesUserClientFuture(userId: widget.currentUser!.uid);
      if (currentClients.isNotEmpty) {
        for (var client in currentClients) {
          clientMarkers.putIfAbsent(
              client.uid!,
              () => Marker(
                    markerId: MarkerId(client.clientName!),
                    position: LatLng(client.clientAddress!['Lat'],
                        client.clientAddress!['Lng']),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen),
                    infoWindow: InfoWindow(
                        title: client.clientName,
                        snippet: client.phoneNumber!.phoneNumber,
                        onTap: () {}),
                  ));
        }
      }
    }
    //will put the client in a list
    if (clientMarkers.isNotEmpty) {
      clientProvider = await db.getClientFuture();
    }

    return userMarkers!;
  }

  //Get directions
  void _getDirections(LatLng destination) async {
    final directions = await DirectionRepository()
        .getDirections(origin: _center, destination: destination);
    setState(() {
      _info = directions;
    });
  }

  //create a circle to assign the project location on the map
  void _setProjectCirclesLocations() {
    _circules.clear();
    for (var project in projectProvider) {
      if (project.projectStatus != 'closed') {
        _circules.add(Circle(
            consumeTapEvents: true,
            onTap: () {
              _showDialog(
                  title: project.projectName,
                  content:
                      '${project.projectDetails}\nWorkers: ${project.assignedWorkers.length}\n',
                  projectData: project);
            },
            circleId: CircleId(project.uid),
            center: LatLng(
                project.projectAddress['Lat'], project.projectAddress['Lng']),
            radius: project.radius,
            fillColor: Colors.redAccent.withOpacity(0.3),
            strokeWidth: 3,
            strokeColor: Colors.redAccent));
      }
    }
  }

  //create a circle to assign the mockup location on the map
  void _setMockupCirclesLocations() {
    // _circules.clear();
    for (var mockup in mockupProvider) {
      if (mockup.mockupStatus != 'closed') {
        _circules.add(Circle(
            consumeTapEvents: true,
            onTap: () {
              _showDialog(
                  title: mockup.mockupName,
                  content: mockup.mockupDetails,
                  mockupData: mockup);
            },
            circleId: CircleId(mockup.uid),
            center: LatLng(
                mockup.mockupAddress['Lat'], mockup.mockupAddress['Lng']),
            radius: mockup.radius,
            fillColor:
                const ui.Color.fromARGB(255, 93, 204, 133).withOpacity(0.3),
            strokeWidth: 3,
            strokeColor: const ui.Color.fromARGB(255, 12, 97, 6)));
      }
    }
  }

  void _showDialog(
      {String? title,
      String? content,
      ProjectData? projectData,
      MockupData? mockupData}) {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text(title!),
            content: Text(content!),
            actions: [
              //Delete the project
              projectData != null || mockupData != null
                  ? Center(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 56, 52, 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                          onPressed: () async {
                            //will check if we are deleting a project or a mockup
                            if (projectData != null &&
                                projectData.uid != null) {
                              if (projectData.assignedWorkers != null &&
                                  projectData.assignedWorkers!.isNotEmpty) {
                                _snackBarWidget.content =
                                    'Please remove workers before deletion';
                                _snackBarWidget.showSnack();
                                return;
                              }
                              await db.deleteProject(
                                  projectId: projectData.uid);
                              Navigator.pop(context);
                            }

                            //will check if we are deleting a project or a mockup
                            if (mockupData != null && mockupData.uid != null) {
                              if (mockupData.assignedWorkers != null &&
                                  mockupData.assignedWorkers!.isNotEmpty) {
                                _snackBarWidget.content =
                                    'Please remove workers before deletion';
                                _snackBarWidget.showSnack();
                                return;
                              }
                              await db.deleteMockup(mockupId: mockupData.uid);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Delete')),
                    )
                  : const SizedBox.shrink()
            ],
          );
        });
  }

  //Get the current position of the device
  //when the location service is not enabled or permissions are denied
  //the future will return an error
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    //Test if location service is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error('Location service is disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        //Permission are denied, try requesting persmission again
        return Future.error('Location permission are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location persmission are denied forever, we cannot handle permission requests');
    }
    //if permissions are granted
    var currentLocation = await Geolocator.getCurrentPosition();
    setState(() {
      lat = currentLocation.latitude;
      long = currentLocation.longitude;
    });
    _center = LatLng(lat, long);
    _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _center!, zoom: _mapZoom)));
    return currentLocation;
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    projectProvider = Provider.of<List<ProjectData>>(context);
    userProvider = Provider.of<List<UserData>>(context);
    mockupProvider = Provider.of<List<MockupData>>(context);
    //Assign project proivder to circules
    if (projectProvider != null && projectProvider.isNotEmpty) {
      _setProjectCirclesLocations();
    }
    if (mockupProvider != null && mockupProvider.isNotEmpty) {
      _setMockupCirclesLocations();
    }
    if (widget.listOfMarkers == 'users' &&
        userProvider != null &&
        userProvider.isNotEmpty) {
      setInitialMarkers();
    }
    return WillPopScope(
      onWillPop: () {
        Navigator.pop(context);
        return Future(() => false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: const Color.fromARGB(255, 191, 180, 66),
        ),
        body: _buildLocationSelection(),
        endDrawer: widget.addProject! || widget.addMockup!
            ? null
            : _buildMarkersDrawer(),
      ),
    );
  }

  //Will determine api key for ios and android
  void _getApiKey() {
    if (Platform.isAndroid) {
      apiKey = googleAPIKey;
    } else {
      apiKey = iosAPIKey;
    }
  }

  void updateState() {
    setState(() {});
  }

  Future setInitialMarkers() async {
    for (var user in userProvider) {
      //  streamLocation = db.getAllUsersLocation(userId: user.uid);
      futureLocation = await db.getUserLocationFuture(usersId: user.uid);
      // var result = await streamLocation.first;
      if (futureLocation!['uuid'] != null) {
        _setInitialMarkers(
          uuid: futureLocation!['uuid'],
          userData: user,
          lat: futureLocation!['lat'],
          lng: futureLocation!['lng'],
        );
      }
    }
  }

  Future<Set<Marker>> _setInitialMarkers(
      {String? uuid, double? lat, double? lng, UserData? userData}) async {
    // final Uint8List markIcons = await getImages(userData.imageUrl, 20);
    List<RichText> _userDetail = [];
    RichText _richText;
    _richText = RichText(
      text: TextSpan(
        children: [
          TextSpan(
              text: '${userData!.firstName} ${userData.lastName}',
              style: textStyle10),
        ],
      ),
    );
    _userDetail.add(_richText);

    listMarkers.putIfAbsent(uuid!, () {
      futureLocation!.forEach((key, value) {
        if (key != 'uuid' && value != '') {
          if (key == 'time') {
            //we will change the value
            var newValue = value.toString().split('T');
            var newTime = newValue[1].split('.')[0];
            var simplifiedTime = DateTime.parse('${newValue[0]}T$newTime');
            simplifiedTime = simplifiedTime.add(const Duration(hours: 4));
            value = simplifiedTime;
          }
          _richText = RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '${key.toUpperCase()}: ', style: textStyle3),
                TextSpan(text: '$value', style: textStyle12),
              ],
            ),
          );
          _userDetail.add(_richText);
        }
      });
      return Marker(
        markerId: MarkerId(uuid),
        position: LatLng(lat!, lng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
            title: '${userData.firstName} ${userData.lastName}',
            snippet: userData.phoneNumber,
            onTap: () {
              showDialog(
                  context: context,
                  builder: (_) {
                    return SizedBox(
                      width: _size!.width - 100,
                      height: _size!.height / 2,
                      child: AlertDialog(
                        title: const Text('Details'),
                        content: SizedBox(
                          height: _size!.height / 3,
                          width: double.maxFinite,
                          child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _userDetail.length,
                              itemBuilder: (context, index) {
                                return RichText(text: _userDetail[index].text);
                              }),
                        ),
                      ),
                    );
                  });
            }),
      );
    });

    if (clientMarkers.isNotEmpty) {
      listMarkers.addAll(clientMarkers);
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
    return userMarkers!;
  }

  void _updateCurrentMarkers() async {
    Map<String, Marker> updatedMarker = {};
    for (var user in userProvider) {
      futureLocation = await db.getUserLocationFuture(usersId: user.uid);
      if (futureLocation!['uuid'] != null) {
        updatedMarker.putIfAbsent(futureLocation!['uuid'], () {
          List<RichText> _userDetail = [];
          RichText _richText;
          _richText = RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: '${user.firstName} ${user.lastName}\n',
                    style: textStyle10),
              ],
            ),
          );
          _userDetail.add(_richText);
          futureLocation!.forEach((key, value) {
            if (key != 'uuid' && value != '') {
              if (key == 'time') {
                //we will change the value
                var newValue = value.toString().split('T');
                var newTime = newValue[1].split('.')[0];
                var simplifiedTime = DateTime.parse('${newValue[0]}T$newTime');
                simplifiedTime = simplifiedTime.add(const Duration(hours: 4));
                value = simplifiedTime;
              }
              _richText = RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: '${key.toUpperCase()}: ', style: textStyle3),
                    TextSpan(text: '$value', style: textStyle12),
                  ],
                ),
              );

              _userDetail.add(_richText);
            }
          });

          return Marker(
            markerId: MarkerId(futureLocation!['uuid']),
            position: LatLng(futureLocation!['lat'], futureLocation!['lng']),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet),
            infoWindow: InfoWindow(
                title: '${user.firstName} ${user.lastName}',
                snippet: '${user.phoneNumber}',
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (_) {
                        return SizedBox(
                          width: _size!.width - 100,
                          height: _size!.height / 2,
                          child: AlertDialog(
                            title: const Text('Details'),
                            content: SizedBox(
                              height: _size!.height / 3,
                              width: double.maxFinite,
                              child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _userDetail.length,
                                  itemBuilder: (context, index) {
                                    return RichText(
                                        text: _userDetail[index].text);
                                  }),
                            ),
                          ),
                        );
                      });
                }),
          );
        });
      }

      if (clientMarkers.isNotEmpty) {
        updatedMarker.addAll(clientMarkers);
      }
    }
    if (mounted) {
      setState(() {
        MarkerUpdates.from(
            Set.of(listMarkers.values), Set.of(updatedMarker.values));
        listMarkers = {};
        listMarkers = updatedMarker;
      });
    }
  }

  Widget _buildLocationSelection() {
    return Stack(
      children: [
        SizedBox(
          height: _size!.height,
          width: _size!.width,
          child: Stack(
            children: [
              userProvider != null
                  ? GoogleMap(
                      onMapCreated: (controller) {
                        setState(() {
                          _mapController = controller;
                        });
                      },
                      onLongPress: (coordinates) async {
                        //passing circle
                        if (coordinates != null) {
                          var betterName = '';
                          await _getLocationName(coordinates);
                          locationName!.replaceAll(' ', '');
                          var theName = locationName!.split('\n');

                          for (var i = 0; i < 7; i++) {
                            betterName += theName[i].trimLeft();
                          }

                          var projectLocation = {
                            'Lat': coordinates.latitude,
                            'Lng': coordinates.longitude,
                            'addressName': betterName
                          };
                          if (widget.addMockup!) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) {
                                  return MockupForm(
                                    projectLocation: projectLocation,
                                    isNewMockup: widget.addMockup!,
                                    currentUser: widget.currentUser!,
                                  );
                                },
                              ),
                            );
                          }
                          if (widget.addProject!) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) {
                                  return ProjectForm(
                                    projectLocation: projectLocation,
                                    isNewProject: widget.addProject!,
                                    currentUser: widget.currentUser!,
                                  );
                                },
                              ),
                            );
                          }
                        }
                      },
                      onTap: (coordinates) {
                        _selectedLocation = coordinates;
                      },
                      circles: _circules,
                      mapToolbarEnabled: true,
                      myLocationButtonEnabled: true,
                      myLocationEnabled: true,
                      polylines: {
                        if (_info != null)
                          Polyline(
                            polylineId: const PolylineId('overview_polyline'),
                            color: Colors.red,
                            width: 5,
                            points: _info!.polylinePoints
                                .map((e) => LatLng(e.latitude, e.longitude))
                                .toList(),
                          )
                      },
                      initialCameraPosition:
                          CameraPosition(target: _center!, zoom: _mapZoom),
                      markers: listMarkers != null && listMarkers.isNotEmpty
                          ? Set.of(listMarkers.values)
                          : noMarkers,
                      mapType: MapType.normal,
                    )
                  : const Center(child: Loading()),
              if (_info != null)
                Positioned(
                  bottom: 20,
                  left: 30,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 6.0,
                        ),
                      ],
                    ),
                    child: Text(
                      '${_info!.totalDistance}, ${_info!.totalDuration}',
                      style: const TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              widget.listOfMarkers == 'users'
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 25.0, 0, 0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: _elevation,
                        child: Container(
                          width: MediaQuery.of(context).size.width - 80,
                          height: 50,
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(15.0),
                              color: Colors.grey[200]),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(children: [
                              Text(
                                '$title: ',
                                style: textStyle4,
                              ),
                              Text(
                                '${userProvider.length}',
                                style: textStyle4,
                              ),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return SizedBox(
                                    height: constraints.maxHeight - 1,
                                    child: const VerticalDivider(
                                      color: Colors.black,
                                      thickness: 1.0,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(
                                width: _size!.width / 3,
                                height: 40,
                                child: Row(
                                  children: [
                                    const Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Zoom: ',
                                        style: textStyle4,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          enabledBorder:
                                              const OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              15.0)),
                                                  borderSide: BorderSide(
                                                      color: Colors.grey)),
                                          focusedBorder:
                                              const OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              15.0)),
                                                  borderSide: BorderSide(
                                                      color: Colors.green)),
                                        ),
                                        initialValue: _mapZoom.toString(),
                                        onChanged: (val) {
                                          if (val != null && val.isNotEmpty) {
                                            if (double.parse(val) >= 0) {
                                              setState(() {
                                                _mapZoom = double.parse(val);
                                              });
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
        widget.addProject! || widget.addMockup!
            ? Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.amber[200],
                      borderRadius: BorderRadius.circular(25)),
                  child: const Text(
                    'For adding a project, long press on the map location you want the project to be.',
                    style: textStyle5,
                    softWrap: true,
                    textAlign: TextAlign.center,
                  ),
                ))
            : const SizedBox.shrink(),
        _loading && !widget.addProject! && !widget.addMockup!
            ? SizedBox(
                height: _size!.height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Please wait...',
                      style: textStyle4,
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Center(
                      child: SpinKitSpinningLines(
                        color: Colors.black,
                        size: _size!.height / 5,
                        lineWidth: 6,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink()
      ],
    );
  }

  Widget _buildMarkersDrawer() {
    //THe following drawer will show the list of users or clients
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 186, 184, 152),
      width: _size!.width / 2,
      child: DefaultTabController(
        initialIndex: _prefTab,
        length: 2,
        child: Padding(
          padding: EdgeInsets.only(top: _size!.height / 15, right: 10),
          child: Column(
            children: [
              SizedBox(
                child: TabBar(
                    onTap: ((value) async {
                      _preferredTab = await SharedPreferences.getInstance();
                      _prefTab = value;
                      _preferredTab!.setInt('tab', value);
                    }),
                    labelStyle: textStyle5,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white,
                    indicatorColor: Colors.black,
                    tabs: const [
                      Tab(
                        text: 'Users',
                      ),
                      Tab(
                        text: 'Clients',
                      ),
                    ]),
              ),
              SizedBox(
                height: _size!.height - 100,
                child: TabBarView(children: [
                  StatefulBuilder(builder: (context, setState) {
                    return SizedBox(
                      height: _size!.height - 100,
                      child: ListView.builder(
                          itemCount: userProvider.length,
                          itemBuilder: (context, index) {
                            String? locationStatus;
                            bool _locationFailed = false;
                            var result;
                            result = db.getAllUsersLocation(
                                userId: userProvider[index].uid);
                            //check if location collection exist or not

                            if (userProvider[index].permissionStatus != null &&
                                    userProvider[index].permissionStatus ==
                                        'PermissionStatus.denied' ||
                                userProvider[index].permissionStatus ==
                                    'PermissionStatus.limited' ||
                                userProvider[index].permissionStatus ==
                                    'PermissionStatus.restricted') {
                              locationStatus = 'disabled';
                            }
                            if (locationStatus == 'disabled') {
                              _locationFailed = true;
                            }

                            return Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: GestureDetector(
                                onTap: () async {
                                  var userLoc = await result.first;
                                  if (userLoc != null && userLoc.isNotEmpty) {
                                    setState(() {
                                      _center = LatLng(
                                          userLoc.first.coord.latitude,
                                          userLoc.first.coord.longitude);
                                    });
                                    _mapController!.animateCamera(
                                        CameraUpdate.newCameraPosition(
                                            CameraPosition(
                                                target: _center!,
                                                zoom: _mapZoom)));
                                    Navigator.pop(context);
                                  } else {
                                    locationStatus = 'No Collection';
                                    setState(() {
                                      _locationFailed = true;
                                    });
                                    if (locationStatus == 'No Collection') {
                                      _snackBarWidget.content =
                                          'Location not found';
                                      _snackBarWidget.showSnack();
                                      return;
                                    }
                                  }

                                  if (locationStatus == 'disabled') {
                                    _snackBarWidget.content =
                                        'Access has been denied';
                                    _snackBarWidget.showSnack();
                                    return;
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 15),
                                  decoration: BoxDecoration(
                                      color: _locationFailed
                                          ? const Color.fromARGB(
                                              255, 239, 57, 24)
                                          : const Color.fromARGB(
                                              255, 192, 144, 229),
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Text(
                                    '${userProvider[index].firstName} ${userProvider[index].lastName}',
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    style: textStyle13,
                                  ),
                                ),
                              ),
                            );
                          }),
                    );
                  }),
                  SizedBox(
                    height: _size!.height - 105,
                    child: clientProvider != null && clientProvider!.isNotEmpty
                        ? ListView.builder(
                            itemCount: clientProvider!.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      _center = LatLng(
                                          clientProvider![index]
                                              .clientAddress!['Lat'],
                                          clientProvider![index]
                                              .clientAddress!['Lng']);
                                    });
                                    _mapController!.animateCamera(
                                        CameraUpdate.newCameraPosition(
                                            CameraPosition(
                                                target: _center!,
                                                zoom: _mapZoom)));
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 15),
                                    decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 169, 236, 158),
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    child: Text(
                                      clientProvider![index].clientName!,
                                      textAlign: TextAlign.center,
                                      style: textStyle13,
                                    ),
                                  ),
                                ),
                              );
                            })
                        : SizedBox(
                            height: _size!.height - 105,
                            child: const Center(
                              child: Text('Please wait for list to load'),
                            ),
                          ),
                  )
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getLocationName(coordinates) async {
    await placemarkFromCoordinates(coordinates.latitude, coordinates.longitude)
        .catchError((err) {
      Sentry.captureException(err);
    }).then((value) {
      if (Platform.isIOS) {
        locationName = '${value[0]}';
      } else {
        locationName = '${value[4]}';
      }
    });
  }
}
