import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/directions.dart';
import '../shared/loading.dart';
import 'direction_repo.dart';

class GoogleMapNavigation extends StatefulWidget {
  const GoogleMapNavigation(
      {Key key, this.lat, this.lng, this.getLocation, this.navigate})
      : super(key: key);
  final double lat;
  final double lng;
  final bool navigate;
  final Function getLocation;

  @override
  State<GoogleMapNavigation> createState() => _GoogleMapNavigationState();
}

class _GoogleMapNavigationState extends State<GoogleMapNavigation> {
  var lat = 0.0, long = 0.0;
  LatLng _center;
  LatLng _selectedLatLng;
  String _selecteLocation;
  bool _loading = true;
  Directions _info;
  GoogleMapController _googleMapController;
  CameraPosition _cameraPosition;
  Marker _myLocation;
  Marker _myDestination;
  List<Marker> listMarkers = [];
  List<Marker> noMarkers = const [
    Marker(markerId: MarkerId('No Marker'), position: LatLng(0, 0))
  ];
  Future _addAllMarkers;
  Future currentPosition;
  final _cameraZoom = 16.0;
  final _snackBarWidget = SnackBarWidget();
  Future addMarker;
  Size _size;

  @override
  void initState() {
    super.initState();
    currentPosition = _determinePosition();
  }

