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
  List<UserData> nonActiveUser = [];
  Size size;
  @override
  Widget build(BuildContext context) {
    listOfUsers = Provider.of<List<UserData>>(context)
        .where((element) => element.isActive == true)
        .toList();
    nonActiveUser = Provider.of<List<UserData>>(context)
        .where((element) => element.isActive == false)
        .toList();
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
                      'List of non-active users who have registered to the company',
                      style: textStyle6,
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(
                        height: nonActiveUser.isNotEmpty
                            ? (size.height / 2) - 10
                            : size.height / 6,
                        child: nonActiveUser.isNotEmpty
                            ? ListView.builder(
                                itemCount: nonActiveUser.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 20),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(),
                                          borderRadius:
                                              BorderRadius.circular(25)),
                                      child: GestureDetector(
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => UserDetails(
                                                currentUser:
                                                    nonActiveUser[index],
                                                myAccount: false,
                                              ),
                                            ),
                                          );
                                        },
                                        child: ListTile(
                                          leading: nonActiveUser[index]
                                                      .imageUrl ==
                                                  null
                                              ? const CircleAvatar(
                                                  radius: 30,
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 50,
                                                  ),
                                                )
                                              : CircleAvatar(
                                                  radius: 30,
                                                  backgroundImage: NetworkImage(
                                                    nonActiveUser[index]
                                                        .imageUrl,
                                                    scale: 2,
                                                  )),
                                          title: Text(
                                              '${nonActiveUser[index].firstName} ${nonActiveUser[index].lastName}'),
                                          subtitle: SizedBox(
                                              height: 60,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      'Email Address: ${nonActiveUser[index].emailAddress}'),
                                                  Text(
                                                      'Phone Number: ${nonActiveUser[index].phoneNumber}')
                                                ],
                                              )),
                                        ),
                                      ),
                                    ),
                                  );
                                })
                            : const Center(
                                child: Text('There are no non-active users'),
                              ),
                      ),
                      const Divider(
                        height: 10,
                        thickness: 3,
                      ),
                      Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 20),
                            child: Text(
                              'List of active users for the company',
                              style: textStyle6,
                            ),
                          ),
                          SizedBox(
                            height: listOfUsers.isNotEmpty
                                ? (size.height / 2) - 10
                                : size.height / 6,
                            child: listOfUsers.isNotEmpty
                                ? ListView.builder(
                                    itemCount: listOfUsers.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 20),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(),
                                              borderRadius:
                                                  BorderRadius.circular(25)),
                                          child: GestureDetector(
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => UserDetails(
                                                    currentUser:
                                                        listOfUsers[index],
                                                    myAccount: false,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: ListTile(
                                              leading:
                                                  listOfUsers[index].imageUrl ==
                                                          null
                                                      ? const CircleAvatar(
                                                          radius: 30,
                                                          child: Icon(
                                                            Icons.person,
                                                            size: 50,
                                                          ),
                                                        )
                                                      : CircleAvatar(
                                                          radius: 30,
                                                          backgroundImage:
                                                              NetworkImage(
                                                            listOfUsers[index]
                                                                .imageUrl,
                                                            scale: 2,
                                                          )),
                                              title: Text(
                                                  '${listOfUsers[index].firstName} ${listOfUsers[index].lastName}'),
                                              subtitle: SizedBox(
                                                  height: 60,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
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
                                    })
                                : const Center(
                                    child: Text('There are no active users'),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ));
  }
}
