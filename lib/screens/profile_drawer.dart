import 'package:flutter/material.dart';
import 'package:royal_marble/account_settings/users_details.dart';
import 'package:royal_marble/account_settings/users_grid.dart';
import 'package:royal_marble/clients/clients_form.dart';
import 'package:royal_marble/clients/clients_grid.dart';
import 'package:royal_marble/location/map_providers.dart';
import 'package:royal_marble/location/show_map.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/reports/report_grid.dart';
import 'package:royal_marble/sales_pipeline/visit_forms.dart/visit_form_streams.dart';
import 'package:royal_marble/services/auth.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({Key key, this.currentUser, this.allUsers})
      : super(key: key);
  final UserData currentUser;
  final List<UserData> allUsers;

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  Size size;
  final db = DatabaseService();
  final _auth = AuthService();
  SharedPreferences _pref;

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 2 / 3,
      child: widget.currentUser.roles != null
          ? Drawer(
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
                      widget.currentUser != null
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Center(
                                child: Text(
                                  '${widget.currentUser.firstName} ${widget.currentUser.lastName}',
                                  style: textStyle16,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      const Divider(
                        endIndent: 15,
                        indent: 15,
                        height: 5,
                        thickness: 3,
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
                          //Adding a new client
                          ? ExpansionTile(
                              iconColor:
                                  const Color.fromARGB(255, 191, 180, 66),
                              textColor:
                                  const Color.fromARGB(255, 191, 180, 66),
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
                                //Viewing current clients
                                ListTile(
                                  leading:
                                      const Icon(Icons.business_center_rounded),
                                  title: const Text('View Client'),
                                  enabled: true,
                                  onTap: () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => ClientGrid(
                                                  currentUser:
                                                      widget.currentUser,
                                                )));
                                  },
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),

                      //Will show the current project
                      widget.currentUser.roles.contains('isAdmin') ||
                              widget.currentUser.roles.contains('isSales')
                          //Adding a new project
                          ? ExpansionTile(
                              iconColor:
                                  const Color.fromARGB(255, 191, 180, 66),
                              textColor:
                                  const Color.fromARGB(255, 191, 180, 66),
                              leading: const Icon(
                                Icons.build,
                              ),
                              title: const Text('Projects'),
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.add_location),
                                  title: const Text('New Project'),
                                  enabled: true,
                                  onTap: () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => MapProviders(
                                                  currentUser:
                                                      widget.currentUser,
                                                  addNewProject: true,
                                                  addNewMockup: false,
                                                  listOfMarkers: 'Add Project',
                                                )));
                                  },
                                ),

                                //For mock ups only
                                ListTile(
                                  leading: const Icon(Icons.add_location),
                                  title: const Text('New Mock-up'),
                                  enabled: true,
                                  onTap: () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => MapProviders(
                                                  currentUser:
                                                      widget.currentUser,
                                                  addNewProject: false,
                                                  addNewMockup: true,
                                                  listOfMarkers: 'Add Mockup',
                                                )));
                                  },
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),

                      widget.currentUser.roles.contains('isAdmin') ||
                              widget.currentUser.roles.contains('isSales')
                          ? ExpansionTile(
                              iconColor:
                                  const Color.fromARGB(255, 191, 180, 66),
                              textColor:
                                  const Color.fromARGB(255, 191, 180, 66),
                              leading: const Icon(
                                Icons.account_tree,
                              ),
                              title: const Text('Sales Pipeline'),
                              children: [
                                //Adding a new client visit
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
                                          viewingVisit: false,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                //Visiting the current client
                                ListTile(
                                  leading:
                                      const Icon(Icons.apps_outage_outlined),
                                  title: const Text('View Visits'),
                                  enabled: true,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VisitFormStreams(
                                          currentUser: widget.currentUser,
                                          viewingVisit: true,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),

                      widget.currentUser.roles.contains('isAdmin')
                          ? ExpansionTile(
                              iconColor:
                                  const Color.fromARGB(255, 191, 180, 66),
                              textColor:
                                  const Color.fromARGB(255, 191, 180, 66),
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
                                          builder: (_) => MapProviders(
                                                allUsers: widget.allUsers,
                                                currentUser: widget.currentUser,
                                                listOfMarkers: 'users',
                                                addNewProject: false,
                                                addNewMockup: false,
                                              )),
                                    );
                                  },
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      //This section will hold the report that will be generated by the app
                      widget.currentUser.roles.contains('isAdmin')
                          ? ExpansionTile(
                              iconColor:
                                  const Color.fromARGB(255, 191, 180, 66),
                              textColor:
                                  const Color.fromARGB(255, 191, 180, 66),
                              leading: const Icon(
                                Icons.document_scanner,
                              ),
                              title: const Text('Reports'),
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.construction),
                                  title: const Text('Site Report'),
                                  enabled: true,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => ReportGrid(
                                                currentUser: widget.currentUser,
                                                reportType: 'site',
                                              )),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.sell),
                                  title: const Text('Sales Report'),
                                  enabled: true,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => ReportGrid(
                                                currentUser: widget.currentUser,
                                                reportType: 'sales',
                                              )),
                                    );
                                  },
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),

                      const SizedBox(
                        height: 35,
                      ),
                      Center(
                        child: SizedBox(
                          width: size.width / 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 56, 52, 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              ),
                            ),
                            onPressed: () async {
                              await _auth.signOut();
                              //clear sharedpreference data
                              _pref = await SharedPreferences.getInstance();
                              _pref.clear();
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/home', (route) => false);
                            },
                            child: const Text('Sign Out'),
                          ),
                        ),
                      )
                      // : const SizedBox.shrink()
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
