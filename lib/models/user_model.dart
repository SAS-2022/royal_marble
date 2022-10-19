class UserData {
  String uid;
  String firstName;
  String lastName;
  String emailAddress;
  String phoneNumber;
  Map<String, dynamic> homeAddress;
  Map<String, dynamic> currentLocation;
  List<dynamic> roles;
  Map<String, dynamic> nationality;
  Map<String, dynamic> assignedProject;
  String company;
  bool isActive;
  String error;

  UserData({
    this.uid,
    this.firstName,
    this.lastName,
    this.emailAddress,
    this.phoneNumber,
    this.homeAddress,
    this.currentLocation,
    this.roles,
    this.nationality,
    this.company,
    this.isActive,
    this.assignedProject,
    this.error,
  });
}
