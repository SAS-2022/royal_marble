import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:royal_marble/location/.env.dart';

import '../models/directions.dart';

class DirectionRepository {
  DirectionRepository({Dio dio}) : _dio = dio ?? Dio();
  final Dio _dio;
  static const String baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json?';

  Future<Directions> getDirections({LatLng origin, LatLng destination}) async {
    final response = await _dio.get(baseUrl, queryParameters: {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'key': googleAPIKey,
    });
    print('response: ${response.data}');
    if (response.statusCode == 200) {
      return Directions.fromMap(response.data);
    } else {
      return Directions.fromMap({'error': 'null'});
    }
  }
}
