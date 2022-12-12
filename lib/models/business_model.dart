import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class ClientData {
  String uid;
  String clientName;
  Map<String, dynamic> clientAddress;
  String contactPerson;
  PhoneNumber phoneNumber;
  String emailAddress;
  List<dynamic> clientVisits;
  String userId;
  String error;
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

class ProjectData {
  String uid;
  String projectName;
  String projectDetails;
  Map<String, dynamic> projectAddress;
  double radius;
  String contactorCompany;
  String contactPerson;
  PhoneNumber phoneNumber;
  String emailAddress;
  List<dynamic> projectVisits;
  String userId;
  List<dynamic> assignedWorkers;
  String projectStatus;
  String error;
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

  @override
  String toString() {
    return 'ProjectData(uid: $uid, projectName: $projectName, projectDetails: $projectDetails, projectAddress: $projectAddress, radius: $radius, contactorCompany: $contactorCompany, contactPerson: $contactPerson, phoneNumber: $phoneNumber, emailAddress: $emailAddress, projectVisits: $projectVisits, userId: $userId, assignedWorkers: $assignedWorkers, projectStatus: $projectStatus, error: $error)';
  }
}

class ClientVisitDetails {
  String uid;
  String userId;
  String clientId;
  String clientName;
  String visitPurpose;
  String visitDetails;
  String contactPerson;
  String managerComments;
  var visitTime;
  String error;
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
  String uid;
  String userId;
  String projectId;
  String projectName;
  String visitPurpose;
  String visitDetails;
  String contactPerson;
  String managerComments;
  var visitTime;
  String error;
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
  Map<String, dynamic> userData;
  TimeSheet({
    this.userData,
  });
}
