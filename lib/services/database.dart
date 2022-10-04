import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sentry/sentry.dart' as sentry;

class DatabaseService {
  String uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  //Update the user data
  Future<String> setUserData(
      {String uid,
      String firstName,
      String lastName,
      String company,
      bool isActive,
      String phoneNumber,
      String emailAddress,
      String countryOfResidence,
      String cityOfResidence,
      List<dynamic> roles,
      String secondEmail,
      String defaultStoreKeeper}) async {
    try {
      return await userCollection.doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'company': company,
        'isActive': isActive,
        'phoneNumber': phoneNumber,
        'emailAddress': emailAddress,
        'countryOfResidence': countryOfResidence,
        'cityOfResidence': cityOfResidence,
        'storeKeeper': defaultStoreKeeper,
        'secondEmail': secondEmail,
      }).then((value) {
        return 'your data has been updated successfully';
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return ' $e';
    }
  }
}
