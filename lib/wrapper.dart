import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:royal_marble/auth/register.dart';
import 'package:royal_marble/auth/sign_in.dart';
import 'package:royal_marble/core/error_reporter.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/core/roles.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/services/push_service.dart';
import 'package:royal_marble/shared/loading.dart';
import 'package:royal_marble/widgets/checkin_card.dart';

import 'home.dart';
import 'models/user_model.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserData?>(context);
    if (auth == null || auth.uid == null) return const SignInScreen();

    final db = DatabaseService();
    return StreamBuilder<UserData?>(
      stream: db.watchUser(auth.uid!),
      builder: (context, snap) {
        if (snap.hasError || snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: Loading()));
        }
        final user = snap.data;
        if (user == null) {
          // Signed in with Google/Apple for the first time: no profile yet.
          final firebaseUser = FirebaseAuth.instance.currentUser;
          return firebaseUser == null
              ? const Scaffold(body: Center(child: Loading()))
              : RegisterScreen(
                  key: ValueKey(firebaseUser.uid), socialUser: firebaseUser);
        }
        final role = primaryRole(user.roles);
        ErrorReporter.setUser(uid: user.uid, role: role.name);
        context.read<LocaleController>().adoptFromProfile(user.language);
        PushService.start(user);
        // Only people who manage others need everyone's profiles; workers
        // get just their own data.
        final seesTeam = role != AppRole.worker && role != AppRole.siteEngineer;

        return MultiProvider(
          key: ValueKey('${user.uid}|${role.name}'),
          providers: [
            Provider<UserData?>.value(value: user),
            StreamProvider<List<ProjectData>>.value(
              value: seesTeam ? db.getAllProjects() : Stream.value(const []),
              initialData: const [],
              catchError: (context, err) => const [],
            ),
            StreamProvider<List<MockupData>>.value(
              value: seesTeam ? db.getAllMockups() : Stream.value(const []),
              initialData: const [],
              catchError: (context, err) => const [],
            ),
            StreamProvider<List<UserData>>.value(
              value: seesTeam ? db.getAllUsers() : Stream.value(const []),
              initialData: const [],
              catchError: (context, err) => const [],
            ),
            StreamProvider<Map<String, dynamic>>.value(
              value: seesTeam
                  ? db.getTimeSheetData(uid: timesheetDayId())
                  : Stream.value(const {}),
              initialData: const {},
              catchError: (context, err) => const {},
            ),
          ],
          child: HomeScreen(currentUser: user),
        );
      },
    );
  }
}
