import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Build with `--dart-define=USE_EMULATOR=true` to run against the local
/// Firebase Emulator Suite (`firebase emulators:start`) instead of production.
const useEmulator = bool.fromEnvironment('USE_EMULATOR');

/// Host of the Mac running the emulators, as seen from the device.
/// 10.0.2.2 is the Android emulator's alias for the host machine; pass
/// `--dart-define=EMULATOR_HOST=<mac LAN IP>` for a real phone.
const _host = String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');

bool _configured = false;

/// Points Auth, Firestore and Functions at the emulators. Must run right
/// after `Firebase.initializeApp()` in every isolate (app and headless task).
Future<void> configureEmulators() async {
  if (!useEmulator || _configured) return;
  _configured = true;
  await FirebaseAuth.instance.useAuthEmulator(_host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(_host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(_host, 5001);
}
