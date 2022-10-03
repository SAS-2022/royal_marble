class UserData {
  String uid;
  String firstName;
  String lastName;
  String emailAddress;
  String phoneNumber;
  Map<String, dynamic> homeAddress;
  List<dynamic> roles;

  UserData({
    this.uid,
    this.firstName,
    this.lastName,
    this.emailAddress,
    this.phoneNumber,
    this.homeAddress,
    this.roles,
  });
}
