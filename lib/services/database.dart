import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:sentry/sentry.dart' as sentry;

import '../models/user_model.dart';

class DatabaseService {
  String uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  final CollectionReference clientCollection =
      FirebaseFirestore.instance.collection('clients');

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

  //activate or deactivate a user
  Future<String> activateDeactivateUser({String uid, bool active}) async {
    try {
      return await userCollection
          .doc(uid)
          .update({'isActive': active}).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //update current user
  Future<String> updateCurrentUser({String uid, UserData newUsers}) async {
    try {
      return await userCollection.doc(uid).update({
        'firstName': newUsers.firstName,
        'lastName': newUsers.lastName,
        'company': newUsers.company,
        'phoneNumber': newUsers.phoneNumber,
        'nationality': {
          'contryCode': newUsers.nationality['countryCode'],
          'countryName': newUsers.nationality['countryName']
        },
        'homeAddress': newUsers.homeAddress,
      }).then((value) => 'Completed');
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

  Stream<List<UserData>> getAllUsers() {
    return userCollection.snapshots().map(_allUserDataFromSnapshot);
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
      company: data['company'],
      homeAddress: data['homeAddress'],
    );
  }

  List<UserData> _allUserDataFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((snapshot) {
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
        company: data['company'],
        homeAddress: data['homeAddress'],
      );
    }).toList();
  }

  //The below section will allow us to handle clients changes
  //adding clients
  Future<String> addNewClients({ClientData client}) async {
    try {
      return await clientCollection.add({
        'clientName': client.clientName,
        'clientAddress': client.clientAddress,
        'contactPerson': client.contactPerson,
        'phoneNumber': client.phoneNumber,
        'emailAddress': client.emailAddress,
        'userId': client.userId,
      }).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //updating clients
  Future<String> updateClientData({ClientData client}) async {
    try {
      return await clientCollection.doc(client.uid).update({
        'clientName': client.clientName,
        'clientAddress': client.clientAddress,
        'contactPerson': client.contactPerson,
        'phoneNumber': client.phoneNumber,
        'emailAddress': client.emailAddress,
        'userId': client.userId,
      }).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //add a client visit
  Future<String> addClientVisit(
      {ClientData client, VisitDetails visitDetails}) async {
    try {
      return await clientCollection.doc(client.uid).update({
        'clientVisits': FieldValue.arrayUnion([
          {
            'contactPerson': visitDetails.contactPerson,
            'visitContent': visitDetails.visitContent,
            'visitTime': visitDetails.visitTime
          }
        ])
      }).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //deleting clients
  Future<void> deleteClient({String clientId}) async {
    try {
      await clientCollection.doc(clientId).delete();
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  //reading through streams and futures
  Stream<List<ClientData>> getClientsPerUser({String userId}) {
    return clientCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_listClientDataFromSnapshot);
  }

  Stream<ClientData> getClientPerId({String uid}) {
    return clientCollection
        .doc(uid)
        .snapshots()
        .map(_singleClientDataFromSnapshot);
  }

  Stream<List<ClientData>> getAllClients() {
    return clientCollection.snapshots().map(_listClientDataFromSnapshot);
  }

  ClientData _singleClientDataFromSnapshot(DocumentSnapshot snapshot) {
    var data = snapshot.data() as Map<String, dynamic>;
    return ClientData(
        uid: snapshot.id,
        clientName: data['clientName'],
        contactPerson: data['contactPerson'],
        clientAddress: data['clientAddress'],
        emailAddress: data['emailAddress'],
        phoneNumber: data['phoneNumber'],
        clientVisits: data['clientVisits']);
  }

  List<ClientData> _listClientDataFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((snapshot) {
      var data = snapshot.data() as Map<String, dynamic>;
      return ClientData(
          uid: snapshot.id,
          clientName: data['clientName'],
          contactPerson: data['contactPerson'],
          clientAddress: data['clientAddress'],
          emailAddress: data['emailAddress'],
          phoneNumber: data['phoneNumber'],
          clientVisits: data['clientVisits']);
    }).toList();
  }
}
