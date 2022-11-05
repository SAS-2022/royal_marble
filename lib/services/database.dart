import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/directions.dart';
import 'package:sentry/sentry.dart' as sentry;
import '../models/user_model.dart';

class DatabaseService {
  String uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference clientCollection =
      FirebaseFirestore.instance.collection('clients');
  final CollectionReference projectCollection =
      FirebaseFirestore.instance.collection('projects');

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
    Map<String, dynamic> nationality,
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

  //update the user's live location
  Future<String> updateUserLiveLocation(
      {String uid, LatLng currentLocation, double distance}) async {
    try {
      Map<String, dynamic> newLoc = {
        'Lat': currentLocation.latitude,
        'Lng': currentLocation.longitude,
      };
      return await userCollection.doc(uid).update({
        'currentLocation': newLoc,
        'distanceToProject': distance,
      }).then((value) => 'Completed');
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

  //update current user role
  Future<String> assignUserRole({String selectedRole, String uid}) async {
    var roles = '';
    switch (selectedRole) {
      case 'Worker':
        roles = 'isNormalUser';
        break;
      case 'Sales':
        roles = 'isSales';
        break;
      case 'Admin':
        roles = 'isAdmin';
        break;
    }
    try {
      return await userCollection.doc(uid).update({
        'roles': [roles]
      }).then((value) => 'Completed');
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

  //assign user to a project
  Future<String> assignUsersToProject(
      {List<UserData> userIds, ProjectData project}) async {
    String result;
    try {
      for (UserData user in userIds) {
        Map<String, dynamic> projectDetails = {
          'projectId': project.uid,
          'Lat': project.projectAddress['Lat'],
          'Lng': project.projectAddress['Lng'],
          'radius': project.radius,
        };
        result = await userCollection.doc(user.uid).update(
            {'assignedProject': projectDetails}).then((value) => 'Completed');
      }
      return result;
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

  Stream<List<CustomMarker>> getAllUsersLocation({String userId}) {
    return userCollection
        .doc(userId)
        .collection('location')
        .limit(1)
        .snapshots()
        .map(_allUserLocationDataFromSnapshot);
  }

  Future<Map<String, dynamic>> getUserLocationFuture({String usersId}) async {
    return await userCollection
        .doc(usersId)
        .collection('location')
        .doc('current')
        .get()
        .then((value) {
      if (value.data() != null) {
        return {
          'lat': value.data()['location']['coords']['latitude'],
          'lng': value.data()['location']['coords']['longitude']
        };
      } else {
        return {};
      }
    });
  }

  Stream<List<UserData>> getAllWorkers() {
    return userCollection
        .where('roles', arrayContains: 'isNormalUser')
        .orderBy('firstName', descending: false)
        .snapshots()
        .map(_allUserDataFromSnapshot);
  }

  Future<UserData> getUserByIdFuture({String uid}) async {
    try {
      return await userCollection.doc(uid).get().then((data) {
        return UserData(
          emailAddress: data['emailAddress'],
          firstName: data['firstName'],
          lastName: data['lastName'],
          phoneNumber: data['phoneNumber'],
          nationality: data['nationality'],
          isActive: data['isActive'] ?? false,
          roles: data['roles'],
          company: data['company'],
          homeAddress: data['homeAddress'],
          assignedProject: data['assignedProject'],
          distanceToProject: data['distanceToProject'],
          currentLocation: data['currentLocation'],
        );
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return UserData(error: e);
    }
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
      assignedProject: data['assignedProject'],
      distanceToProject: data['distanceToProject'],
      currentLocation: data['currentLocation'],
      location: data['location'],
    );
  }

  List<CustomMarker> _allUserLocationDataFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((snapshot) {
      var data = snapshot.data() as Map<String, dynamic>;
      var result = CustomMarker(
          id: snapshot.id,
          coord: LatLng(data['location']['coords']['latitude'],
              data['location']['coords']['longitude']));

      return result;
    }).toList();
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
        assignedProject: data['assignedProject'],
        distanceToProject: data['distanceToProject'],
        currentLocation: data['currentLocation'],
        location: data['location'],
      );
    }).toList();
  }

  //Future to read current users
  Future<List<UserData>> getUsersFuture() async {
    try {
      return await userCollection.get().then((value) {
        return value.docs.map((e) {
          var data = e.data() as Map<String, dynamic>;
          return UserData(
              uid: e.id,
              emailAddress: data['emailAddress'],
              firstName: data['firstName'],
              lastName: data['lastName'],
              phoneNumber: data['phoneNumber'],
              nationality: data['nationality'],
              isActive: data['isActive'] ?? false,
              roles: data['roles'],
              company: data['company'],
              homeAddress: data['homeAddress'],
              distanceToProject: data['distanceToProject'],
              currentLocation: data['currentLocation']);
        }).toList();
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return [];
    }
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

  //Future to read current Clients
  Future<List<ClientData>> getClientFuture() async {
    try {
      return await clientCollection.get().then((value) {
        return value.docs.map((e) {
          var data = e.data() as Map<String, dynamic>;
          return ClientData(
              uid: e.id,
              clientName: data['clientName'],
              contactPerson: data['contactPerson'],
              clientAddress: data['clientAddress'],
              emailAddress: data['emailAddress'],
              phoneNumber: data['phoneNumber'],
              clientVisits: data['clientVisits']);
        }).toList();
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<ClientData>> getSalesUserClientFuture({String userId}) async {
    try {
      return await clientCollection
          .where('salesInCharge', isEqualTo: userId)
          .get()
          .then((value) {
        return value.docs.map((e) {
          var data = e.data() as Map<String, dynamic>;
          return ClientData(
              uid: e.id,
              clientName: data['clientName'],
              contactPerson: data['contactPerson'],
              clientAddress: data['clientAddress'],
              emailAddress: data['emailAddress'],
              phoneNumber: data['phoneNumber'],
              clientVisits: data['clientVisits']);
        }).toList();
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return [];
    }
  }

  //create a project with location
  Future<String> addNewProject({ProjectData project}) async {
    try {
      print('the project address: ${project.projectAddress}');
      return await projectCollection.add({
        'projectName': project.projectName,
        'projectDetails': project.projectDetails,
        'selectedAddress': project.projectAddress,
        'radius': project.radius,
        'contractor': project.contactorCompany,
        'contactPerson': project.contactPerson,
        'phoneNumber': project.phoneNumber,
        'emailAddress': project.emailAddress,
        'salesInCharge': project.userId,
        'assignedWorkers': project.assignedWorkers,
      }).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //updating clients
  Future<String> updateProjectData({ProjectData project}) async {
    try {
      return await projectCollection.doc(project.uid).update({
        'projectName': project.projectName,
        'projectDetails': project.projectDetails,
        'selectedAddress': project.projectAddress,
        'radius': project.radius,
        'contractor': project.contactorCompany,
        'contactPerson': project.contactPerson,
        'phoneNumber': project.phoneNumber,
        'emailAddress': project.emailAddress,
        'salesInCharge': project.userId,
        'assignedWorkers': project.assignedWorkers,
      }).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //update project with assigned users
  //we will update the project with a list of users ids
  //we will update each user with the assigned project and its coordinates
  Future<String> updateProjectWithWorkers(
      {ProjectData project, List<String> selectedUserIds}) async {
    try {
      //update the project data first
      var result = await projectCollection
          .doc(project.uid)
          .update({
            'assignedWorkers': selectedUserIds,
          })
          .then((value) => 'Completed')
          .catchError((err) => 'Error: $err');

      if (result == 'Completed') {
        var userResult;
        for (var user in selectedUserIds) {
          userResult = await userCollection
              .doc(user)
              .update({
                'assignedProject': {
                  'id': project.uid,
                  'name': project.projectName,
                  'projectAddress': project.projectAddress,
                  'radius': project.radius,
                }
              })
              .then((value) => 'Completed')
              .catchError((err) {
                print('Error updating users: $err');
                return err;
              });
        }
        return userResult;
      } else {
        return '[Failed]: $result';
      }
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //Get projects through streams and Futures

  Stream<List<ProjectData>> getAllProjects() {
    return projectCollection.snapshots().map(_listProjectDataFromSnapshot);
  }

  Stream<ProjectData> getProjectById({String projectId}) {
    return projectCollection
        .doc(projectId)
        .snapshots()
        .map(_projectDataFromSnapshot);
  }

  Future<ProjectData> getPorjectByIdFuture({String projectId}) async {
    try {
      var result = await projectCollection.doc(projectId).get().then((data) {
        var result = ProjectData(
            uid: data.id,
            projectName: data['projectName'],
            projectDetails: data['projectDetails'],
            projectAddress: data['selectedAddress'],
            radius: data['radius'],
            contactorCompany: data['contractor'],
            contactPerson: data['contactPerson'],
            emailAddress: data['emailAddress'],
            phoneNumber: data['phoneNumber'],
            userId: data['salesInCharge'],
            assignedWorkers: data['assignedWorkers']);
        return result;
      });

      return result;
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      print('An error obtaining project: $e');
      return ProjectData(error: e);
    }
  }

  List<ProjectData> _listProjectDataFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((snapshot) {
      var data = snapshot.data() as Map<String, dynamic>;
      return ProjectData(
          uid: snapshot.id,
          projectName: data['projectName'],
          projectDetails: data['projectDetails'],
          projectAddress: data['selectedAddress'],
          radius: data['radius'],
          contactorCompany: data['contractor'],
          contactPerson: data['contactPerson'],
          emailAddress: data['emailAddress'],
          phoneNumber: data['phoneNumber'],
          userId: data['salesInCharge'],
          assignedWorkers: data['assignedWorkers']);
    }).toList();
  }

  ProjectData _projectDataFromSnapshot(DocumentSnapshot snapshot) {
    var data = snapshot.data() as Map<String, dynamic>;
    return ProjectData(
      uid: snapshot.id,
      projectName: data['projectName'],
      projectDetails: data['projectDetails'],
      projectAddress: data['selectedAddress'],
      radius: data['radius'],
      contactorCompany: data['contractor'],
      contactPerson: data['contactPerson'],
      emailAddress: data['emailAddress'],
      phoneNumber: data['phoneNumber'],
      userId: data['salesInCharge'],
      assignedWorkers: data['assignedWorkers'],
    );
  }

  Future<String> deleteProject({String projectId}) async {
    try {
      return await projectCollection
          .doc(projectId)
          .delete()
          .then((value) => 'Deleted');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error Deleting: $e';
    }
  }
}
