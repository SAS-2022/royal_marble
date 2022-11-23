import 'package:firebase_auth/firebase_auth.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:sentry/sentry.dart' as sentry;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserData currentUser;

  DatabaseService db = DatabaseService();
  var newUser;

  //create a user object based on Firebase user
  UserData _userFromFirebaseUser(User user) {
    return user != null ? UserData(uid: user.uid) : null;
  }

  //Verify user account
  Future<String> userFromFirebaseVerification(String emailAddress) async {
    var user = _auth.currentUser;
    try {
      await user.sendEmailVerification();
      return user.uid;
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return e.toString();
    }
  }

  //auth change user screen
  Stream<UserData> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  //sign in with user name and password
  Future signInWithUserNameandPassword(String email, String password) async {
    try {
      var result = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      var user = result.user.uid;
      if (user != null) {
        return user;
      } else {
        return null;
      }
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  //Sign in without requesting any credentials
  Future signInAnonymously() async {
    try {
      var result = await _auth.signInAnonymously();
      var user = result.user;
      if (user.uid != null) {
        return user.uid;
      } else {
        return null;
      }
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return e.toString();
    }
  }

  //register with email and password
  Future registerWithEmailandPassword(
      {String email,
      String password,
      String firstName,
      String lastName,
      String company,
      bool isActive,
      String phoneNumber,
      Map<String, dynamic> nationality,
      Map<String, dynamic> homeAddress,
      String imageUrl,
      List<String> roles}) async {
    try {
      var result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      var user = result.user;
      if (user != null) {
        await db
            .updateUser(
                uid: user.uid,
                firstName: firstName,
                lastName: lastName,
                company: company,
                phoneNumber: phoneNumber,
                isActive: false,
                emailAddress: email,
                nationality: nationality,
                homeAddress: homeAddress,
                imageUrl: imageUrl,
                roles: roles)
            .then((value) {
          return value;
        });
        Future.delayed(const Duration(seconds: 3));
        user = _auth.currentUser;
        try {
          await user.sendEmailVerification();
          return user.uid;
        } catch (e, stackTrace) {
          print('Error sending verification email: $e');
          await sentry.Sentry.captureException(e, stackTrace: stackTrace);
        }
      }
    } catch (e, stackTrace) {
      print('Error creating user: $e');
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return e.toString();
    }
  }

  //sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return null;
    }
  }

  Future resetPassword(String email) async {
    try {
      return await _auth.sendPasswordResetEmail(email: email);
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Reset email error: $e';
    }
  }

  Future deleteUser(String uid) async {
    try {} catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
    }
  }
}
