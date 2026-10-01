import 'dart:io' show Platform;

/// Build-time configuration, supplied with
/// `flutter run --dart-define-from-file=config/env.json`.
/// Copy `config/env.example.json` to `config/env.json` and fill it in.
class Env {
  static const _mapsAndroid = String.fromEnvironment('MAPS_API_KEY_ANDROID');
  static const _mapsIos = String.fromEnvironment('MAPS_API_KEY_IOS');
  static const trackerHost = String.fromEnvironment('TRACKER_HOST');

  /// Google Maps Platform key for web-service calls (Directions) on this platform.
  static String get mapsApiKey => Platform.isIOS ? _mapsIos : _mapsAndroid;
}
