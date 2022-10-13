import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

class BackGroundDetector {
  void detectMotion() {
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      print('The Current Location: $location');
    });

    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      print('When Motion: $location');
    });

    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      print('providerChange - $event');
    });
    print('we are here');

    bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 10.0,
      stopOnTerminate: false,
      startOnBoot: true,
      debug: true,
      logLevel: bg.Config.LOG_LEVEL_VERBOSE,
    )).then((bg.State state) {
      if (!state.enabled) {
        bg.BackgroundGeolocation.start();
      }
    });
  }
}
