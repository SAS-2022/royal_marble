class ClientData {
  String uid;
  String clientName;
  Map<String, dynamic> clientAddress;
  String phoneNumber;
  String emailAddress;
  List<dynamic> clientVisits;
  ClientData({
    this.uid,
    this.clientName,
    this.clientAddress,
    this.phoneNumber,
    this.emailAddress,
    this.clientVisits,
  });
}

class ProjectData {
  String uid;
  String projectName;
  Map<String, dynamic> projectAddress;
  String contactPerson;
  String phoneNumber;
  String emailAddress;
  List<dynamic> projectVisits;
  ProjectData({
    this.uid,
    this.projectName,
    this.projectAddress,
    this.contactPerson,
    this.phoneNumber,
    this.emailAddress,
    this.projectVisits,
  });
}
