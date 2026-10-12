import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'emulators.dart';

/// Firebase settings for the admin web dashboard. Phones read theirs from
/// `google-services.json` / `GoogleService-Info.plist`; the browser needs them
/// passed in. Values come from `config/env.json` (git-ignored):
/// `WEB_API_KEY` and `WEB_APP_ID` from the Firebase console (Project settings →
/// Your apps → the web app). Against the emulators any placeholder works.
FirebaseOptions get webFirebaseOptions => FirebaseOptions(
      apiKey: _apiKey.isNotEmpty || !useEmulator ? _apiKey : 'emulator',
      appId: _appId.isNotEmpty || !useEmulator
          ? _appId
          : '1:420263984039:web:emulator',
      messagingSenderId: '420263984039',
      projectId: 'royal-marble',
      authDomain: 'royal-marble.firebaseapp.com',
      storageBucket: 'royal-marble.appspot.com',
    );

const _apiKey = String.fromEnvironment('WEB_API_KEY');
const _appId = String.fromEnvironment('WEB_APP_ID');

/// Browser key for Google Maps (Maps JavaScript API), restricted to the
/// dashboard's domain. Empty → maps show a placeholder.
const webMapsKey = String.fromEnvironment('MAPS_API_KEY_WEB');

/// Phones always have maps; the browser only once a web key is set.
bool get mapsAvailable => !kIsWeb || webMapsKey.isNotEmpty;
