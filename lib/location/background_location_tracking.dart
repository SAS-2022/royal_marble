import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:royal_marble/location/.env.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:http/http.dart' as http;

import '../geolocation/event_list.dart';
import '../geolocation/map_view.dart';
import '../geolocation/shared_events.dart';

class LiveView extends StatefulWidget {
  const LiveView({Key key, this.userData, this.allUsers}) : super(key: key);
  final UserData userData;
  final List<UserData> allUsers;
  @override
  State<LiveView> createState() => _LiveViewState();
}

JsonEncoder encoder = const JsonEncoder.withIndent("    ");

class _LiveViewState extends State<LiveView>
    with TickerProviderStateMixin<LiveView>, WidgetsBindingObserver {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  TabController _tabController;

  bool _isMoving;
  bool _enabled;
  String _motionActivity;
  String _odometer;

  DateTime _lastRequestedTemporaryFullAccuracy;

  /// My private test mode.  IGNORE.
  int _testModeClicks;
  Timer _testModeTimer;
  List<Event> events = [];
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _isMoving = false;
    _enabled = false;
    _motionActivity = 'UNKNOWN';
    _odometer = '0';
    _testModeClicks = 0;

    _tabController = TabController(length: 2, initialIndex: 0, vsync: this);
    _tabController.addListener(_handleTabChange);

    initPlatformState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("[home_view didChangeAppLifecycleState] : $state");
    if (state == AppLifecycleState.paused) {
      // Do nothing.
      /* For testing location access in background on Android 12.
      new Timer(Duration(seconds: 21), () async {
        var location = await bg.BackgroundGeolocation.getCurrentPosition();
        print("************ [location] $location");
      });
      */

    } else if (state == AppLifecycleState.resumed) {
      if (!_enabled) return;

      DateTime now = DateTime.now();
      if (_lastRequestedTemporaryFullAccuracy != null) {
        Duration dt = _lastRequestedTemporaryFullAccuracy.difference(now);
        if (dt.inSeconds < 10) return;
      }
      _lastRequestedTemporaryFullAccuracy = now;
      bg.BackgroundGeolocation.requestTemporaryFullAccuracy("DemoPurpose");
    }
  }

  void initPlatformState() async {
    if (widget.userData != null) {
      _configureBackgroundGeolocation(widget.allUsers);
      _configureBackgroundFetch();
    }
  }

  void _configureBackgroundGeolocation(List<UserData> allUsers) async {
    bg.BackgroundGeolocation.onLocation(_onLocation, _onLocationError);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
    bg.BackgroundGeolocation.onGeofence(_onGeofence);

    bg.BackgroundGeolocation.ready(bg.Config(
            reset:
                false, // <-- lets the Settings screen drive the config rather than re-applying each boot.

            // Logging & Debug
            debug: true,
            logLevel: bg.Config.LOG_LEVEL_VERBOSE,
            // Geolocation options
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_NAVIGATION,
            distanceFilter: 10.0,
            // Activity recognition options
            stopTimeout: 5,
            backgroundPermissionRationale: bg.PermissionRationale(
                title:
                    "Allow {applicationName} to access this device's location even when the app is closed or not in use.",
                message:
                    "This app collects location data to enable recording your trips to work and calculate distance-travelled.",
                positiveAction: 'Change to "{backgroundPermissionOptionLabel}"',
                negativeAction: 'Cancel'),
            // HTTP & Persistence
            autoSync: true,
            // Application options
            stopOnTerminate: false,
            startOnBoot: true,
            enableHeadless: true,
            heartbeatInterval: 60))
        .then((bg.State state) async {
      print('[ready] ${state.toMap()}');
      print('[didDeviceReboot] ${state.didDeviceReboot}');

      if (state.schedule.isNotEmpty) {
        bg.BackgroundGeolocation.startSchedule();
      }
      setState(() {
        _enabled = state.enabled;
        _isMoving = state.isMoving;
      });
    }).catchError((error) {
      print('[ready] ERROR: $error');
    });
  }

  void _configureBackgroundFetch() async {
    BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 10,
            startOnBoot: true,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresStorageNotLow: false,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE), (String taskId) async {
      print("[BackgroundFetch] received event $taskId");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      int count = 0;
      if (prefs.get("fetch-count") != null) {
        count = prefs.getInt("fetch-count");
      }
      prefs.setInt("fetch-count", ++count);
      print('[BackgroundFetch] count: $count');

      if (taskId == 'flutter_background_fetch') {
        try {
          // Fetch current position
          var location = await bg.BackgroundGeolocation.getCurrentPosition(
              samples: 1,
              extras: {"event": "background-fetch", "headless": false});
          print("[location] $location");
        } catch (error) {
          print("[location] ERROR: $error");
        }

        // Test scheduling a custom-task in fetch event.
        BackgroundFetch.scheduleTask(TaskConfig(
            taskId: "com.transistorsoft.customtask",
            delay: 5000,
            periodic: false,
            forceAlarmManager: true,
            stopOnTerminate: false,
            enableHeadless: true));
      }
      BackgroundFetch.finish(taskId);
    });
  }

  void _onLocation(bg.Location location) {
    print('[${bg.Event.LOCATION}] - $location');

    setState(() {
      events.insert(0,
          Event(bg.Event.LOCATION, location, location.toString(compact: true)));
      _odometer = (location.odometer / 1000.0).toStringAsFixed(1);
    });
  }

  void _onLocationError(bg.LocationError error) {
    print('[${bg.Event.LOCATION}] ERROR - $error');
    setState(() {
      events.insert(
          0, Event(bg.Event.LOCATION + " error", error, error.toString()));
    });
  }

  void _onMotionChange(bg.Location location) {
    print('[${bg.Event.MOTIONCHANGE}] - $location');

    setState(() {
      events.insert(
          0,
          Event(bg.Event.MOTIONCHANGE, location,
              location.toString(compact: true)));
      _isMoving = location.isMoving;
    });
  }

  void _onGeofence(bg.GeofenceEvent event) async {
    print('[${bg.Event.GEOFENCE}] - $event');

    bg.BackgroundGeolocation.startBackgroundTask().then((int taskId) async {
      // Execute an HTTP request to test an async operation completes.
      String url = "${ENV.TRACKER_HOST}/api/devices";
      bg.State state = await bg.BackgroundGeolocation.state;
      http.read(Uri.parse(url), headers: {
        "Authorization": "Bearer ${state.authorization.accessToken}"
      }).then((String result) {
        print("[http test] success: $result");

        bg.BackgroundGeolocation.stopBackgroundTask(taskId);
      }).catchError((dynamic error) {
        print("[http test] failed: $error");
        bg.BackgroundGeolocation.stopBackgroundTask(taskId);
      });
    });

    setState(() {
      events.insert(
          0, Event(bg.Event.GEOFENCE, event, event.toString(compact: false)));
    });
  }

  void _onClickTestMode() {
    _testModeClicks++;

    if (_testModeTimer != null) {
      _testModeTimer.cancel();
    }
    _testModeTimer = new Timer(Duration(seconds: 2), () {
      _testModeClicks = 0;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();

    bg.BackgroundGeolocation.setOdometer(0.0).catchError((error) {
      print('************ dispose [setOdometer] ERROR $error');
    });
  }

  void _handleTabChange() async {
    if (!_tabController.indexIsChanging) {
      return;
    }
    final SharedPreferences prefs = await _prefs;
    prefs.setInt("tabIndex", _tabController.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BG Geo'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          tabs: const [Tab(icon: Icon(Icons.map)), Tab(icon: Icon(Icons.list))],
        ),
      ),
      //body: body,
      body: SharedEvents(
          events: events,
          child: TabBarView(
              controller: _tabController,
              children: [
                MapView(
                  currentUser: widget.userData,
                ),
                EventList()
              ],
              physics: const NeverScrollableScrollPhysics())),
      bottomNavigationBar: BottomAppBar(
          child: Container(
              padding: const EdgeInsets.only(left: 5.0, right: 5.0),
              child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TextButton(
                        child: Text('$_motionActivity · $_odometer km'),
                        onPressed: _onClickTestMode,
                        style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all<Color>(
                                Colors.black))),
                  ]))),
    );
  }
}
