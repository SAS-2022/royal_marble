import 'package:flutter/material.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/snack_bar.dart';

class UserDetails extends StatefulWidget {
  const UserDetails({Key key, this.currentUser, this.myAccount})
      : super(key: key);
  final UserData currentUser;
  final bool myAccount;

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  Size _size;
  DatabaseService db = DatabaseService();
  SnackBarWidget _snackBarWidget = SnackBarWidget();

  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: SingleChildScrollView(
          child:
              widget.myAccount ? _buildMyUserDetails() : _buildUserDetails()),
    );
  }

  Widget _buildUserDetails() {
    return Padding(
      padding: const EdgeInsets.only(top: 35, left: 25, right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'First Name: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.firstName,
                style: textStyle3,
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Last Name: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.lastName,
                style: textStyle3,
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Phone Number: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.phoneNumber,
                style: textStyle3,
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Email Address: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.emailAddress,
                style: textStyle3,
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Nationality: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.nationality,
                style: textStyle3,
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Company: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.company,
                style: textStyle3,
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Home Address: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.homeAddress != null
                    ? widget.currentUser.homeAddress['name']
                    : 'address not assigned',
                style: textStyle3,
              )
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Text(
                'Active User: ',
                style: textStyle5,
              ),
              Text(
                widget.currentUser.isActive.toString(),
                style: textStyle3,
              )
            ],
          ),
          const Divider(height: 30, thickness: 3),
          //the below code will be functions for the admin to do
          //Activate or deactivate an account
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'The following button will allow you to grant access and remove it from a selected user',
                style: textStyle6,
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: widget.currentUser.isActive
                          ? Colors.red[400]
                          : Colors.green[400],
                      fixedSize: Size(_size.width / 2, 45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25))),
                  onPressed: () async {
                    var result = await db.activateDeactivateUser(
                        uid: widget.currentUser.uid,
                        active: !widget.currentUser.isActive);
                    if (result == 'Completed') {
                      Navigator.pop(context);
                    } else {
                      _snackBarWidget.content =
                          'failed to deactivate account, please contact developer';
                      _snackBarWidget.showSnack();
                    }
                  },
                  child: widget.currentUser.isActive
                      ? const Text(
                          'Deactivate',
                          style: textStyle2,
                        )
                      : const Text(
                          'Activate',
                          style: textStyle2,
                        ))
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          //Delete an account
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'The following button will allow you to delete a current user (A user has to be deactivated before they can be deleted)',
                style: textStyle6,
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: widget.currentUser.isActive
                          ? Colors.grey[300]
                          : Colors.red[400],
                      fixedSize: Size(_size.width / 2, 45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25))),
                  onPressed: widget.currentUser.isActive ? null : () async {},
                  child: const Text(
                    'Delete',
                    style: textStyle2,
                  ))
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyUserDetails() {
    return Column();
  }
}
