import 'package:flutter/material.dart';
import 'package:royal_marble/account_settings/users_details.dart';
import 'package:royal_marble/account_settings/users_grid.dart';
import 'package:royal_marble/models/user_model.dart';

class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({Key key, this.currentUser}) : super(key: key);
  final UserData currentUser;

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  Size size;

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 2 / 3,
      child: Drawer(
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: SizedBox(
            child: ListView(
              children: [
                //The logo on top
                Padding(
                  padding: const EdgeInsets.only(
                      left: 25, top: 20, bottom: 40, right: 35),
                  child: Image.asset('assets/images/logo_1.jpg'),
                ),
                //account or profile settings
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile Settings'),
                  enabled: true,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetails(
                          currentUser: widget.currentUser,
                          myAccount: true,
                        ),
                      ),
                    );
                  },
                ),
                //Add the user control settings
                widget.currentUser.roles.contains('isAdmin')
                    ? ListTile(
                        leading: const Icon(Icons.people),
                        title: const Text('Users'),
                        enabled: true,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserGrid(
                                currentUser: widget.currentUser,
                              ),
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
