import 'package:flutter/material.dart';
import 'package:royal_marble/account_settings/users_details.dart';
import 'package:royal_marble/account_settings/users_grid.dart';
import 'package:royal_marble/clients/clients_form.dart';
import 'package:royal_marble/clients/clients_grid.dart';
import 'package:royal_marble/location/show_map.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/sales_pipeline/visit_forms.dart/visit_form_streams.dart';

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
                widget.currentUser.roles.contains('isAdmin') ||
                        widget.currentUser.roles.contains('isSales')
                    ? ExpansionTile(
                        leading: const Icon(
                          Icons.business,
                        ),
                        title: const Text('Clients'),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.add_business),
                            title: const Text('Add New Client'),
                            enabled: true,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ClientForm(
                                          isNewClient: true,
                                          currentUser: widget.currentUser,
                                        )),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.business_center_rounded),
                            title: const Text('View Client'),
                            enabled: true,
                            onTap: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ClientGrid(
                                            currentUser: widget.currentUser,
                                          )));
                            },
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),

                widget.currentUser.roles.contains('isAdmin') ||
                        widget.currentUser.roles.contains('isSales')
                    ? ExpansionTile(
                        leading: const Icon(
                          Icons.account_tree,
                        ),
                        title: const Text('Sales Pipeline'),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.app_registration),
                            title: const Text('New Visit'),
                            enabled: true,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VisitFormStreams(
                                    currentUser: widget.currentUser,
                                  ),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.apps_outage_outlined),
                            title: const Text('View Visits'),
                            enabled: true,
                            onTap: () async {},
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                widget.currentUser.roles.contains('isAdmin')
                    ? ExpansionTile(
                        leading: const Icon(
                          Icons.account_tree,
                        ),
                        title: const Text('Map'),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.maps_home_work),
                            title: const Text('User Map'),
                            enabled: true,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ShowMap(
                                          currentUser: widget.currentUser,
                                          listOfMarkers: 'users',
                                        )),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.map_outlined),
                            title: const Text('Client Map'),
                            enabled: true,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ShowMap(
                                          currentUser: widget.currentUser,
                                          listOfMarkers: 'clients',
                                        )),
                              );
                            },
                          ),
                        ],
                      )
                    : const SizedBox.shrink()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
