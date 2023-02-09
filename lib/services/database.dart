import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
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
  final CollectionReference timeSheetCollection =
      FirebaseFirestore.instance.collection('time_sheet');
  final CollectionReference helperCollection =
      FirebaseFirestore.instance.collection('helper');
  final CollectionReference mockupCollection =
      FirebaseFirestore.instance.collection('mockup');

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
    String imageUrl,
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
        'imageUrl': imageUrl,
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

  //update user location permission status
  Future<String> updateUserPermissionStatus(
      {String uid, ph.PermissionStatus permissionStatus}) async {
    try {
      print('the status 1: $permissionStatus');
      return await userCollection
          .doc(uid)
          .update({'locationPermission': permissionStatus.toString()}).then(
              (value) => 'Permission Status updated');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error: $e';
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
      case 'Mason':
        roles = 'isNormalUser';
        break;
      case 'Supervisor':
        roles = 'isSupervisor';
        break;
      case 'Site Engineer':
        roles = 'isSiteEngineer';
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
        'imageUrl': newUsers.imageUrl,
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

  //Update a user with helpers
  Future<String> updateUserWithHelpers(
      {String uid, List<dynamic> helpers}) async {
    try {
      return await userCollection
          .doc(uid)
          .update({'assignedHelpers': helpers}).then((value) => 'Completed');
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
    return userCollection
        .orderBy('firstName')
        .snapshots()
        .map(_allUserDataFromSnapshot);
  }

  Stream<List<UserData>> getNonAdminUsers() {
    return userCollection
        .where('roles', arrayContainsAny: [
          'isSales',
          'isNormalUser',
          'isSupervisor',
          'isSiteEngineer'
        ])
        .snapshots()
        .map(_allUserDataFromSnapshot);
  }

  Stream<List<CustomMarker>> getAllUsersLocation({String userId}) {
    return userCollection
        .doc(userId)
        .collection('location')
        .limit(1)
        .snapshots()
        .map(_allUserLocationDataFromSnapshot);
  }

  //Get users depending on their role
  Future<List<UserData>> getUsersPerRole({String userRole}) async {
    try {
      return userCollection
          .where('roles', arrayContains: userRole)
          .get()
          .then((value) {
        return value.docs.map((e) {
          var data = e.data() as Map<String, dynamic>;
          return UserData(
            uid: e.id,
            firstName: data['firstName'],
            lastName: data['lastName'],
          );
        }).toList();
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return [];
    }
  }

  //Future for getting all masons
  Future<List<UserData>> getAllMasonsFuture() async {
    try {
      return userCollection
          .where('roles', arrayContains: 'isNormalUser')
          .get()
          .then((value) {
        return value.docs.map((e) {
          var data = e.data() as Map<String, dynamic>;
          return UserData(
              uid: e.id,
              firstName: data['firstName'],
              lastName: data['lastName'],
              assingedHelpers: data['assignedHelpers']);
        }).toList();
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return [];
    }
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
          'uuid': value.data()['location']['uuid'],
          'lat': value.data()['location']['coords']['latitude'],
          'lng': value.data()['location']['coords']['longitude'],
          'speed': value.data()['location']['coords']['speed'] ?? '',
          'activity': value.data()['location']['activity']['type'] ?? '',
          'charging': value.data()['location']['battery']['is_charging'] ?? '',
          'battery': value.data()['location']['battery']['level'] ?? '',
          'isMoving': value.data()['location']['is_moving'] ?? '',
          'enabled': value.data()['location']['provider'] != null
              ? value.data()['location']['provider']['enabled']
              : '',
          'network': value.data()['location']['provider'] != null
              ? value.data()['location']['provider']['network']
              : '',
          'gps': value.data()['location']['provider'] != null
              ? value.data()['location']['provider']['gps']
              : '',
          'time': value.data()['location']['timestamp'] ?? ''
        };
      } else {
        return {};
      }
    });
  }

  Stream<List<UserData>> getAllWorkers() {
    return userCollection
        .where('roles', arrayContainsAny: [
          'isNormalUser',
          'isSupervisor',
          'isSiteEngineer'
        ])
        .orderBy('firstName', descending: false)
        .snapshots()
        .map(_allUserDataFromSnapshot);
  }

  Stream<List<UserData>> getSalesUsers() {
    return userCollection
        .where('roles', arrayContains: 'isSales')
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
            assignedMockups: data['assignedMockup'],
            distanceToProject: data['distanceToProject'],
            currentLocation: data['currentLocation'],
            assingedHelpers: data['assignedHelpers'] ?? [],
            imageUrl: data['imageUrl']);
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
      assignedMockups: data['assignedMockup'],
      distanceToProject: data['distanceToProject'],
      currentLocation: data['currentLocation'],
      imageUrl: data['imageUrl'],
      assingedHelpers: data['assignedHelpers'] ?? [],
      location: data['location'],
    );
  }

  List<CustomMarker> _allUserLocationDataFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((snapshot) {
      var data = snapshot.data() as Map<String, dynamic>;
      var result = CustomMarker(
          id: data['location']['uuid'],
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
        assignedMockups: data['assignedMockup'],
        distanceToProject: data['distanceToProject'],
        currentLocation: data['currentLocation'],
        imageUrl: data['imageUrl'],
        permissionStatus: data['locationPermission'],
        assingedHelpers: data['assignedHelpers'] ?? [],
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
              assignedProject: data['assignedProject'],
              assignedMockups: data['assignedMockup'],
              distanceToProject: data['distanceToProject'],
              imageUrl: data['imageUrl'],
              assingedHelpers: data['assignedHelpers'] ?? [],
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
        'phoneNumber': {
          'phoneNumber': client.phoneNumber.phoneNumber,
          'dialCode': client.phoneNumber.dialCode,
          'isoCode': client.phoneNumber.isoCode,
        },
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
        'phoneNumber': {
          'phoneNumber': client.phoneNumber.phoneNumber,
          'dialCode': client.phoneNumber.dialCode,
          'isoCode': client.phoneNumber.isoCode,
        },
        'emailAddress': client.emailAddress,
        'userId': client.userId,
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
    var result = clientCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_listClientDataFromSnapshot);
    return result;
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
        phoneNumber: PhoneNumber(
            phoneNumber: data['phoneNumber']['phoneNumber'],
            isoCode: data['phoneNumber']['isoCode'],
            dialCode: data['phoneNumber']['dialCode']),
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
          phoneNumber: PhoneNumber(
              phoneNumber: data['phoneNumber']['phoneNumber'],
              isoCode: data['phoneNumber']['isoCode'],
              dialCode: data['phoneNumber']['dialCode']),
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
              phoneNumber: PhoneNumber(
                  phoneNumber: data['phoneNumber']['phoneNumber'],
                  isoCode: data['phoneNumber']['isoCode'],
                  dialCode: data['phoneNumber']['dialCode']),
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
              phoneNumber: PhoneNumber(
                  phoneNumber: data['phoneNumber']['phoneNumber'],
                  isoCode: data['phoneNumber']['isoCode'],
                  dialCode: data['phoneNumber']['dialCode']),
              clientVisits: data['clientVisits']);
        }).toList();
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return [];
    }
  }

  //Projects Section
  //create a project with location
  Future<String> addNewProject({ProjectData project}) async {
    try {
      return await projectCollection.add({
        'projectName': project.projectName,
        'projectDetails': project.projectDetails,
        'selectedAddress': project.projectAddress,
        'radius': project.radius,
        'contractor': project.contactorCompany,
        'contactPerson': project.contactPerson,
        'phoneNumber': {
          'phoneNumber': project.phoneNumber.phoneNumber,
          'isoCode': project.phoneNumber.isoCode,
          'dialCode': project.phoneNumber.dialCode,
        },
        'emailAddress': project.emailAddress,
        'salesInCharge': project.userId,
        'assignedWorkers': project.assignedWorkers,
        'status': project.projectStatus,
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
        'phoneNumber': {
          'phoneNumber': project.phoneNumber.phoneNumber,
          'isoCode': project.phoneNumber.isoCode,
          'dialCode': project.phoneNumber.dialCode,
        },
        'emailAddress': project.emailAddress,
        'salesInCharge': project.userId,
        'assignedWorkers': project.assignedWorkers,
        'status': project.projectStatus,
      }).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //update project status
  Future<String> updateProjectStatus({ProjectData project}) async {
    try {
      return await projectCollection.doc(project.uid).update({
        'status': project.projectStatus,
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
      {ProjectData project,
      List<UserData> addedUsers,
      List<String> selectedUserIds,
      List<UserData> removedUsers}) async {
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
        //check which users were removed to remove them
        if (removedUsers != null && removedUsers.isNotEmpty) {
          for (var user in removedUsers) {
            if (user.roles.contains('isSupervisor')) {
              await userCollection
                  .doc(user.uid)
                  .update({
                    'assignedProject': FieldValue.arrayRemove(
                      [
                        {
                          'id': project.uid,
                          'name': project.projectName,
                          'projectAddress': project.projectAddress,
                          'radius': project.radius,
                        }
                      ],
                    )
                  })
                  .then((value) => print(
                      'the user ${user.firstName} ${user.lastName} was removed'))
                  .catchError((err) => print(
                      'Error remove user ${user.firstName} ${user.lastName}'));
            } else {
              await userCollection
                  .doc(user.uid)
                  .update({'assignedProject': {}})
                  .then((value) => print(
                      'the user ${user.firstName} ${user.lastName} was removed'))
                  .catchError((err) => print(
                      'Error remove user ${user.firstName} ${user.lastName}'));
            }
          }
        }
        //add new users
        for (var user in addedUsers) {
          if (user.roles.contains('isSupervisor')) {
            userResult = await userCollection
                .doc(user.uid)
                .update({
                  'assignedProject': FieldValue.arrayUnion([
                    {
                      'id': project.uid,
                      'name': project.projectName,
                      'projectAddress': project.projectAddress,
                      'radius': project.radius,
                    }
                  ])
                })
                .then((value) => 'Completed')
                .catchError((err) {
                  print('Error updating users: $err');
                  return err;
                });
          } else {
            userResult = await userCollection
                .doc(user.uid)
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

  //removing users from a selected project
  Future<String> removeUserFromProject(
      {ProjectData selectedProject,
      String userId,
      UserData removedUser}) async {
    var result;
    try {
      //first remove user id from the project
      List<dynamic> projectAssignedUsers =
          await projectCollection.doc(selectedProject.uid).get().then((value) {
        var data = value.data() as Map<String, dynamic>;
        return data['assignedWorkers'];
      });
      //will remove current user
      if (projectAssignedUsers != null && projectAssignedUsers.isNotEmpty) {
        projectAssignedUsers.removeWhere((element) => element == userId);
        //now assign the new list to the project
        await projectCollection
            .doc(selectedProject.uid)
            .update({'assignedWorkers': projectAssignedUsers}).catchError(
                (err) => print('Could not update project assigned workers'));
      }

      //now we need to remove the assigned project from the user's document
      var assignedProject =
          await userCollection.doc(removedUser.uid).get().then((value) {
        var data = value.data() as Map<String, dynamic>;
        return data['assignedProject'];
      });

      if (removedUser.roles.contains('isSupervisor')) {
        for (var project in assignedProject) {
          if (project['id'] == selectedProject.uid) {
            result = await userCollection
                .doc(userId)
                .update({
                  'assignedProject': FieldValue.arrayRemove([
                    {
                      'id': selectedProject.uid,
                      'name': selectedProject.projectName,
                      'projectAddress': selectedProject.projectAddress,
                      'radius': selectedProject.radius,
                    }
                  ])
                })
                .then((value) => 'Deleted User')
                .catchError((err) => 'Error: $err');
          }
        }
      } else {
        if (assignedProject['id'] == selectedProject.uid) {
          result = await userCollection
              .doc(userId)
              .update({'assignedProject': {}})
              .then((value) => 'Deleted User')
              .catchError((err) => 'Error: $err');
        }
      }

      return result;
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      print('An error removing users: $e');
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
            phoneNumber: PhoneNumber(
                phoneNumber: data['phoneNumber']['phoneNumber'],
                isoCode: data['phoneNumber']['isoCode'],
                dialCode: data['phoneNumber']['dialCode']),
            userId: data['salesInCharge'],
            projectStatus: data['status'],
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
          phoneNumber: PhoneNumber(
              phoneNumber: data['phoneNumber']['phoneNumber'],
              isoCode: data['phoneNumber']['isoCode'],
              dialCode: data['phoneNumber']['dialCode']),
          userId: data['salesInCharge'],
          projectStatus: data['status'],
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
      phoneNumber: PhoneNumber(
          phoneNumber: data['phoneNumber']['phoneNumber'],
          isoCode: data['phoneNumber']['isoCode'],
          dialCode: data['phoneNumber']['dialCode']),
      userId: data['salesInCharge'],
      projectStatus: data['status'],
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

  //Mock-up Section
  //Add new mockup
  Future<String> addNewMockup({MockupData mockup}) async {
    try {
      return await mockupCollection.add({
        'name': mockup.mockupName,
        'details': mockup.mockupDetails,
        'address': mockup.mockupAddress,
        'radius': mockup.radius,
        'contractor': mockup.contactorCompany,
        'contactPerson': mockup.contactPerson,
        'phoneNumber': {
          'phoneNumber': mockup.phoneNumber.phoneNumber,
          'isoCode': mockup.phoneNumber.isoCode,
          'dialCode': mockup.phoneNumber.dialCode,
        },
        'emailAddress': mockup.emailAddress,
        'salesInCharge': mockup.userId,
        'assignedWorkers': mockup.assignedWorkers,
        'status': mockup.mockupStatus,
      }).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //update mockup
  Future<String> updateMockupData({MockupData mockup}) async {
    try {
      return await projectCollection.doc(mockup.uid).update({
        'name': mockup.mockupName,
        'details': mockup.mockupDetails,
        'address': mockup.mockupAddress,
        'radius': mockup.radius,
        'contractor': mockup.contactorCompany,
        'contactPerson': mockup.contactPerson,
        'phoneNumber': {
          'phoneNumber': mockup.phoneNumber.phoneNumber,
          'isoCode': mockup.phoneNumber.isoCode,
          'dialCode': mockup.phoneNumber.dialCode,
        },
        'emailAddress': mockup.emailAddress,
        'salesInCharge': mockup.userId,
        'assignedWorkers': mockup.assignedWorkers,
        'status': mockup.mockupStatus,
      }).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //update mockup with assigned users
  //we will update the mockup with a list of users ids
  //we will update each user with the assigned mockup and its coordinates
  Future<String> updateMockupWithWorkers(
      {MockupData mockup,
      List<UserData> addedUsers,
      List<String> selectedUserIds,
      List<UserData> removedUsers}) async {
    try {
      //update the project data first
      var result = await mockupCollection
          .doc(mockup.uid)
          .update({
            'assignedWorkers': selectedUserIds,
          })
          .then((value) => 'Completed')
          .catchError((err) => 'Error: $err');

      if (result == 'Completed') {
        var userResult;
        //check which users were removed to remove them
        if (removedUsers != null && removedUsers.isNotEmpty) {
          for (var user in removedUsers) {
            if (user.roles.contains('isSupervisor')) {
              await userCollection
                  .doc(user.uid)
                  .update({
                    'assignedMockup': FieldValue.arrayRemove(
                      [
                        {
                          'id': mockup.uid,
                          'name': mockup.mockupName,
                          'projectAddress': mockup.mockupAddress,
                          'radius': mockup.radius,
                        }
                      ],
                    )
                  })
                  .then((value) => print(
                      'the user ${user.firstName} ${user.lastName} was removed'))
                  .catchError((err) => print(
                      'Error remove user ${user.firstName} ${user.lastName}'));
            } else {
              await userCollection
                  .doc(user.uid)
                  .update({'assignedMockup': {}})
                  .then((value) => print(
                      'the user ${user.firstName} ${user.lastName} was removed'))
                  .catchError((err) => print(
                      'Error remove user ${user.firstName} ${user.lastName}'));
            }
          }
        }
        //add new users
        for (var user in addedUsers) {
          userResult = await userCollection
              .doc(user.uid)
              .update({
                'assignedMockup': FieldValue.arrayUnion([
                  {
                    'id': mockup.uid,
                    'name': mockup.mockupName,
                    'projectAddress': mockup.mockupAddress,
                    'radius': mockup.radius,
                  }
                ])
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

  //Update the mockup status
  Future<String> updateMockupStatus({MockupData mockup}) async {
    try {
      return await mockupCollection.doc(mockup.uid).update({
        'status': mockup.mockupStatus,
        'assignedWorkers': mockup.assignedWorkers,
      }).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //removing users from a selected mockup
  Future<String> removeUserFromMockup(
      {MockupData selectedMockup, String userId, UserData removedUser}) async {
    var result;
    try {
      //first remove user id from the project
      List<dynamic> mockupAssignedUsers =
          await mockupCollection.doc(selectedMockup.uid).get().then((value) {
        var data = value.data() as Map<String, dynamic>;
        return data['assignedWorkers'];
      });
      //will remove current user
      if (mockupAssignedUsers != null && mockupAssignedUsers.isNotEmpty) {
        mockupAssignedUsers.removeWhere((element) => element == userId);
        //now assign the new list to the project
        await mockupCollection
            .doc(selectedMockup.uid)
            .update({'assignedWorkers': mockupAssignedUsers}).catchError(
                (err) => print('Could not update project assigned workers'));
      }

      //now we need to remove the assigned project from the user's document
      var assignedMockup =
          await userCollection.doc(removedUser.uid).get().then((value) {
        var data = value.data() as Map<String, dynamic>;
        return data['assignedMockup'];
      });

      for (var mockup in assignedMockup) {
        print('the mockup: ${mockup['id']} - ${selectedMockup.uid} - $userId');
        print(
            'the mockup: ${selectedMockup.uid} ${selectedMockup.mockupName} ${selectedMockup.mockupAddress} ${selectedMockup.radius}');
        if (mockup['id'] == selectedMockup.uid) {
          result = await userCollection
              .doc(userId)
              .update({
                'assignedMockup': FieldValue.arrayRemove([
                  {
                    'id': selectedMockup.uid,
                    'name': selectedMockup.mockupName,
                    'projectAddress': selectedMockup.mockupAddress,
                    'radius': selectedMockup.radius,
                  }
                ])
              })
              .then((value) => 'Deleted User')
              .catchError((err) => 'Error: $err');
        }
      }

      return result;
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      print('An error removing users: $e');
      return 'Error: $e';
    }
  }

  //read mockup
  //Get projects through streams and Futures
  Stream<List<MockupData>> getAllMockups() {
    return mockupCollection.snapshots().map(_listMockupDataFromSnapshot);
  }

  Stream<MockupData> getMockupById({String mockupId}) {
    return mockupCollection
        .doc(mockupId)
        .snapshots()
        .map(_mockupDataFromSnapshot);
  }

  Future<MockupData> getMockupByIdFuture({String mockupId}) async {
    try {
      var result = await mockupCollection.doc(mockupId).get().then((data) {
        var result = MockupData(
            uid: data.id,
            mockupName: data['name'],
            mockupDetails: data['details'],
            mockupAddress: data['address'],
            radius: data['radius'],
            contactorCompany: data['contractor'],
            contactPerson: data['contactPerson'],
            emailAddress: data['emailAddress'],
            phoneNumber: PhoneNumber(
                phoneNumber: data['phoneNumber']['phoneNumber'],
                isoCode: data['phoneNumber']['isoCode'],
                dialCode: data['phoneNumber']['dialCode']),
            userId: data['salesInCharge'],
            mockupStatus: data['status'],
            assignedWorkers: data['assignedWorkers']);
        return result;
      });

      return result;
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      print('An error obtaining project: $e');
      return MockupData(error: e);
    }
  }

  List<MockupData> _listMockupDataFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((snapshot) {
      var data = snapshot.data() as Map<String, dynamic>;
      return MockupData(
          uid: snapshot.id,
          mockupName: data['name'],
          mockupDetails: data['details'],
          mockupAddress: data['address'],
          radius: data['radius'],
          contactorCompany: data['contractor'],
          contactPerson: data['contactPerson'],
          emailAddress: data['emailAddress'],
          phoneNumber: PhoneNumber(
              phoneNumber: data['phoneNumber']['phoneNumber'],
              isoCode: data['phoneNumber']['isoCode'],
              dialCode: data['phoneNumber']['dialCode']),
          userId: data['salesInCharge'],
          mockupStatus: data['status'],
          assignedWorkers: data['assignedWorkers']);
    }).toList();
  }

  MockupData _mockupDataFromSnapshot(DocumentSnapshot snapshot) {
    var data = snapshot.data() as Map<String, dynamic>;
    return MockupData(
      uid: snapshot.id,
      mockupName: data['name'],
      mockupDetails: data['details'],
      mockupAddress: data['address'],
      radius: data['radius'],
      contactorCompany: data['contractor'],
      contactPerson: data['contactPerson'],
      emailAddress: data['emailAddress'],
      phoneNumber: PhoneNumber(
          phoneNumber: data['phoneNumber']['phoneNumber'],
          isoCode: data['phoneNumber']['isoCode'],
          dialCode: data['phoneNumber']['dialCode']),
      userId: data['salesInCharge'],
      mockupStatus: data['status'],
      assignedWorkers: data['assignedWorkers'],
    );
  }

  //Delete mockup
  Future<String> deleteMockup({String mockupId}) async {
    try {
      return await mockupCollection
          .doc(mockupId)
          .delete()
          .then((value) => 'Deleted');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error Deleting: $e';
    }
  }

  //generating time sheet report
  //Adding a new entry to the collection
  Future<String> setWorkerTimeSheet(
      {UserData currentUser,
      String today,
      ProjectData selectedProject,
      MockupData selectedMockup,
      bool isAtSite,
      String checkIn,
      String checkOut,
      String userRole}) async {
    try {
      return await timeSheetCollection.doc(today).set({
        currentUser.uid: {
          'firstName': currentUser.firstName,
          'lastName': currentUser.lastName,
          'projectId': selectedProject != null
              ? selectedProject.uid
              : selectedMockup.uid,
          'projectName': selectedProject != null
              ? selectedProject.projectName
              : selectedMockup.mockupName,
          'arriving_at': checkIn,
          'leaving_at': checkOut,
          'isOnSite': isAtSite,
          'role': userRole
        }
      }).then((value) => 'time sheet updated');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error setting: $e';
    }
  }

  //updating the current entry
  Future<String> updateWorkerTimeSheet({
    UserData currentUser,
    String userRole,
    String today,
    ProjectData selectedProject,
    MockupData selectedMockup,
    bool isAtSite,
    String checkIn,
    String checkOut,
    String workType,
    double squareMeters,
  }) async {
    try {
      print(
          'the current User: ${currentUser.uid} - $selectedProject - $selectedMockup');

      return await timeSheetCollection.doc(today).update({
        currentUser.uid: {
          'firstName': currentUser.firstName,
          'lastName': currentUser.lastName,
          'projectId': selectedProject != null
              ? selectedProject.uid
              : selectedMockup.uid,
          'projectName': selectedProject != null
              ? selectedProject.projectName
              : selectedMockup.mockupName,
          'arriving_at': checkIn,
          'leaving_at': checkOut,
          'isOnSite': isAtSite,
          'roles': userRole,
          'workCompleted': {
            'workType': workType,
            'sqaureMeters': squareMeters,
          }
        }
      }).then((value) => 'time sheet updated');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error updating: $e';
    }
  }

  //Add the mason's work to the time sheet
  Future<String> updateMasonWork({
    UserData currentUser,
    String today,
    String workType,
    double sqaureMeters,
  }) async {
    try {
      return await timeSheetCollection.doc(today).update({
        currentUser.uid: {
          'completedWork': {
            'workType': workType,
            'sqaureMetere': sqaureMeters,
          }
        }
      }).then((value) => 'time sheet updated');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error updating: $e';
    }
  }

  //reading the current entry
  Future<Map<String, dynamic>> getCurrentTimeSheet({String today}) async {
    try {
      return await timeSheetCollection
          .doc(today)
          .get()
          .then((value) => {'data': value.data()})
          .catchError((err) => {'status': 'empty'});
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return {'Error': e};
    }
  }

  Future<Map<String, dynamic>> getRangeTimeSheets(
      {String uid, List<String> roles, String reportSection}) async {
    try {
      return await timeSheetCollection.doc(uid).get().then((value) {
        Map<String, dynamic> reportList = {};
        var result = value.data() as Map<String, dynamic>;
        if (result.keys != null) {
          var keys = result.keys;
          var data = <String, dynamic>{};
          for (var key in keys) {
            if (result[key]['roles'] == reportSection) {
              //we need to add the data of the related user
              data.addAll({
                key: {
                  'arriving_at': result[key]['arriving_at'],
                  'leaving_at': result[key]['leaving_at'],
                  'isOnSite': result[key]['isOnSite'],
                  'firstName': result[key]['firstName'],
                  'lastName': result[key]['lastName'],
                  'projectId': result[key]['projectId'],
                  'projectName': result[key]['projectName'],
                  'roles': result[key]['roles'],
                  'workCompleted': result[key]['workCompleted']
                }
              });

              reportList.addAll({'id': value.id, 'data': data});
            }
          }

          return reportList;
        }
        return null;
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return {};
    }
  }

  Stream<Map<String, dynamic>> getTimeSheetData({String uid}) {
    return timeSheetCollection
        .doc(uid)
        .snapshots()
        .map(_timeSheetDataFromSnapshot);
  }

  Map<String, dynamic> _timeSheetDataFromSnapshot(DocumentSnapshot snapshot) {
    var data = snapshot.data() as Map<String, dynamic>;
    return data;
  }

  //sales user pipeline
  //add a sales visit
  Future<String> addNewSalesVisit(
      {String userId,
      ClientData selectedClient,
      ProjectData selectedProject,
      String contact,
      String visitPurpose,
      String visitDetails,
      DateTime visitTime,
      String visitType}) async {
    try {
      var visitCollection;
      if (visitType == 'Client') {
        visitCollection = 'clientVisits';
      } else {
        visitCollection = 'projectVisits';
      }

      return await userCollection.doc(userId).collection(visitCollection).add({
        'uid':
            selectedClient != null ? selectedClient.uid : selectedProject.uid,
        'name': selectedClient != null
            ? selectedClient.clientName
            : selectedProject.projectName,
        'contact': contact,
        'visitPurpose': visitPurpose,
        'visitDetails': visitDetails,
        'visitTime': visitTime,
        'userId': userId,
      }).then((value) => 'Document added Successfully');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      print('the error: $e');
      return e;
    }
  }

  //update a sales visit
  Future<String> updateNewSalesVisit(
      {String visitId,
      String userId,
      ClientData selectedClient,
      ProjectData selectedProject,
      String contact,
      String visitPurpose,
      String visitDetails,
      String managerComments,
      String visitType}) async {
    try {
      var visitCollection;
      if (visitType == 'Clients') {
        visitCollection = 'clientVisits';
      } else {
        visitCollection = 'projectVisits';
      }

      return await userCollection
          .doc(userId)
          .collection(visitCollection)
          .doc(visitId)
          .update({
        'uid':
            selectedClient != null ? selectedClient.uid : selectedProject.uid,
        'name': selectedClient != null
            ? selectedClient.clientName
            : selectedProject.projectName,
        'contact': contact,
        'visitPurpose': visitPurpose,
        'visitDetails': visitDetails,
        'managerComments': managerComments,
      }).then((value) => 'Document updated Successfully');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return e;
    }
  }

  //update manager note or visit details
  Future<String> updateCurrentSalesVisit(
      {String visitId,
      String userId,
      String managerComments,
      String visitType,
      String visitDetails}) async {
    try {
      var subCollection;
      if (visitType == 'Client') {
        subCollection = 'clientVisits';
      } else {
        subCollection = 'projectVisits';
      }

      return await userCollection
          .doc(userId)
          .collection(subCollection)
          .doc(visitId)
          .update({
        'visitDetails': visitDetails,
        'managerComments': managerComments,
      }).then((value) => 'Document updated Successfully');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      print('Error updating visit: $e');
      return e;
    }
  }

  //stream sales visits for clients
  Stream<List<ClientVisitDetails>> getSalesVisitDetailsStream(
      {String userId, DateTime fromDate, DateTime toDate}) {
    return userCollection
        .doc(userId)
        .collection('clientVisits')
        .snapshots()
        .map((event) {
      return event.docs.map((value) {
        var data = value.data();

        if (fromDate.isBefore(data['visitTime'].toDate()) &&
            toDate.isAfter(data['visitTime'].toDate())) {
          return ClientVisitDetails(
              uid: value.id,
              clientId: data['uid'],
              clientName: data['name'],
              contactPerson: data['contact'],
              visitDetails: data['visitDetails'],
              visitPurpose: data['visitPurpose'],
              managerComments: data['managerComments'],
              userId: data['userId'],
              visitTime: data['visitTime']);
        } else {
          return null;
        }
      }).toList();
    });
  }

  //stream sales visit for projects
  Stream<List<ProjectVisitDetails>> getSalesVisitDetailsStreamProjects(
      {String userId, DateTime fromDate, DateTime toDate}) {
    return userCollection
        .doc(userId)
        .collection('projectVisits')
        .snapshots()
        .map((event) {
      return event.docs.map((value) {
        var data = value.data();

        if (fromDate.isBefore(data['visitTime'].toDate()) &&
            toDate.isAfter(data['visitTime'].toDate())) {
          var result = ProjectVisitDetails(
              uid: value.id,
              projectId: data['uid'],
              projectName: data['name'],
              contactPerson: data['contact'],
              visitDetails: data['visitDetails'],
              visitPurpose: data['visitPurpose'],
              userId: data['userId'],
              managerComments: data['managerComments'],
              visitTime: data['visitTime']);
          return result;
        } else {
          return null;
        }
      }).toList();
    });
  }

  //read client visits in a future with a date range
  Future<List<ClientVisitDetails>> getTimeRangedClientVisitsFuture(
      {String userId, DateTime fromDate, DateTime toDate}) async {
    try {
      return await userCollection
          .doc(userId)
          .collection('clientVisits')
          .where('visitTime', isGreaterThanOrEqualTo: fromDate)
          .where('visitTime', isLessThanOrEqualTo: toDate)
          .get()
          .then((value) {
        return value.docs.map((e) {
          return ClientVisitDetails(
            uid: e.id,
            clientId: e.data()['uid'],
            clientName: e.data()['name'],
            contactPerson: e.data()['contact'],
            visitPurpose: e.data()['visitPurpose'],
            visitDetails: e.data()['visitDetails'],
            visitTime: e.data()['visitTime'].toDate().toString().split(' ')[0],
          );
        }).toList();
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return [ClientVisitDetails(error: e)];
    }
  }

  //read project visits in a future date range
  Future<List<ProjectVisitDetails>> getTimeRangedProjectVisitsFuture(
      {String userId, DateTime fromDate, DateTime toDate}) async {
    try {
      return await userCollection
          .doc(userId)
          .collection('projectVisits')
          .where('visitTime', isGreaterThanOrEqualTo: fromDate)
          .where('visitTime', isLessThanOrEqualTo: toDate)
          .get()
          .then((value) {
        return value.docs.map((e) {
          return ProjectVisitDetails(
              uid: e.id,
              projectId: e['uid'],
              projectName: e['name'],
              contactPerson: e['contact'],
              visitDetails: e['visitDetails'],
              visitPurpose: e['visitPurpose'],
              userId: e['userId'],
              // managerComments: e['managerComments'] ?? '',
              visitTime: e['visitTime'].toDate().toString().split(' ')[0]);
        }).toList();
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);

      return [ProjectVisitDetails(error: e)];
    }
  }

  //read a sales visit
  Future<List<ClientVisitDetails>> getSalesVisitDetails({String userId}) async {
    try {
      return await userCollection
          .doc(userId)
          .collection('clientVisit')
          .get()
          .then((value) {
        return value.docs.map((e) {
          return ClientVisitDetails(
            uid: e.id,
            clientId: e.data()['clientId'],
            clientName: e.data()['clientName'],
            contactPerson: e.data()['contactPerson'],
            visitPurpose: e.data()['visitPurpose'],
            visitDetails: e.data()['visitDetails'],
            visitTime: e.data()['visitTime'],
          );
        }).toList();
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return [ClientVisitDetails(error: e)];
    }
  }

  List<ClientVisitDetails> _listVisitDetailsMap(QuerySnapshot snapshot) {
    return snapshot.docs.map((value) {
      var data = value.data() as Map<String, dynamic>;
      var result = ClientVisitDetails(
          uid: value.id,
          clientId: data['clientId'],
          clientName: data['clientName'],
          visitDetails: data['visitDetails'],
          visitPurpose: data['visitPurpose'],
          visitTime: data['visitTime']);

      return result;
    }).toList();
  }

  //Helper collection allows to add, read, update and delete helpers
  Future<String> addNewHelper(
      {String firstName, String lastName, String mobileNumber}) async {
    try {
      return await helperCollection.add({
        'firstName': firstName,
        'lastName': lastName,
        'mobileNumber': mobileNumber,
      }).then((value) => 'Helper Added Sucessfully');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error Adding Helper: $e';
    }
  }

  Future<String> updateHelper(
      {String uid,
      String firstName,
      String lastName,
      String mobileNumber}) async {
    try {
      return await helperCollection.doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'mobileNumber': mobileNumber,
      }).then((value) => 'Helper Updated Sucessfully');
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return 'Error Updating Helper: $e';
    }
  }

  //Read helper data
  Future<Helpers> readSingleHelper({String uid}) async {
    try {
      return await helperCollection.doc(uid).get().then((value) {
        var data = value.data() as Map<String, dynamic>;
        return Helpers(
            uid: value.id,
            firstName: data['firstName'],
            lastName: data['lastName'],
            mobileNumber: data['mobileNumber']);
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return Helpers();
    }
  }

  Future<void> deleteHelper({String uid}) async {
    try {
      await helperCollection.doc(uid).delete();
    } catch (e, stackTrace) {
      print('Error deleting helper: $e');
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  Future<List<Helpers>> getAssignedHelper() async {
    try {
      return helperCollection.get().then((value) => value.docs.map((e) {
            var data = e.data() as Map<String, dynamic>;
            return Helpers(
                uid: e.id,
                firstName: data['firstName'],
                lastName: data['lastName'],
                mobileNumber: data['mobileNumber']);
          }).toList());
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return [];
    }
  }

  Stream<List<Helpers>> streamAllHelpers() {
    return helperCollection.snapshots().map(_mapAllHelpersData);
  }

  List<Helpers> _mapAllHelpersData(QuerySnapshot snapshot) {
    return snapshot.docs.map((value) {
      var data = value.data() as Map<String, dynamic>;
      return Helpers(
          uid: value.id,
          firstName: data['firstName'],
          lastName: data['lastName'],
          mobileNumber: data['mobileNumber']);
    }).toList();
  }
}
