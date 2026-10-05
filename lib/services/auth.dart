import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/core/error_reporter.dart';

enum SignInError {
  invalidEmail,
  userDisabled,
  tooManyRequests,
  noInternet,
  wrongCredentials,
  /// The email already belongs to an account with another sign-in method.
  accountExists,
  /// The person closed the Google/Apple sheet; show nothing.
  cancelled,
  other,
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// google_sign_in must be initialized exactly once per app run. On Android
  /// the web client id comes from google-services.json.
  static Future<void>? _googleInit;
  static Future<GoogleSignIn> _google() async {
    await (_googleInit ??= GoogleSignIn.instance.initialize());
    return GoogleSignIn.instance;
  }
  UserData? currentUser;

  DatabaseService db = DatabaseService();
  var newUser;

  //create a user object based on Firebase user
  UserData? _userFromFirebaseUser(User? user) {
    return user != null ? UserData(uid: user.uid) : null;
  }

  //Verify user account
  Future<String> userFromFirebaseVerification(String emailAddress) async {
    var user = _auth.currentUser;
    try {
      await user!.sendEmailVerification();
      return user.uid;
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return e.toString();
    }
  }

  //auth change user screen
  Stream<UserData?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  //sign in with user name and password
  Future signInWithUserNameandPassword(String? email, String? password) async {
    try {
      var result = await _auth.signInWithEmailAndPassword(
          email: email!.trim(), password: password!);
      var user = result.user?.uid;
      if (user != null) {
        return user;
      } else {
        return null;
      }
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
    }
  }

  /// Signs in; returns null on success or why it failed.
  Future<SignInError?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'invalid-email' => SignInError.invalidEmail,
        'user-disabled' => SignInError.userDisabled,
        'too-many-requests' => SignInError.tooManyRequests,
        'network-request-failed' => SignInError.noInternet,
        _ => SignInError.wrongCredentials,
      };
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return SignInError.other;
    }
  }

  /// Signs in (or up) with Google; returns null on success. A new person has
  /// no profile yet, so the wrapper then shows the rest of the registration.
  Future<SignInError?> signInWithGoogle() async {
    try {
      final account = await (await _google()).authenticate();
      await _auth.signInWithCredential(GoogleAuthProvider.credential(
          idToken: account.authentication.idToken));
      return null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return SignInError.cancelled;
      }
      await ErrorReporter.record(e);
      return SignInError.other;
    } on FirebaseAuthException catch (e) {
      return _socialError(e);
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return SignInError.other;
    }
  }

  /// Signs in (or up) with Apple; returns null on success.
  Future<SignInError?> signInWithApple() async {
    try {
      await _auth.signInWithProvider(
          AppleAuthProvider()..addScope('email')..addScope('name'));
      return null;
    } on FirebaseAuthException catch (e) {
      return _socialError(e);
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return SignInError.other;
    }
  }

  Future<SignInError> _socialError(FirebaseAuthException e) async {
    if (e.code.contains('cancel')) return SignInError.cancelled;
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return SignInError.accountExists;
      case 'user-disabled':
        return SignInError.userDisabled;
      case 'network-request-failed':
        return SignInError.noInternet;
    }
    await ErrorReporter.record(e);
    return SignInError.other;
  }

  /// How the current user signs in: 'password', 'google.com' or 'apple.com'.
  String? get signInMethod {
    final ids = _auth.currentUser?.providerData.map((p) => p.providerId) ?? [];
    if (ids.contains('password')) return 'password';
    return ids.isEmpty ? null : ids.first;
  }

  /// Firebase only deletes an account after a recent sign-in. Google and
  /// Apple users confirm through their provider; throws if they cancel.
  Future<void> reauthenticateWithProvider() async {
    final user = _auth.currentUser!;
    if (signInMethod == 'google.com') {
      final account = await (await _google()).authenticate();
      await user.reauthenticateWithCredential(GoogleAuthProvider.credential(
          idToken: account.authentication.idToken));
    } else if (signInMethod == 'apple.com') {
      await user.reauthenticateWithProvider(AppleAuthProvider());
    }
  }

  //Sign in without requesting any credentials
  Future signInAnonymously() async {
    try {
      var result = await _auth.signInAnonymously();
      var user = result.user;
      if (user != null) {
        return user.uid;
      } else {
        return null;
      }
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return e.toString();
    }
  }

  //register with email and password
  Future registerWithEmailandPassword(
      {String? email,
      String? password,
      String? firstName,
      String? lastName,
      String? company,
      bool? isActive,
      String? phoneNumber,
      Map<String, dynamic>? nationality,
      Map<String, dynamic>? homeAddress,
      String? imageUrl,
      List<String>? roles}) async {
    try {
      var result = await _auth.createUserWithEmailAndPassword(
          email: email!, password: password!);

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
          await user!.sendEmailVerification();
          return user.uid;
        } catch (e, stackTrace) {
          print('Error sending verification email: $e');
          await ErrorReporter.record(e, stackTrace: stackTrace);
        }
      }
    } catch (e, stackTrace) {
      print('Error creating user: $e');
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return e.toString();
    }
  }

  //sign out
  Future signOut() async {
    try {
      // Otherwise Google picks the same account next time without asking.
      if (signInMethod == 'google.com') await (await _google()).signOut();
      return await _auth.signOut();
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return null;
    }
  }

  Future resetPassword(String email) async {
    try {
      return await _auth.sendPasswordResetEmail(email: email);
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Reset email error: $e';
    }
  }
}
