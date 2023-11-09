import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_place_picker/google_maps_place_picker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../services/database.dart';

class LocationInsertion extends StatefulWidget {
  const LocationInsertion(
      {Key? key,
      this.customerLocation,
      this.customerId,
      this.userId,
      this.visitPurpose,
      this.contactName,
      this.clientName,
      this.projectId,
      this.showroomAddress})
      : super(key: key);
  final String? customerLocation;
  final String? customerId;
  final String? userId;
  final String? visitPurpose;
  final String? contactName;
  final String? clientName;
  final String? projectId;
  final bool? showroomAddress;

  @override
  _LocationInsertionState createState() => _LocationInsertionState();
}

class _LocationInsertionState extends State<LocationInsertion> {
  final _formKey = GlobalKey<FormState>();
  GoogleMapController? _mapController;
  var lat = 0.0, long = 0.0;
  var _getMyCurrentLocation;
  // PickResult selectedPlace;
  String? apiKey;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (widget.showroomAddress != null && widget.showroomAddress!) {
          Navigator.pop(context);
          return Future(() => true);
        } else {
          Navigator.pop(context);
          return Future(() => true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Location'),
          backgroundColor: Colors.blueGrey,
        ),
        body: _buildLocationSelection(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getApiKey();
    _getMyCurrentLocation = _determinePosition();
  }

  //Will determine api key for ios and android
  void _getApiKey() {
    if (Platform.isAndroid) {
      apiKey = 'AIzaSyCt_85xyi17R7CH21UssFrwJS0uehlmaFQ';
    } else {
      apiKey = 'AIzaSyDZ9q7SmS1El658-kOsQdCnzPZokcsa-FA';
    }
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
    lat = currentLocation.latitude;
    long = currentLocation.longitude;
    return currentLocation;
  }

  LatLng? _center;
  // void _onMapCreated(GoogleMapController controller) {
  //   _mapController = controller;
  // }

  //This widget will build the location selection for each client or will display the location for existing ones
  Widget _buildLocationSelection() {
    _center = LatLng(lat, long);

    return FutureBuilder(
      future: _getMyCurrentLocation,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              height: MediaQuery.of(context).size.height - 50,
              child: Column(
                children: [
                  Expanded(child: Container()),
                ],
              ),
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  //Save customer location
  Future _saveNewLocation() async {
    if (widget.customerLocation != null) {
      return showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Change Address'),
              content: const Text(
                  'Are you sure you want to change the client address to this new one?'),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _saveClientAddress();
                  },
                  child: const Text('Yes'),
                ),
                TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                    },
                    child: const Text('No'))
              ],
            );
          });
    } else {
      //Add customer location
      await _saveClientAddress();
    }
  }

  //Save the client address
  Future _saveClientAddress() async {
    var db = DatabaseService();
    var result;
    try {
      if (result != null) {
        print('the location has been updated');
      } else {
        print('Unable to update location');
      }
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }
}
