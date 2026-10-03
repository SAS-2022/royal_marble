import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/directions.dart';
import 'package:royal_marble/core/error_reporter.dart';
import '../models/attendance.dart' show siteAssignments;
import '../models/user_model.dart';

class DatabaseService {
  String? uid;
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
    String? uid,
    String? firstName,
    String? lastName,
    String? company,
    bool? isActive,
    String? phoneNumber,
    String? emailAddress,
    List<dynamic>? roles,
    String? imageUrl,
    Map<String, dynamic>? nationality,
    Map<String, dynamic>? homeAddress,
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
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return ' $e';
    }
  }

  //update the user's live location
  Future<String> updateUserLiveLocation(
      {String? uid, LatLng? currentLocation, double? distance}) async {
    try {
      Map<String, dynamic> newLoc = {
        'Lat': currentLocation!.latitude,
        'Lng': currentLocation.longitude,
      };
      return await userCollection.doc(uid).update({
        'currentLocation': newLoc,
        'distanceToProject': distance,
      }).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return ' $e';
    }
  }

  //mirror the latest background-geolocation fix to users/{uid}/location/current
  Future<void> saveTrackedLocation(
      {required String uid, required Map<dynamic, dynamic> location}) async {
    try {
      await userCollection
          .doc(uid)
          .collection('location')
          .doc('current')
          .set({'location': location});
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
    }
  }

  //update user location permission status
  Future<void> updateUserPermissionStatus(
      {String? uid, ph.PermissionStatus? permissionStatus}) async {
    try {
      await userCollection
          .doc(uid)
          .update({'locationPermission': permissionStatus.toString()}).then(
              (value) => 'Permission Status updated');
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
    }
  }

  //delete a user
  Future<String> deleteUser({String? uid}) async {
    try {
      return await userCollection
          .doc(uid)
          .delete()
          .then((value) => 'User deleted');
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //activate or deactivate a user
  Future<String> activateDeactivateUser({String? uid, bool? active}) async {
    try {
      return await userCollection
          .doc(uid)
          .update({'isActive': active}).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //update current user role
  Future<String> assignUserRole({String? selectedRole, String? uid}) async {
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
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //Update a user with helpers
  Future<String> updateUserWithHelpers(
      {String? uid, List<dynamic>? helpers}) async {
    try {
      return await userCollection
          .doc(uid)
          .update({'assignedHelpers': helpers}).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //assign user to a project
  Future<String> assignUsersToProject(
      {List<UserData>? userIds, ProjectData? project}) async {
    String? result;
    try {
      for (UserData user in userIds!) {
        Map<String, dynamic> projectDetails = {
          'projectId': project!.uid,
          'Lat': project.projectAddress!['Lat'],
          'Lng': project.projectAddress!['Lng'],
          'radius': project.radius,
        };
        result = await userCollection.doc(user.uid).update(
            {'assignedProject': projectDetails}).then((value) => 'Completed');
      }
      return result.toString();
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //read the users data through futures and streams
  //stream user data
  Stream<UserData> getUserPerId({String? uid}) {
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

  Stream<List<CustomMarker>> getAllUsersLocation({String? userId}) {
    return userCollection
        .doc(userId)
        .collection('location')
        .limit(1)
        .snapshots()
        .map(_allUserLocationDataFromSnapshot);
  }

  //Get users depending on their role
  Future<List<UserData>> getUsersPerRole({String? userRole}) async {
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
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserLocationFuture({String? usersId}) async {
    return await userCollection
        .doc(usersId)
        .collection('location')
        .doc('current')
        .get()
        .then((value) {
      if (value.data() != null) {
        return {
          'uuid': value.data()!['location']['uuid'],
          'lat': value.data()!['location']['coords']['latitude'],
          'lng': value.data()!['location']['coords']['longitude'],
          'speed': value.data()!['location']['coords']['speed'] ?? '',
          'activity': value.data()!['location']['activity']['type'] ?? '',
          'charging': value.data()!['location']['battery']['is_charging'] ?? '',
          'battery': value.data()!['location']['battery']['level'] ?? '',
          'isMoving': value.data()!['location']['is_moving'] ?? '',
          'enabled': value.data()!['location']['provider'] != null
              ? value.data()!['location']['provider']['enabled']
              : '',
          'network': value.data()!['location']['provider'] != null
              ? value.data()!['location']['provider']['network']
              : '',
          'gps': value.data()!['location']['provider'] != null
              ? value.data()!['location']['provider']['gps']
              : '',
          'time': value.data()!['location']['timestamp'] ?? ''
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

  Future<UserData> getUserByIdFuture({String? uid}) async {
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
            deviceStatus: (data.data() as Map<String, dynamic>?)?['deviceStatus'],
            assingedHelpers: data['assignedHelpers'] ?? [],
            imageUrl: data['imageUrl']);
      });
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return UserData(error: e.toString());
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
      deviceStatus: data['deviceStatus'],
      language: data['language'],
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
        deviceStatus: data['deviceStatus'],
        language: data['language'],
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
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return [];
    }
  }

  //The below section will allow us to handle clients changes
  //adding clients
  Future<String> addNewClients({ClientData? client}) async {
    try {
      return await clientCollection.add({
        'clientName': client!.clientName,
        'clientAddress': client.clientAddress,
        'contactPerson': client.contactPerson,
        'phoneNumber': {
          'phoneNumber': client.phoneNumber!.phoneNumber,
          'dialCode': client.phoneNumber!.dialCode,
          'isoCode': client.phoneNumber!.isoCode,
        },
        'emailAddress': client.emailAddress,
        'userId': client.userId,
      }).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //updating clients
  Future<String> updateClientData({ClientData? client}) async {
    try {
      return await clientCollection.doc(client!.uid).update({
        'clientName': client.clientName,
        'clientAddress': client.clientAddress,
        'contactPerson': client.contactPerson,
        'phoneNumber': {
          'phoneNumber': client.phoneNumber!.phoneNumber,
          'dialCode': client.phoneNumber!.dialCode,
          'isoCode': client.phoneNumber!.isoCode,
        },
        'emailAddress': client.emailAddress,
        'userId': client.userId,
      }).then((value) => 'Completed');
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //deleting clients
  Future<void> deleteClient({String? clientId}) async {
    try {
      await clientCollection.doc(clientId).delete();
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
    }
  }

  //reading through streams and futures
  Stream<List<ClientData>> getClientsPerUser({String? userId}) {
    var result = clientCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_listClientDataFromSnapshot);
    return result;
  }

  Stream<ClientData> getClientPerId({String? uid}) {
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
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<List<ClientData>> getSalesUserClientFuture({String? userId}) async {
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
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Adds or removes one site in a user's `assignedProject` /
  /// `assignedMockup`. Always stores a list (older versions kept a single map
  /// for masons, which moved them off their other site) and matches by site
  /// id, so a site renamed since the assignment is still removed.
  Future<void> _setAssignment(String uid, String field,
          Map<String, dynamic> site, {required bool assign}) =>
      FirebaseFirestore.instance.runTransaction((tx) async {
        final ref = userCollection.doc(uid);
        final data = (await tx.get(ref)).data() as Map<String, dynamic>?;
        final sites = siteAssignments(data?[field])
          ..removeWhere((a) => a['id'] == site['id']);
        if (assign) sites.add(site);
        tx.update(ref, {field: sites});
      });

  Map<String, dynamic> _projectSite(ProjectData p) => {
        'id': p.uid,
        'name': p.projectName,
        'projectAddress': p.projectAddress,
        'radius': p.radius,
      };

  Map<String, dynamic> _mockupSite(MockupData m) => {
        'id': m.uid,
        'name': m.mockupName,
        'projectAddress': m.mockupAddress,
        'radius': m.radius,
      };

  /// Sets a project's team to [selectedUserIds] and updates each added or
  /// removed user's assignments. Workers keep their other sites.
  Future<String> updateProjectWithWorkers(
      {ProjectData? project,
      List<UserData>? addedUsers,
      List<String>? selectedUserIds,
      List<UserData>? removedUsers}) async {
    try {
      await projectCollection
          .doc(project!.uid)
          .update({'assignedWorkers': selectedUserIds});
      final site = _projectSite(project);
      for (final u in removedUsers ?? const <UserData>[]) {
        await _setAssignment(u.uid!, 'assignedProject', site, assign: false);
      }
      for (final u in addedUsers ?? const <UserData>[]) {
        await _setAssignment(u.uid!, 'assignedProject', site, assign: true);
      }
      return 'Completed';
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  //Get projects through streams and Futures
  Stream<List<ProjectData>> getAllProjects() {
    return projectCollection.snapshots().map(_listProjectDataFromSnapshot);
  }

  Stream<ProjectData> getProjectById({String? projectId}) {
    return projectCollection
        .doc(projectId)
        .snapshots()
        .map(_projectDataFromSnapshot);
  }

  List<ProjectData> _listProjectDataFromSnapshot(QuerySnapshot snapshot) => [
        for (final d in snapshot.docs)
          ProjectData.fromMap(d.id, d.data() as Map<String, dynamic>?)
      ];

  ProjectData _projectDataFromSnapshot(DocumentSnapshot snapshot) =>
      ProjectData.fromMap(snapshot.id, snapshot.data() as Map<String, dynamic>?);

  /// Sets a mock-up's team to [selectedUserIds] and updates each added or
  /// removed user's assignments.
  Future<String> updateMockupWithWorkers(
      {MockupData? mockup,
      List<UserData>? addedUsers,
      List<String>? selectedUserIds,
      List<UserData>? removedUsers}) async {
    try {
      await mockupCollection
          .doc(mockup!.uid)
          .update({'assignedWorkers': selectedUserIds});
      final site = _mockupSite(mockup);
      for (final u in removedUsers ?? const <UserData>[]) {
        await _setAssignment(u.uid!, 'assignedMockup', site, assign: false);
      }
      for (final u in addedUsers ?? const <UserData>[]) {
        await _setAssignment(u.uid!, 'assignedMockup', site, assign: true);
      }
      return 'Completed';
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  /// Firestore field names of a site document, which differ between
  /// projects and mock-ups.
  static ({String col, String name, String details, String address}) siteFields(
          bool mockup) =>
      mockup
          ? (col: 'mockup', name: 'name', details: 'details', address: 'address')
          : (col: 'projects', name: 'projectName', details: 'projectDetails',
              address: 'selectedAddress');

  /// Creates (no [id]) or updates a project or mock-up. When the name, pin or
  /// radius change, every assigned worker's copy of the site is refreshed too,
  /// because tracking and check-in read those copies. Returns the site id.
  Future<String> saveSite({
    required bool mockup,
    String? id,
    required String name,
    required String details,
    required Map<String, dynamic> address,
    required double radius,
    required String status,
    String? contractor,
    String? contactPerson,
    Map<String, dynamic>? phone,
    String? email,
    String? createdBy,
  }) async {
    final f = siteFields(mockup);
    final col = FirebaseFirestore.instance.collection(f.col);
    final data = {
      f.name: name,
      f.details: details,
      f.address: address,
      'radius': radius,
      'status': status,
      'contractor': contractor,
      'contactPerson': contactPerson,
      'phoneNumber': phone,
      'emailAddress': email,
    };
    if (id == null) {
      final ref = await col.add({
        ...data,
        'assignedWorkers': <String>[],
        'salesInCharge': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    }
    await col.doc(id).update(data);
    final workers = ((await col.doc(id).get()).data()?['assignedWorkers'] as List?) ?? [];
    final site = {
      'id': id,
      'name': name,
      'projectAddress': address,
      'radius': radius,
    };
    for (final uid in workers) {
      await _setAssignment('$uid', mockup ? 'assignedMockup' : 'assignedProject',
          site, assign: true);
    }
    return id;
  }

  Future<void> setSiteStatus(
          {required bool mockup, required String id, required String status}) =>
      FirebaseFirestore.instance
          .collection(siteFields(mockup).col)
          .doc(id)
          .update({'status': status});

  /// Deletes a site after removing it from every assigned worker. Past
  /// timesheets keep the site's name, so reports still read correctly.
  Future<void> deleteSite({required bool mockup, required String id}) async {
    final ref = FirebaseFirestore.instance.collection(siteFields(mockup).col).doc(id);
    final workers = ((await ref.get()).data()?['assignedWorkers'] as List?) ?? [];
    for (final uid in workers) {
      await _setAssignment('$uid', mockup ? 'assignedMockup' : 'assignedProject',
          {'id': id}, assign: false);
    }
    await ref.delete();
  }

  //read mockup
  //Get projects through streams and Futures
  Stream<List<MockupData>> getAllMockups() {
    return mockupCollection.snapshots().map(_listMockupDataFromSnapshot);
  }

  Stream<MockupData> getMockupById({String? mockupId}) {
    return mockupCollection
        .doc(mockupId)
        .snapshots()
        .map(_mockupDataFromSnapshot);
  }

  List<MockupData> _listMockupDataFromSnapshot(QuerySnapshot snapshot) => [
        for (final d in snapshot.docs)
          MockupData.fromMap(d.id, d.data() as Map<String, dynamic>?)
      ];

  MockupData _mockupDataFromSnapshot(DocumentSnapshot snapshot) =>
      MockupData.fromMap(snapshot.id, snapshot.data() as Map<String, dynamic>?);

  //generating time sheet report
  //Adding a new entry to the collection
  Future<String> setWorkerTimeSheet(
      {UserData? currentUser,
      String? today,
      ProjectData? selectedProject,
      MockupData? selectedMockup,
      bool? isAtSite,
      String? checkIn,
      String? checkOut,
      String? userRole}) async {
    try {
      return await timeSheetCollection.doc(today).set({
        currentUser!.uid: {
          'firstName': currentUser.firstName,
          'lastName': currentUser.lastName,
          'projectId': selectedProject != null
              ? selectedProject.uid
              : selectedMockup!.uid,
          'projectName': selectedProject != null
              ? selectedProject.projectName
              : selectedMockup!.mockupName,
          'arriving_at': checkIn,
          'leaving_at': checkOut,
          'isOnSite': isAtSite,
          'role': userRole
        }
      }).then((value) => 'time sheet updated');
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error setting: $e';
    }
  }

  //updating the current entry
  Future<String> updateWorkerTimeSheet({
    UserData? currentUser,
    String? userRole,
    String? today,
    ProjectData? selectedProject,
    MockupData? selectedMockup,
    bool? isAtSite,
    String? checkIn,
    String? checkOut,
    String? workType,
    double? squareMeters,
  }) async {
    try {
      return await timeSheetCollection.doc(today).update({
        currentUser!.uid!: {
          'firstName': currentUser.firstName,
          'lastName': currentUser.lastName,
          'projectId': selectedProject != null
              ? selectedProject.uid
              : selectedMockup!.uid,
          'projectName': selectedProject != null
              ? selectedProject.projectName
              : selectedMockup!.mockupName,
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
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error updating: $e';
    }
  }

  //Add the mason's work to the time sheet
  Future<String> updateMasonWork({
    UserData? currentUser,
    String? today,
    String? workType,
    double? sqaureMeters,
  }) async {
    try {
      return await timeSheetCollection.doc(today).update({
        currentUser!.uid!: {
          'completedWork': {
            'workType': workType,
            'sqaureMetere': sqaureMeters,
          }
        }
      }).then((value) => 'time sheet updated');
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error updating: $e';
    }
  }

  //reading the current entry
  Future<Map<String, dynamic>> getCurrentTimeSheet({String? today}) async {
    try {
      return await timeSheetCollection
          .doc(today)
          .get()
          .then((value) => {'data': value.data()})
          .catchError((err) => {'status': 'empty'});
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return {'Error': e};
    }
  }

  Future<Map<String, dynamic>> getRangeTimeSheets(
      {String? uid, List<String>? roles, String? reportSection}) async {
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
        return {};
      });
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return {};
    }
  }

  Stream<Map<String, dynamic>> getTimeSheetData({String? uid}) {
    return timeSheetCollection
        .doc(uid)
        .snapshots()
        .map(_timeSheetDataFromSnapshot);
  }

  Map<String, dynamic> _timeSheetDataFromSnapshot(DocumentSnapshot snapshot) {
    var data = snapshot.data() as Map<String, dynamic>? ?? {};
    return data;
  }

  //sales user pipeline
  //add a sales visit
  Future<String> addNewSalesVisit(
      {String? userId,
      ClientData? selectedClient,
      ProjectData? selectedProject,
      String? contact,
      String? visitPurpose,
      String? visitDetails,
      DateTime? visitTime,
      String? visitType}) async {
    try {
      var visitCollection;
      if (visitType == 'Client') {
        visitCollection = 'clientVisits';
      } else {
        visitCollection = 'projectVisits';
      }

      return await userCollection.doc(userId).collection(visitCollection).add({
        'uid':
            selectedClient != null ? selectedClient.uid : selectedProject!.uid,
        'name': selectedClient != null
            ? selectedClient.clientName
            : selectedProject!.projectName,
        'contact': contact,
        'visitPurpose': visitPurpose,
        'visitDetails': visitDetails,
        'visitTime': visitTime,
        'userId': userId,
      }).then((value) => 'Document added Successfully');
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      print('the error: $e');
      return e.toString();
    }
  }

  //update a sales visit
  Future<String> updateNewSalesVisit(
      {String? visitId,
      String? userId,
      ClientData? selectedClient,
      ProjectData? selectedProject,
      String? contact,
      String? visitPurpose,
      String? visitDetails,
      String? managerComments,
      String? visitType}) async {
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
            selectedClient != null ? selectedClient.uid : selectedProject!.uid,
        'name': selectedClient != null
            ? selectedClient.clientName
            : selectedProject!.projectName,
        'contact': contact,
        'visitPurpose': visitPurpose,
        'visitDetails': visitDetails,
        'managerComments': managerComments,
      }).then((value) => 'Document updated Successfully');
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return e.toString();
    }
  }

  //update manager note or visit details
  Future<String> updateCurrentSalesVisit(
      {String? visitId,
      String? userId,
      String? managerComments,
      String? visitType,
      String? visitDetails}) async {
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
      await ErrorReporter.record(e, stackTrace: stackTrace);

      return e.toString();
    }
  }

  //stream sales visits for clients
  Stream<List<ClientVisitDetails?>> getSalesVisitDetailsStream(
      {String? userId, DateTime? fromDate, DateTime? toDate}) {
    return userCollection
        .doc(userId)
        .collection('clientVisits')
        .orderBy('visitTime', descending: false)
        .snapshots()
        .map((event) {
      return event.docs.map((value) {
        var data = value.data();

        if (fromDate!.isBefore(data['visitTime'].toDate()) &&
            toDate!.isAfter(data['visitTime'].toDate())) {
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
  Stream<List<ProjectVisitDetails?>> getSalesVisitDetailsStreamProjects(
      {String? userId, DateTime? fromDate, DateTime? toDate}) {
    return userCollection
        .doc(userId)
        .collection('projectVisits')
        .orderBy('visitTime', descending: false)
        .snapshots()
        .map((event) {
      return event.docs.map((value) {
        var data = value.data();

        if (fromDate!.isBefore(data['visitTime'].toDate()) &&
            toDate!.isAfter(data['visitTime'].toDate())) {
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
      {String? userId, DateTime? fromDate, DateTime? toDate}) async {
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
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return [ClientVisitDetails(error: e.toString())];
    }
  }

  //read project visits in a future date range
  Future<List<ProjectVisitDetails>> getTimeRangedProjectVisitsFuture(
      {String? userId, DateTime? fromDate, DateTime? toDate}) async {
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
      await ErrorReporter.record(e, stackTrace: stackTrace);

      return [ProjectVisitDetails(error: e.toString())];
    }
  }

  //read a sales visit
  Future<List<ClientVisitDetails>> getSalesVisitDetails(
      {String? userId}) async {
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
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return [ClientVisitDetails(error: e.toString())];
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
      {String? firstName, String? lastName, String? mobileNumber}) async {
    try {
      return await helperCollection.add({
        'firstName': firstName,
        'lastName': lastName,
        'mobileNumber': mobileNumber,
      }).then((value) => 'Helper Added Sucessfully');
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error Adding Helper: $e';
    }
  }

  Future<String> updateHelper(
      {String? uid,
      String? firstName,
      String? lastName,
      String? mobileNumber}) async {
    try {
      return await helperCollection.doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'mobileNumber': mobileNumber,
      }).then((value) => 'Helper Updated Sucessfully');
    } catch (e, stackTrace) {
      await ErrorReporter.record(e, stackTrace: stackTrace);
      return 'Error Updating Helper: $e';
    }
  }

  /// Deletes a helper and takes them off every mason they were assigned to.
  Future<void> deleteHelperEverywhere(String helperId) async {
    final masons =
        await userCollection.where('assignedHelpers', arrayContains: helperId).get();
    for (final m in masons.docs) {
      await m.reference.update({
        'assignedHelpers': FieldValue.arrayRemove([helperId])
      });
    }
    await helperCollection.doc(helperId).delete();
  }

  /// Saves a user's own editable profile fields (not role or access).
  Future<void> updateMyProfile(String uid, Map<String, dynamic> fields) =>
      userCollection.doc(uid).update(fields);

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
