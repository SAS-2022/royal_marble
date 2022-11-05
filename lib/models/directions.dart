import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Directions {
  Directions(this.bounds, this.polylinePoints, this.totalDistance,
      this.totalDuration, this.northE, this.southW);

  final LatLngBounds bounds;
  final List<PointLatLng> polylinePoints;
  final String totalDistance;
  final String totalDuration;
  final LatLng northE;
  final LatLng southW;

  factory Directions.fromMap(Map<String, dynamic> map) {
    if ((map['routes'] as List).isEmpty) {}

    //get route information
    final data = Map<String, dynamic>.from(map['routes'][0]);

    //bounds
    final northEast = data['bounds']['northeast'];
    final southWest = data['bounds']['southwest'];
    final bounds = LatLngBounds(
      northeast: LatLng(northEast['lat'], northEast['lng']),
      southwest: LatLng(
        southWest['lat'],
        southWest['lng'],
      ),
    );

    //get distance and duration
    String distance = '';
    String duration = '';

    if ((data['legs'] as List).isNotEmpty) {
      final leg = data['legs'][0];
      distance = leg['distance']['text'];
      duration = leg['duration']['text'];
    }

    return Directions(
        bounds,
        PolylinePoints().decodePolyline(data['overview_polyline']['points']),
        distance,
        duration,
        LatLng(northEast['lat'], northEast['lng']),
        LatLng(
          southWest['lat'],
          southWest['lng'],
        ));
  }
}

class CustomMarker {
  String id;
  LatLng coord;
  CustomMarker({
    this.id,
    this.coord,
  });

  @override
  String toString() => 'CustomMarker(id: $id, coord: $coord)';
}
