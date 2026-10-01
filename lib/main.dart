import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:provider/provider.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/error_reporter.dart';
import 'package:royal_marble/services/auth.dart';
import 'package:royal_marble/services/tracking_service.dart';
import 'package:royal_marble/wrapper.dart';

import 'models/user_model.dart';

/// Runs when Android delivers tracking events with the app closed or after a
/// reboot. Shares its handling with the foreground app.
@pragma('vm:entry-point')
void backgroundGeolocationHeadlessTask(bg.HeadlessEvent headlessEvent) async {
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  await TrackingService.handleEvent(headlessEvent.name, headlessEvent.event);
}

/// Debug builds don't send reports unless run with
/// `--dart-define=CRASHLYTICS_DEBUG=true` (used to verify the setup).
const _crashlyticsInDebug = bool.fromEnvironment('CRASHLYTICS_DEBUG');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics
      .setCrashlyticsCollectionEnabled(!kDebugMode || _crashlyticsInDebug);
  // Framework errors (build/layout/paint) and uncaught async errors.
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };

  // `--dart-define=CRASHLYTICS_TEST=true` sends one test report on launch.
  if (const bool.fromEnvironment('CRASHLYTICS_TEST')) {
    ErrorReporter.message('Crashlytics test report from a debug build');
  }

  bg.BackgroundGeolocation.registerHeadlessTask(
      backgroundGeolocationHeadlessTask);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserData?>.value(
      value: AuthService().user,
      initialData: UserData(),
      catchError: (context, err) => UserData(error: err.toString()),
      child: MaterialApp(
        title: 'Royal Marble',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routes: <String, WidgetBuilder>{'/home': (context) => const Wrapper()},
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          settings: const RouteSettings(name: '/home'),
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const Wrapper(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.scale(scale: 0.92 + 0.08 * v, child: child),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('assets/images/logo_2.jpg', width: 220),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.gold),
            ),
          ]),
        ),
      ),
    );
  }
}
