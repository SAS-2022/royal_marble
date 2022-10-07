import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/account_settings/users_details.dart';
import 'package:royal_marble/shared/constants.dart';

import '../models/user_model.dart';

class UserList extends StatefulWidget {
  const UserList({Key key}) : super(key: key);

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  List<UserData> listOfUsers = [];
  Size size;
  @override
  Widget build(BuildContext context) {
    listOfUsers = Provider.of<List<UserData>>(context);
    size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return SingleChildScrollView(
        child: listOfUsers.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text('There are no current users'),
                ),
              )
            : Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                    child: Text(
                      'These are the list of current users who have registered to the company',
                      style: textStyle6,
                    ),
                  ),
                  SizedBox(
                    height: size.height - 40,
                    child: ListView.builder(
                        itemCount: listOfUsers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(),
                                  borderRadius: BorderRadius.circular(25)),
                              child: GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserDetails(
                                        currentUser: listOfUsers[index],
                                        myAccount: false,
                                      ),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.person,
                                    size: 50,
                                  ),
                                  title: Text(
                                      '${listOfUsers[index].firstName} ${listOfUsers[index].lastName}'),
                                  subtitle: SizedBox(
                                      height: 40,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Email Address: ${listOfUsers[index].emailAddress}'),
                                          Text(
                                              'Phone Number: ${listOfUsers[index].phoneNumber}')
                                        ],
                                      )),
                                ),
                              ),
                            ),
                          );
                        }),
                  ),
                ],
              ));
  }
}
