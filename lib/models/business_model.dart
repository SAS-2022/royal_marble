import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class ClientData {
  String? uid;
  String? clientName;
  Map<String, dynamic>? clientAddress;
  String? contactPerson;
  PhoneNumber? phoneNumber;
  String? emailAddress;
  List<dynamic>? clientVisits;
  String? userId;
  String? error;
  ClientData({
    this.uid,
    this.clientName,
    this.clientAddress,
    this.phoneNumber,
    this.contactPerson,
    this.emailAddress,
    this.clientVisits,
    this.userId,
    this.error,
  });
}

PhoneNumber? _phone(dynamic v) => v is Map
    ? PhoneNumber(
        phoneNumber: v['phoneNumber'] as String?,
        isoCode: v['isoCode'] as String?,
        dialCode: v['dialCode'] as String?)
    : null;

double? _double(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

class ProjectData {
  String? uid;
  String? projectName;
  String? projectDetails;
  Map<String, dynamic>? projectAddress;
  double? radius;
  String? contactorCompany;
  String? contactPerson;
  PhoneNumber? phoneNumber;
  String? emailAddress;
  List<dynamic>? projectVisits;
  String? userId;
  List<dynamic>? assignedWorkers;
  String? projectStatus;
  String? error;
  ProjectData(
      {this.uid,
      this.projectName,
      this.projectDetails,
      this.projectAddress,
      this.radius,
      this.contactorCompany,
      this.contactPerson,
      this.phoneNumber,
      this.emailAddress,
      this.projectVisits,
      this.userId,
      this.assignedWorkers,
      this.projectStatus,
      this.error});

  /// From a `projects/{id}` document. Tolerates fields older versions left
  /// out or stored as another type (a whole-number radius, no phone).
  factory ProjectData.fromMap(String id, Map<String, dynamic>? d) {
    if (d == null) return ProjectData(uid: id, error: 'not-found');
    return ProjectData(
      uid: id,
      projectName: d['projectName'] as String?,
      projectDetails: d['projectDetails'] as String?,
      projectAddress: _map(d['selectedAddress']),
      radius: _double(d['radius']),
      contactorCompany: d['contractor'] as String?,
      contactPerson: d['contactPerson'] as String?,
      emailAddress: d['emailAddress'] as String?,
      phoneNumber: _phone(d['phoneNumber']),
      userId: d['salesInCharge'] as String?,
      projectStatus: d['status'] as String?,
      assignedWorkers: d['assignedWorkers'] as List?,
    );
  }

  @override
  String toString() {
    return 'ProjectData(uid: $uid, projectName: $projectName, projectDetails: $projectDetails, projectAddress: $projectAddress, radius: $radius, contactorCompany: $contactorCompany, contactPerson: $contactPerson, phoneNumber: $phoneNumber, emailAddress: $emailAddress, projectVisits: $projectVisits, userId: $userId, assignedWorkers: $assignedWorkers, projectStatus: $projectStatus, error: $error)';
  }
}

class MockupData {
  String? uid;
  String? mockupName;
  String? mockupDetails;
  Map<String, dynamic>? mockupAddress;
  double? radius;
  String? contactorCompany;
  String? contactPerson;
  PhoneNumber? phoneNumber;
  String? emailAddress;
  List<dynamic>? projectVisits;
  String? userId;
  List<dynamic>? assignedWorkers;
  String? mockupStatus;
  String? error;
  MockupData(
      {this.uid,
      this.mockupName,
      this.mockupDetails,
      this.mockupAddress,
      this.radius,
      this.contactorCompany,
      this.contactPerson,
      this.phoneNumber,
      this.emailAddress,
      this.projectVisits,
      this.userId,
      this.assignedWorkers,
      this.mockupStatus,
      this.error});

  /// From a `mockup/{id}` document; see [ProjectData.fromMap].
  factory MockupData.fromMap(String id, Map<String, dynamic>? d) {
    if (d == null) return MockupData(uid: id, error: 'not-found');
    return MockupData(
      uid: id,
      mockupName: d['name'] as String?,
      mockupDetails: d['details'] as String?,
      mockupAddress: _map(d['address']),
      radius: _double(d['radius']),
      contactorCompany: d['contractor'] as String?,
      contactPerson: d['contactPerson'] as String?,
      emailAddress: d['emailAddress'] as String?,
      phoneNumber: _phone(d['phoneNumber']),
      userId: d['salesInCharge'] as String?,
      mockupStatus: d['status'] as String?,
      assignedWorkers: d['assignedWorkers'] as List?,
    );
  }

  @override
  String toString() {
    return 'MockupData(uid: $uid, mockupName: $mockupName, mockUpDetails: $mockupDetails, mockUpAddress: $mockupAddress, radius: $radius, contactorCompany: $contactorCompany, contactPerson: $contactPerson, phoneNumber: $phoneNumber, emailAddress: $emailAddress, projectVisits: $projectVisits, userId: $userId, assignedWorkers: $assignedWorkers, mockupStatus: $mockupStatus, error: $error)';
  }
}

class ClientVisitDetails {
  String? uid;
  String? userId;
  String? clientId;
  String? clientName;
  String? visitPurpose;
  String? visitDetails;
  String? contactPerson;
  String? managerComments;
  var visitTime;
  String? error;
  ClientVisitDetails({
    this.uid,
    this.userId,
    this.clientId,
    this.clientName,
    this.visitPurpose,
    this.visitDetails,
    this.contactPerson,
    this.visitTime,
    this.managerComments,
    this.error,
  });

  @override
  String toString() {
    return 'ClientVisitDetails(uid: $uid, userId: $userId, clientId: $clientId, clientName: $clientName, visitPurpose: $visitPurpose, visitDetails: $visitDetails, contactPerson: $contactPerson, managerComments: $managerComments, visitTime: $visitTime, error: $error)';
  }
}

class ProjectVisitDetails {
  String? uid;
  String? userId;
  String? projectId;
  String? projectName;
  String? visitPurpose;
  String? visitDetails;
  String? contactPerson;
  String? managerComments;
  var visitTime;
  String? error;
  ProjectVisitDetails({
    this.uid,
    this.userId,
    this.projectId,
    this.projectName,
    this.visitPurpose,
    this.visitDetails,
    this.contactPerson,
    this.visitTime,
    this.managerComments,
    this.error,
  });

  @override
  String toString() {
    return 'ProjectVisitDetails(uid: $uid, userId: $userId, projectId: $projectId, projectName: $projectName, visitPurpose: $visitPurpose, visitDetails: $visitDetails, contactPerson: $contactPerson, managerComments: $managerComments, visitTime: $visitTime, error: $error)';
  }
}

class TimeSheet {
  Map<String, dynamic>? userData;
  TimeSheet({
    this.userData,
  });
}
