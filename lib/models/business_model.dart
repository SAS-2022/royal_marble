class ClientData {
  String uid;
  String clientName;
  Map<String, dynamic> clientAddress;
  String contactPerson;
  String phoneNumber;
  String emailAddress;
  List<dynamic> clientVisits;
  String userId;
  ClientData({
    this.uid,
    this.clientName,
    this.clientAddress,
    this.phoneNumber,
    this.contactPerson,
    this.emailAddress,
    this.clientVisits,
    this.userId,
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
  String phoneNumber;
  String emailAddress;
  List<dynamic> projectVisits;
  String userId;
  List<dynamic> assignedWorkers;
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
      this.error});
}

class VisitDetails {
  String visitContent;
  String contactPerson;
  DateTime visitTime;
  VisitDetails({
    this.visitContent,
    this.contactPerson,
    this.visitTime,
  });
}
