class UserData {
  String uid;
  String firstName;
  String lastName;
  String emailAddress;
  String phoneNumber;
  Map<String, dynamic> homeAddress;
  List<dynamic> roles;
  bool isActive;
  String error;

  UserData({
    this.uid,
    this.firstName,
    this.lastName,
    this.emailAddress,
    this.phoneNumber,
    this.homeAddress,
    this.roles,
    this.isActive,
    this.error,
  });
}
