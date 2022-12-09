import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/directions.dart';
import 'package:royal_marble/sales_pipeline/visit_forms.dart/visit_form_one.dart';
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
            distanceToProject: data['distanceToProject'],
            currentLocation: data['currentLocation'],
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
      distanceToProject: data['distanceToProject'],
      currentLocation: data['currentLocation'],
      imageUrl: data['imageUrl'],
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
        distanceToProject: data['distanceToProject'],
        currentLocation: data['currentLocation'],
        imageUrl: data['imageUrl'],
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
              imageUrl: data['imageUrl'],
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
        'phoneNumber': project.phoneNumber,
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
      List<String> selectedUserIds,
      List<UserData> removedUsers}) async {
    try {
      print('the project Id: ${project.uid}');
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
            await userCollection
                .doc(user.uid)
                .update({'assignedProject': {}})
                .then((value) => print(
                    'the user ${user.firstName} ${user.lastName} was removed'))
                .catchError((err) => print(
                    'Error remove user ${user.firstName} ${user.lastName}'));
          }
        }
        //add new users
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

  //removing users from a selected project
  Future<String> removeUserFromProject(
      {ProjectData selectedProject, String userId}) async {
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
          await userCollection.doc(userId).get().then((value) {
        var data = value.data() as Map<String, dynamic>;
        return data['assignedProject'];
      });

      if (assignedProject['id'] == selectedProject.uid) {
        result = await userCollection
            .doc(userId)
            .update({'assignedProject': {}})
            .then((value) => 'Deleted User')
            .catchError((err) => 'Error: $err');
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
            phoneNumber: data['phoneNumber'],
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
          phoneNumber: data['phoneNumber'],
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

  //generating time sheet report
  //Adding a new entry to the collection
  Future<String> setWorkerTimeSheet(
      {UserData currentUser,
      String today,
      ProjectData selectedProject,
      bool isAtSite,
      String checkIn,
      String checkOut,
      String userRole}) async {
    try {
      return await timeSheetCollection.doc(today).set({
        currentUser.uid: {
          'firstName': currentUser.firstName,
          'lastName': currentUser.lastName,
          'projectId': selectedProject.uid,
          'projectName': selectedProject.projectName,
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
    bool isAtSite,
    String checkIn,
    String checkOut,
  }) async {
    try {
      return await timeSheetCollection.doc(today).update({
        currentUser.uid: {
          'firstName': currentUser.firstName,
          'lastName': currentUser.lastName,
          'projectId': selectedProject.uid,
          'projectName': selectedProject.projectName,
          'arriving_at': checkIn,
          'leaving_at': checkOut,
          'isOnSite': isAtSite,
          'roles': userRole
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
        var keys = result.keys;

        for (var key in keys) {
          if (result[key]['roles'] == reportSection) {
            reportList.addAll({'id': value.id, 'data': value.data()});
          }
        }

        return reportList;
      });
    } catch (e, stackTrace) {
      await sentry.Sentry.captureException(e, stackTrace: stackTrace);
      return {};
    }
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
}