  @override
  void dispose() {
    super.dispose();
    if (_googleMapController != null) {
      _googleMapController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      body: FutureBuilder<dynamic>(
          future: currentPosition,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return widget.lat == null && widget.lng == null
                  ? _openGoogleMap(
                      lat: snapshot.data.latitude, lng: snapshot.data.longitude)
                  : _openGoogleMap(lat: widget.lat, lng: widget.lng);
            } else {
              return const Center(
                child: Text('Please wait...'),
              );
            }
          }),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'navigate',
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              child: const Icon(Icons.navigate_next_sharp),
              onPressed: () =>
                  _startNaviagtionGoogleMap(lat: widget.lat, lng: widget.lng),
            ),
          ],
        ),
      ),
    );
  }

  Widget _openGoogleMap({var lat, var lng}) {
    return FutureBuilder<dynamic>(
        future: addMarker,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SafeArea(
              child: !widget.navigate
                  ? Stack(
                      children: [
                        lat != null && lng != null
                            ? GoogleMap(
                                zoomGesturesEnabled: true,
                                zoomControlsEnabled: false,
                                myLocationButtonEnabled: false,
                                onMapCreated: (controller) {
                                  setState(() {
                                    _googleMapController = controller;
                                  });
                                },
                                onCameraMove: ((CameraPosition cameraPosition) {
                                  _cameraPosition = cameraPosition;
                                }),
                                onCameraIdle: () async {
                                  List<Placemark> placeMarks =
                                      await placemarkFromCoordinates(
                                          _cameraPosition.target.latitude,
                                          _cameraPosition.target.longitude);

                                  if (mounted) {
                                    setState(() {
                                      _selectedLatLng = LatLng(
                                          _cameraPosition.target.latitude,
                                          _cameraPosition.target.longitude);

                                      _selecteLocation = placeMarks
                                              .first.administrativeArea
                                              .toString() +
                                          ' ' +
                                          placeMarks.first.street.toString();
                                    });
                                  }
                                },
                                initialCameraPosition: CameraPosition(
                                    target: LatLng(lat, lng),
                                    zoom: _cameraZoom),
                                mapType: MapType.normal,
                              )
                            : const Loading(),
                        //Add market to show the location
                        Center(
                          child: Image.asset(
                            'assets/images/location_picker_2.jpg',
                            height: 35,
                          ),
                        ),
                        _selecteLocation != null
                            ? Positioned(
                                top: 20,
                                left: 30,
                                right: 30,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 12),
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
                                    _selecteLocation,
                                    style: const TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        !widget.navigate
                            ? _selecteLocation != null
                                ? Positioned(
                                    bottom: 30,
                                    left: 10,
                                    child: Container(
                                      width: _size.width / 2,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 12),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[400],
                                            fixedSize:
                                                Size(_size.width / 2, 45),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25))),
                                        onPressed: () async {
                                          if (_selecteLocation != null &&
                                              _selectedLatLng != null) {
                                            widget.getLocation(
                                                locationName: _selecteLocation,
                                                locationAddress:
                                                    _selectedLatLng);
                                          }
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                          'Select Position',
                                          style: buttonStyle,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink()
                            : const SizedBox.shrink(),
                      ],
                    )
                  :
                  //incase we are navigating
                  Stack(
                      children: [
                        GoogleMap(
                          polylines: {
                            if (_info != null)
                              Polyline(
                                  polylineId:
                                      const PolylineId('overview_polyline'),
                                  color: Colors.blue,
                                  width: 6,
                                  points: _info.polylinePoints
                                      .map((e) =>
                                          LatLng(e.latitude, e.longitude))
                                      .toList())
                          },
                          zoomGesturesEnabled: true,
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          onMapCreated: (controller) {
                            setState(() {
                              _googleMapController = controller;
                            });
                          },
                          initialCameraPosition: CameraPosition(
                              target: LatLng(lat, lng), zoom: _cameraZoom),
                          mapType: MapType.normal,
                        )
                      ],
                    ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return const Center(
              child: Loading(),
            );
          }
        });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    Position currentLocation;
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

    currentLocation =
        await Geolocator.getCurrentPosition().onError((error, stackTrace) {
      return Position(
          longitude: 0,
          latitude: 0,
          timestamp: DateTime.now(),
          accuracy: 1,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0);
    }).whenComplete(() => print('Location determining has been completed'));

    //currentLocation = Position(latitude: widget.lat, longitude: widget.lng);

    setState(() {
      lat = currentLocation.latitude;
      long = currentLocation.longitude;
    });

    _center = LatLng(lat, long);
    _cameraPosition = CameraPosition(target: _center);
    addMarker = _addMarker(
        currentLat: currentLocation.latitude,
        currentLng: currentLocation.longitude);

    return currentLocation;
  }

  //Get directions
  Future<Directions> _getDirections({LatLng origin, LatLng destination}) async {
    var result = await DirectionRepository()
        .getDirections(origin: _center, destination: destination);

    return result;
  }

  //Add the current location and destination markers
  Future<Marker> _addMarker({
    var currentLat,
    var currentLng,
  }) async {
    _myLocation ??= Marker(
      markerId: const MarkerId('Origin'),
      infoWindow: const InfoWindow(title: 'Selected Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      position: LatLng(currentLat, currentLng),
    );

    setState(() {
      _loading = false;
    });
    if (widget.navigate) {
      _info = await _getDirections(
          origin: LatLng(currentLat, currentLng),
          destination: LatLng(widget.lat, widget.lng));
    }

    // print('the info: $_info');

    if (_info != null) {
      await _adjustCamera(_info.northE, _info.southW);
    }

    return _myLocation;
  }

  Future<void> _adjustCamera(var ne, var sw) async {
    Future.delayed(
        const Duration(milliseconds: 650),
        () async => await _googleMapController.animateCamera(
              CameraUpdate.newLatLngBounds(
                  LatLngBounds(southwest: sw, northeast: ne), 100),
            ));
  }

  //open google map
  Future<void> _startNaviagtionGoogleMap({var lat, var lng}) async {
    _snackBarWidget.context = context;
    var uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    var iosUri = 'comgooglemaps://?q=$lat,$lng&zoom=14';
    if (Platform.isAndroid) {
      await launchUrl(uri).onError((error, stackTrace) {
        _snackBarWidget.content = 'Error: $error';
        _snackBarWidget.showSnack();
        return false;
      }).then((value) {
        _snackBarWidget.content = 'Launching google maps. Please wait';
        _snackBarWidget.showSnack();
      });
    } else {
      if (await canLaunch('comgooglemaps://')) {
        await launch(iosUri.toString(), forceSafariVC: false)
            .onError((error, stackTrace) {
          _snackBarWidget.content = 'Error: $error';
          _snackBarWidget.showSnack();
          return false;
        }).then((value) {
          _snackBarWidget.content = 'Launching google maps. Please wait';
          _snackBarWidget.showSnack();
        });
      } else {
        _snackBarWidget.content =
            'Cannot launch google maps, check if app is installed';
        _snackBarWidget.showSnack();
      }
    }
  }
}
