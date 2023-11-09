import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/account_settings/users_details.dart';
import 'package:royal_marble/shared/constants.dart';

import '../models/user_model.dart';

class UserList extends StatefulWidget {
  const UserList({Key? key, this.currentUser}) : super(key: key);
  final UserData? currentUser;
  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  List<UserData> listOfUsers = [];
  List<UserData> nonActiveUser = [];
  double listOfUsersHeight = 100.00;
  final _searchController = TextEditingController();
  List<UserData>? _searchResult = [];
  bool _emptySearchResults = false;
  Size? size;

  @override
  void initState() {
    super.initState();
    _onSearchTextChnaged('');
  }

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
    if (listOfUsers.isNotEmpty && nonActiveUser.isNotEmpty) {
      listOfUsersHeight = (size!.height / 2) - 40;
    } else if (listOfUsers.isNotEmpty && nonActiveUser.isEmpty) {
      listOfUsersHeight = size!.height - 100;
    } else if (listOfUsers.isEmpty && nonActiveUser.isNotEmpty) {
      listOfUsersHeight = size!.height / 4;
    } else {
      listOfUsersHeight = size!.height;
    }

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
                  Column(
                    children: [
                      nonActiveUser.isNotEmpty
                          ? Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 20),
                                  child: Text(
                                    'Non-active users at Royal Marble. Total: ${nonActiveUser.length}',
                                    style: textStyle6,
                                  ),
                                ),
                                SizedBox(
                                  height: nonActiveUser.isNotEmpty
                                      ? (size!.height / 3) - 10
                                      : size!.height / 6,
                                  child: nonActiveUser.isNotEmpty
                                      ? ListView.builder(
                                          itemCount: nonActiveUser.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15,
                                                      vertical: 20),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    border: Border.all(),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25)),
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            UserDetails(
                                                          currentUser: widget
                                                              .currentUser,
                                                          myAccount: false,
                                                          selectedUser:
                                                              nonActiveUser[
                                                                  index],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: ListTile(
                                                    leading: nonActiveUser[
                                                                    index]
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
                                                            backgroundImage:
                                                                NetworkImage(
                                                              nonActiveUser[
                                                                      index]
                                                                  .imageUrl,
                                                              scale: 2,
                                                            )),
                                                    title: Text(
                                                        '${nonActiveUser[index].firstName} ${nonActiveUser[index].lastName}'),
                                                    subtitle: SizedBox(
                                                        height: 60,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
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
                                          child: Text(
                                              'There are no non-active users'),
                                        ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      const Divider(
                        height: 10,
                        thickness: 3,
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 15),
                            child: TextField(
                              autofocus: false,
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search',
                                filled: true,
                                fillColor: Colors.grey[100],
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                  borderSide: const BorderSide(width: 1.0),
                                ),
                              ),
                              onChanged: (val) {
                                _onSearchTextChnaged(val.toString());
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 20),
                            child: Text(
                              'Active users at Royal Marble. Total: ${listOfUsers.length}',
                              style: textStyle6,
                            ),
                          ),
                          SizedBox(
                            height: listOfUsersHeight,
                            child: _searchResult != null &&
                                    _searchResult!.isNotEmpty
                                ? ListView.builder(
                                    // shrinkWrap: true,
                                    itemCount: _searchResult!.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 10),
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
                                                        widget.currentUser,
                                                    myAccount: false,
                                                    selectedUser:
                                                        _searchResult![index],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: ListTile(
                                              leading: _searchResult![index]
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
                                                      backgroundImage:
                                                          NetworkImage(
                                                        _searchResult![index]
                                                            .imageUrl,
                                                        scale: 2,
                                                      )),
                                              title: Text(
                                                  '${_searchResult![index].firstName} ${_searchResult![index].lastName}'),
                                              subtitle: SizedBox(
                                                  height: 60,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          'Email Address: ${_searchResult![index].emailAddress}'),
                                                      Text(
                                                          'Phone Number: ${_searchResult![index].phoneNumber}')
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

  //will show the User name relative the the typed data in the search field
  void _onSearchTextChnaged(String text) {
    List<UserData> results = [];
    // _searchResult.clear();
    if (text.isEmpty) {
      //waits for the stream provider to load
      Future.delayed(const Duration(milliseconds: 750), () {
        setState(() {
          _searchResult = listOfUsers;
        });
      });
      return;
    }
    results = listOfUsers
        .where((user) => '${user.firstName} ${user.lastName}'
            .toString()
            .toLowerCase()
            .contains(text.toLowerCase()))
        .toList();
    setState(() {
      _searchResult = results;
      if (_searchResult!.isEmpty) {
        _emptySearchResults = true;
      } else {
        _emptySearchResults = false;
      }
    });
  }
}
