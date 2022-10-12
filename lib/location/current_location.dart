import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:royal_marble/models/user_model.dart';

class UserTracking extends StatefulWidget {
  const UserTracking({Key key, this.currentUser}) : super(key: key);
  final UserData currentUser;

  @override
  State<UserTracking> createState() => _UserTrackingState();
}

class _UserTrackingState extends State<UserTracking> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

class UpdateLocation {
  final Completer<GoogleMapController> _googleMapController = Completer();
  LocationData currentLocation;

  void getCurrentLocation() async {
    Location _location = Location();

    _location.getLocation().then((location) => currentLocation = location);

    GoogleMapController googleMapController = await _googleMapController.future;

    _location.onLocationChanged.listen(
      (newLoc) {
        currentLocation = newLoc;

        googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              zoom: 13,
              target: LatLng(newLoc.latitude, newLoc.longitude),
            ),
          ),
        );
      },
    );
  }
}
