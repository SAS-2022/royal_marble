class UserData {
  String? uid;
  String? firstName;
  String? lastName;
  String? emailAddress;
  String? phoneNumber;
  Map<String, dynamic>? homeAddress;
  Map<String, dynamic>? currentLocation;
  Map<String, dynamic>? location;
  List<dynamic>? roles;
  Map<String, dynamic>? nationality;
  var assignedProject;
  var assignedMockups;
  var distanceToProject;
  String? company;
  bool? isActive;
  String? imageUrl;
  String? permissionStatus;
  List<dynamic>? assingedHelpers;
  String? error;

  UserData({
    this.uid,
    this.firstName,
    this.lastName,
    this.emailAddress,
    this.phoneNumber,
    this.homeAddress,
    this.currentLocation,
    this.location,
    this.roles,
    this.nationality,
    this.company,
    this.isActive,
    this.assignedProject,
    this.assignedMockups,
    this.distanceToProject,
    this.imageUrl,
    this.permissionStatus,
    this.assingedHelpers,
    this.error,
  });

  @override
  String toString() {
    return 'UserData(uid: $uid, firstName: $firstName, lastName: $lastName, emailAddress: $emailAddress, phoneNumber: $phoneNumber, homeAddress: $homeAddress, currentLocation: $currentLocation, roles: $roles, nationality: $nationality, assignedProject: $assignedProject, assignedHelper: $assingedHelpers, company: $company, isActive: $isActive, error: $error)';
  }
}

class Helpers {
  String? uid;
  String? firstName;
  String? lastName;
  String? mobileNumber;
  Helpers({
    this.uid,
    this.firstName,
    this.lastName,
    this.mobileNumber,
  });
}
