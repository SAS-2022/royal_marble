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
  Map<String, dynamic> projectAddress;
  String contactorCompany;
  String contactPerson;
  String phoneNumber;
  String emailAddress;
  List<dynamic> projectVisits;
  String userId;
  ProjectData({
    this.uid,
    this.projectName,
    this.projectAddress,
    this.contactorCompany,
    this.contactPerson,
    this.phoneNumber,
    this.emailAddress,
    this.projectVisits,
    this.userId,
  });
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
