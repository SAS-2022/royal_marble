import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/location/.env.dart';
import 'package:royal_marble/location/direction_repo.dart';
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
    Key key,
    this.currentUser,
    this.listOfMarkers,
  }) : super(key: key);
  final UserData currentUser;
  final String listOfMarkers;
  @override
  _ShowMapState createState() => _ShowMapState();
}

class _ShowMapState extends State<ShowMap> {
  final _circleFormKey = GlobalKey<FormState>();
  SnackBarWidget _snackBarWidget = SnackBarWidget();
  var projectProvider;
  var userProvider;
  Directions _info;
  String title = '';
  var lat = 0.0, long = 0.0;
  var _getMyCurrentLocation;
  Set<Circle> _circules = HashSet<Circle>();
  var db = DatabaseService();
  // PickResult selectedPlace;
  String apiKey;
  LatLng _center;
  final _elevation = 3.0;
  List<Marker> listMarkers = [];
  List<Marker> noMarkers = [];
  String clientSector;
  Future assignedMarkers;
  Size _size;
  int _circleIdCounter = 0;
  double radius = 1200;
  LatLng _selectedLocation;
  String locationName;

  // var markerId = MarkerId('one');
  Marker marker1 = Marker(
      markerId: const MarkerId('No clients were loaded'),
      position: const LatLng(26.3650133, 50.19190929999999),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow));

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.currentUser.homeAddress['Lat'],
        widget.currentUser.homeAddress['Lng']);
    _identifyMapMarkers();
    _getApiKey();
    noMarkers.add(marker1);
    _getMyCurrentLocation = _determinePosition();
    _snackBarWidget.context = context;
  }

  Future<void> _identifyMapMarkers() async {
    switch (widget.listOfMarkers) {
      case 'users':
        title = 'Users';
        break;
      case 'clients':
        assignedMarkers = _getClientMarker();
        title = 'Clients';
        break;

      case 'projects':
        await _getProjectMarker();
        title = 'Projects';
        break;
    }
  }

  Future<List<Marker>> _getUserMarker() async {
    listMarkers.clear();
    if (widget.currentUser.roles.contains('isAdmin')) {
      for (var user in userProvider) {
        if (user.currentLocation != null) {
          listMarkers.add(
            Marker(
              markerId: MarkerId(user.firstName),
              position: LatLng(
                  user.currentLocation['Lat'], user.currentLocation['Lng']),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange),
              infoWindow: InfoWindow(
                  title: '${user.firstName} ${user.lastName}',
                  snippet: user.phoneNumber,
                  onTap: () {}),
            ),
          );
        }
      }
    }
    return listMarkers;
  }

  Future<List<Marker>> _getProjectMarker() async {}

  //Function will get the client markers assign by each sales depending on their previlage
  Future<List<Marker>> _getClientMarker() async {
    listMarkers.clear();
    if (widget.currentUser.roles.contains('isAdmin')) {
      var currentClients = await db.getClientFuture();
      if (currentClients.isNotEmpty) {
        for (var client in currentClients) {
          listMarkers.add(
            Marker(
              markerId: MarkerId(client.clientName),
              position: LatLng(
                  client.clientAddress['Lat'], client.clientAddress['Lng']),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange),
              infoWindow: InfoWindow(
                  title: client.clientName,
                  snippet: client.phoneNumber,
                  onTap: () {}),
            ),
          );
        }
      }
    }
    if (widget.currentUser.roles.contains('isSales')) {
      var currentClients =
          await db.getSalesUserClientFuture(userId: widget.currentUser.uid);
      if (currentClients.isNotEmpty) {
        for (var client in currentClients) {
          listMarkers.add(
            Marker(
              markerId: MarkerId(client.clientName),
              position: LatLng(
                  client.clientAddress['Lat'], client.clientAddress['Lng']),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange),
              infoWindow: InfoWindow(
                  title: client.clientName,
                  snippet: client.phoneNumber,
                  onTap: () {}),
            ),
          );
        }
      }
    }
    return listMarkers;
  }

  //Get directions
  void _getDirections(LatLng destination) async {
    final directions = await DirectionRepository()
        .getDirections(origin: _center, destination: destination);
    setState(() {
      _info = directions;
    });
  }

  //create a circle to assign on the map
  void _setCirclesLocations() {
    _circules.clear();
    for (var project in projectProvider) {
      _circules.add(Circle(
          consumeTapEvents: true,
          onTap: () {
            _showDialog(
                title: project.projectName,
                content: project.projectDetails,
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

  Future<void> _getLocationName(coordinates) async {
    await placemarkFromCoordinates(coordinates.latitude, coordinates.longitude)
        .catchError((err) {
      print('Error obtaining location name: $err');
    }).then((value) {
      locationName = '${value[4]}';
    });
  }

  //Will open a small dialog to assign details for a certain location
  void assignCircleLocation(LatLng coordinates) async {
    ProjectData _projectData = ProjectData();
    double radius;
    List<double> availableRadius = [100, 200, 400, 600, 1000];

    showDialog(
        context: context,
        builder: (_) {
          _getLocationName(coordinates);

          return AlertDialog(
            title: const Text('Set Location Details'),
            content: Form(
              key: _circleFormKey,
              child: SizedBox(
                height: _size.height / 3,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: '',
                        style: textStyle3,
                        decoration: InputDecoration(
                          label: const Text('Project Name'),
                          hintText: 'Ex: Mr. X Villa',
                          filled: true,
                          fillColor: Colors.grey[100],
                          enabledBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0)),
                              borderSide: BorderSide(color: Colors.grey)),
                          focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0)),
                              borderSide: BorderSide(color: Colors.blue)),
                        ),
                        validator: (val) =>
                            val.isEmpty ? 'Project name cannot be empty' : null,
                        onChanged: (val) {
                          if (val.isNotEmpty) {
                            setState(() {
                              _projectData.projectName = val.trim();
                            });
                          }
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        initialValue: '',
                        style: textStyle3,
                        maxLines: 4,
                        decoration: InputDecoration(
                          label: const Text('Project Details'),
                          hintText:
                              'Ex: What is the project about and what will people be doing?',
                          filled: true,
                          fillColor: Colors.grey[100],
                          enabledBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0)),
                              borderSide: BorderSide(color: Colors.grey)),
                          focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0)),
                              borderSide: BorderSide(color: Colors.blue)),
                        ),
                        validator: (val) => val.isEmpty
                            ? 'Project details cannot be empty'
                            : null,
                        onChanged: (val) {
                          if (val.isNotEmpty) {
                            setState(() {
                              _projectData.projectDetails = val.trim();
                            });
                          }
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        alignment: Alignment.center,
                        height: 50.0,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<double>(
                            decoration:
                                const InputDecoration.collapsed(hintText: ''),
                            isExpanded: true,
                            value: radius,
                            hint: const Center(child: Text('Project Radius')),
                            onChanged: (val) {
                              setState(() {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                                radius = val;
                                _projectData.radius = radius;
                              });
                            },
                            validator: (val) =>
                                val == null ? 'Please select a radius' : null,
                            selectedItemBuilder: (BuildContext context) {
                              return availableRadius.map<Widget>((double rad) {
                                return Center(
                                  child: Text(
                                    rad.toString(),
                                    style: textStyle4,
                                  ),
                                );
                              }).toList();
                            },
                            items: availableRadius.map((double item) {
                              return DropdownMenuItem<double>(
                                value: item,
                                child: Text(item.toString()),
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(bottom: 35),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 56, 52, 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                      ),
                      onPressed: () async {
                        if (_circleFormKey.currentState.validate() &&
                            radius != null) {
                          //add a project marker with project details
                          if (_projectData != null) {
                            _projectData.projectAddress = {
                              'addressName': locationName,
                              'Lat': coordinates.latitude,
                              'Lng': coordinates.longitude,
                            };

                            var result =
                                await db.addNewProject(project: _projectData);
                            Navigator.pop(context);
                            if (result != null) {
                              _snackBarWidget.content =
                                  'Project Addition: $result';
                              _snackBarWidget.showSnack();
                            }
                          }
                        }
                      },
                      child: const Text('Assign'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 56, 52, 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }

  //Client details dialog
  // ignore: missing_return
  Widget _openDetailsDialog(
      String clientName, String clientId, List<dynamic> visitList) {
    visitList = visitList.reversed.toList();
    showDialog(
        context: context,
        builder: (builder) {
          return AlertDialog(
            title: Text(
              clientName,
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              height: _size.height * 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Visit List: ${visitList.length}',
                      style: textStyle4,
                    ),
                  ),
                  SizedBox(
                    height: _size.height * 0.2,
                    width: _size.width * 0.6,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: visitList.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {},
                          child: Card(
                            elevation: _elevation,
                          ),
                        );
                      },
                    ),
                  ),

                  //Will build the list of quotes for each client allowing you to view the quote from here
                  Container(),
                ],
              ),
            ),
          );
        });
  }

  void _showDialog({String title, String content, ProjectData projectData}) {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              //Delete the project
              projectData != null
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
                            if (projectData.uid != null) {
                              await db.deleteProject(
                                  projectId: projectData.uid);
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
    return currentLocation;
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    projectProvider = Provider.of<List<ProjectData>>(context);
    userProvider = Provider.of<List<UserData>>(context);
    //Assign project proivder to circules
    if (projectProvider != null && projectProvider.isNotEmpty) {
      _setCirclesLocations();
    }
    if (widget.listOfMarkers == 'users' &&
        userProvider != null &&
        userProvider.isNotEmpty) {
      _getUserMarker();
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

  Widget _buildLocationSelection() {
    return SizedBox(
        height: _size.height,
        width: _size.width,
        child: Stack(children: [
          userProvider != null
              ? GoogleMap(
                  onLongPress: (coordinates) async {
                    //assing circule
                    if (coordinates != null) {
                      var betterName = '';
                      await _getLocationName(coordinates);
                      locationName.replaceAll(' ', '');
                      var theName = locationName.split('\n');
                      for (var i = 0; i < 7; i++) {
                        betterName += theName[i].trimLeft();
                      }

                      var projectLocation = {
                        'Lat': coordinates.latitude,
                        'Lng': coordinates.longitude,
                        'addressName': betterName
                      };

                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) {
                        return ProjectForm(
                          projectLocation: projectLocation,
                          isNewProject: true,
                        );
                      }));
                    }
                  },
                  onTap: (coordinates) {
                    _selectedLocation = coordinates;
                  },
                  circles: _circules,
                  mapToolbarEnabled: true,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: false,
                  polylines: {
                    if (_info != null)
                      Polyline(
                        polylineId: const PolylineId('overview_polyline'),
                        color: Colors.red,
                        width: 5,
                        points: _info.polylinePoints
                            .map((e) => LatLng(e.latitude, e.longitude))
                            .toList(),
                      )
                  },
                  initialCameraPosition:
                      CameraPosition(target: _center, zoom: 12.0),
                  markers: listMarkers.isNotEmpty
                      ? Set.of(listMarkers)
                      : Set.of(noMarkers),
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
                  '${_info.totalDistance}, ${_info.totalDuration}',
                  style: const TextStyle(
                      fontSize: 18.0, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 25.0, 0, 0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: _elevation,
              child: Container(
                width: MediaQuery.of(context).size.width - 100,
                height: 50,
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(15.0),
                    color: Colors.grey[200]),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(children: [
                    Text(
                      '$title: ',
                      style: textStyle4,
                    ),
                    Text(
                      '${listMarkers.length}',
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
                    Text(clientSector ?? 'All', style: textStyle4),
                  ]),
                ),
              ),
            ),
          ),
        ]));
  }
}
