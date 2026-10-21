class UserData {
  String? uid;
  String? firstName;
  String? lastName;
  String? emailAddress;

  /// Set for people added by an admin or HR who sign in with a username.
  String? username;
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
  Map<String, dynamic>? deviceStatus;
  String? language;
  List<dynamic>? assingedHelpers;
  String? error;

  UserData({
    this.uid,
    this.firstName,
    this.lastName,
    this.emailAddress,
    this.username,
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
    this.deviceStatus,
    this.language,
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
