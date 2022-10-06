import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sentry/sentry.dart' as sentry;

import '../models/user_model.dart';

class DatabaseService {
  String uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  //Update the user data
  Future<String> updateUser({
    String uid,
    String firstName,
    String lastName,
    String company,
    bool isActive,
    String phoneNumber,
    String emailAddress,
    List<dynamic> roles,
    String nationality,
    Map<String, dynamic> homeAddress,
  }) async {
    try {
      return await userCollection.doc(uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'company': company,
        'isActive': isActive,
        'phoneNumber': phoneNumber,
        'emailAddress': emailAddress,
        'nationality': nationality,
        'roles': roles,
        'homeAddress': homeAddress,
      }).then((value) {
        return 'your data has been updated successfully';
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return ' $e';
    }
  }

  //delete a user
  Future<String> deleteUser({String uid}) async {
    try {
      return await userCollection
          .doc(uid)
          .delete()
          .then((value) => 'User deleted');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //read the users data through futures and streams

  //stream user data
  Stream<UserData> getUserPerId({String uid}) {
    return userCollection.doc(uid).snapshots().map(_singleUserDataFromSnapshot);
  }

  //User data from snapshot
  UserData _singleUserDataFromSnapshot(DocumentSnapshot snapshot) {
    var data = snapshot.data() as Map<String, dynamic>;
    return UserData(
      uid: snapshot.id,
      emailAddress: data['emailAddress'],
      firstName: data['firstName'],
      lastName: data['lastName'],
      phoneNumber: data['phoneNumber'],
      nationality: data['nationality'],
      isActive: data['isActive'] ?? false,
      roles: data['roles'],
      homeAddress: data['homeAddress'],
    );
  }
}
