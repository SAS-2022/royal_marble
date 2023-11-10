import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/loading.dart';

import '../shared/snack_bar.dart';

class HelperProvider extends StatelessWidget {
  const HelperProvider({Key? key, this.currentUser, this.selectedUser})
      : super(key: key);
  final UserData? currentUser;
  final UserData? selectedUser;
  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<Helpers>>.value(
      initialData: const [],
      value: DatabaseService().streamAllHelpers(),
      catchError: ((context, error) {
        return [];
      }),
      child: HelpersPage(
        currentUser: currentUser!,
        selectedUsers: selectedUser!,
      ),
    );
  }
}

class HelpersPage extends StatefulWidget {
  const HelpersPage({Key? key, this.currentUser, this.selectedUsers})
      : super(key: key);
  final UserData? currentUser;
  final UserData? selectedUsers;
  @override
  State<HelpersPage> createState() => _HelpersPageState();
}

class _HelpersPageState extends State<HelpersPage> {
  DatabaseService db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  List<Helpers>? helperProvider;
  Helpers? selectedHelper;
  bool _helperSelected = false;
  Size? _size;
  TextEditingController helperFirstName = TextEditingController();
  TextEditingController helperLastName = TextEditingController();
  TextEditingController helperPhone = TextEditingController();
  final _snackBarWidget = SnackBarWidget();
  bool _isLoading = false;
  List<dynamic> assignedHelpers = [];

  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;

    if (widget.selectedUsers!.assingedHelpers != null) {
      assignedHelpers = widget.selectedUsers!.assingedHelpers!;
    }
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    helperProvider = Provider.of<List<Helpers>>(context);
    return Scaffold(
      appBar: AppBar(
        title: widget.currentUser!.roles!.contains('isAdmin')
            ? const Text(
                'Assign Helpers',
              )
            : const Text(
                'Assigned Helpers',
              ),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
        actions: [
          //Save changes
          widget.currentUser!.roles!.contains('isAdmin')
              ? TextButton(
                  onPressed: () async {
                    //will save the new helpers to the current user
                    if (assignedHelpers.length <= 2) {
                      var result = await db.updateUserWithHelpers(
                          uid: widget.selectedUsers!.uid!,
                          helpers: assignedHelpers);
                      Navigator.pop(context);
                      _snackBarWidget.content = result;
                    } else {
                      _snackBarWidget.content =
                          'Helpers should be at least one and no more than 2';
                    }

                    _snackBarWidget.showSnack();
                  },
                  child: const Text(
                    'Save',
                    style: textStyle2,
                  ))
              : const SizedBox.shrink()
        ],
      ),
      body: widget.currentUser!.roles!.contains('isAdmin')
          ? _buildHelperAdminPageBody()
          : _buildHelperNormalPageBody(),
    );
  }

  Widget _buildHelperNormalPageBody() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: SingleChildScrollView(
        child: SizedBox(
          height: _size!.height,
          child: ListView.builder(
              itemCount: assignedHelpers.length,
              itemBuilder: (context, index) {
                return FutureBuilder(
                    future: db.readSingleHelper(uid: assignedHelpers[index]),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Loading(),
                          );
                        } else {
                          return ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            tileColor: Colors.blueGrey[200],
                            leading: Text((index + 1).toString()),
                            title: Text(
                                '${snapshot.data!.firstName} ${snapshot.data!.lastName}'),
                            subtitle: Text(snapshot.data!.mobileNumber!),
                          );
                        }
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      } else {
                        return const Center(
                          child: Loading(),
                        );
                      }
                    });
              }),
        ),
      ),
    );
  }

  Widget _buildHelperAdminPageBody() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: StreamBuilder(
          stream: db.streamAllHelpers(),
          builder: (context, snapshot) {
            return SingleChildScrollView(
              child: SizedBox(
                height: _size!.height,
                width: _size!.width,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'You can assign up to two helpers for each Mason',
                        textAlign: TextAlign.center,
                        style: textStyle6,
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      //Selected User
                      Text(
                        '${widget.selectedUsers!.firstName} ${widget.selectedUsers!.lastName}',
                        style: textStyle4,
                      ),

                      //Assigned Helpers
                      //will display a list of assigned helper if available
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Container(
                          height: _size!.height * 0.2,
                          decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(25)),
                          child: assignedHelpers.isNotEmpty
                              ? ListView.builder(
                                  itemCount: assignedHelpers.length,
                                  itemBuilder: (context, index) {
                                    return FutureBuilder(
                                        future: db.readSingleHelper(
                                            uid: assignedHelpers[index]),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                child: Loading(),
                                              );
                                            } else {
                                              if (snapshot.data!.uid == null) {
                                                return const SizedBox.shrink();
                                              }
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      color:
                                                          Colors.blueGrey[300],
                                                      border: Border.all(),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15)),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      //will remove this item
                                                      setState(() {
                                                        assignedHelpers
                                                            .removeAt(index);
                                                      });
                                                    },
                                                    child: ListTile(
                                                      title: Text(
                                                          '${snapshot.data!.firstName} ${snapshot.data!.lastName}'),
                                                      subtitle: Text(snapshot
                                                          .data!.mobileNumber!),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          } else {
                                            return const Center(
                                              child: Loading(),
                                            );
                                          }
                                        });
                                  })
                              : const Center(
                                  child: Text(
                                    'No Assigned Helpers',
                                    style: textStyle5,
                                  ),
                                ),
                        ),
                      ),

                      //Available Helpers
                      //Will stream all helpers in the system
                      Column(
                        children: [
                          const Text(
                            'Select a helper in order to assign',
                            textAlign: TextAlign.center,
                            style: textStyle6,
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Container(
                            alignment: AlignmentDirectional.centerStart,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(15.0),
                              ),
                              border:
                                  Border.all(width: 1.0, color: Colors.grey),
                            ),
                            child: helperProvider != null &&
                                    helperProvider!.isNotEmpty &&
                                    !_isLoading
                                ? DropdownButtonHideUnderline(
                                    child: DropdownButtonFormField<Helpers>(
                                      decoration:
                                          const InputDecoration.collapsed(
                                              hintText: ''),
                                      isExpanded: true,
                                      value: selectedHelper,
                                      hint: const Center(
                                        child: Text(
                                          'Select User',
                                        ),
                                      ),
                                      onChanged: (Helpers? val) {
                                        if (val != null) {
                                          setState(() {
                                            selectedHelper = val;
                                            _helperSelected = true;

                                            helperFirstName.text =
                                                selectedHelper!.firstName!;
                                            helperLastName.text =
                                                selectedHelper!.lastName!;
                                            helperPhone.text =
                                                selectedHelper!.mobileNumber!;
                                            if (!assignedHelpers.contains(
                                                selectedHelper!.uid)) {
                                              assignedHelpers
                                                  .add(selectedHelper!.uid);
                                            }
                                          });
                                        }
                                      },
                                      selectedItemBuilder:
                                          (BuildContext context) {
                                        return helperProvider!
                                            .map<Widget>(
                                              (item) => Center(
                                                child: Text(
                                                  '${item.firstName} ${item.lastName}',
                                                  style: textStyle5,
                                                ),
                                              ),
                                            )
                                            .toList();
                                      },
                                      validator: (val) => val == null
                                          ? 'Please select a helper'
                                          : null,
                                      items: helperProvider!
                                          .map((item) =>
                                              DropdownMenuItem<Helpers>(
                                                value: item,
                                                child: Center(
                                                    child: Text(
                                                  '${item.firstName} ${item.lastName}',
                                                  style: textStyle5,
                                                )),
                                              ))
                                          .toList(),
                                    ),
                                  )
                                : const Center(
                                    child: Text('No available Helpers'),
                                  ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          //Add a new Helper
                          //Will open a dialog box to add a helper
                          Container(
                            padding: const EdgeInsets.all(12),
                            width: _size!.width - 10,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 35, 40, 57),
                                    fixedSize: Size(_size!.width / 2, 45),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(25))),
                                onPressed: () async {
                                  setState(() {
                                    selectedHelper = null;
                                  });

                                  await addHelper();
                                },
                                child: const Text(
                                  'Add Helper',
                                  style: textStyle2,
                                )),
                          ),

                          //Will open a small page of where helper details are showing
                          _helperSelected
                              ? Form(
                                  key: _formKey,
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: SizedBox(
                                      width: _size!.width - 10,
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                const Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    'First Name ',
                                                    style: textStyle3,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: TextFormField(
                                                    controller: helperFirstName,
                                                    validator: (val) {
                                                      if (val!.isEmpty) {
                                                        return 'First name is required';
                                                      }
                                                      return null;
                                                    },
                                                    onSaved: (value) {
                                                      if (value != null) {
                                                        helperFirstName.text =
                                                            value.trim();
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 5,
                                            ),
                                            Row(
                                              children: [
                                                const Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    'Last Name ',
                                                    style: textStyle3,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: TextFormField(
                                                    controller: helperLastName,
                                                    validator: (val) {
                                                      if (val!.isEmpty) {
                                                        return 'Last name is required';
                                                      }
                                                      return null;
                                                    },
                                                    onSaved: (value) {
                                                      if (value != null) {
                                                        helperLastName.text =
                                                            value.trim();
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 5,
                                            ),
                                            Row(
                                              children: [
                                                const Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    'Mobile ',
                                                    style: textStyle3,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: TextFormField(
                                                    controller: helperPhone,
                                                    validator: (val) {
                                                      if (val!.isEmpty) {
                                                        return 'Phone is required';
                                                      }
                                                      return null;
                                                    },
                                                    onSaved: (value) {
                                                      if (value != null) {
                                                        helperPhone.text =
                                                            value.trim();
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 5,
                                            ),
                                            Row(
                                              children: [
                                                //Delete current helper
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  width: _size!.width / 2.5,
                                                  child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color.fromARGB(
                                                                  255,
                                                                  226,
                                                                  37,
                                                                  16),
                                                          fixedSize: Size(
                                                              _size!.width / 2,
                                                              45),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          25))),
                                                      onPressed: () async {
                                                        String helperId =
                                                            selectedHelper!
                                                                .uid!;
                                                        setState(() {
                                                          selectedHelper = null;
                                                          // _isLoading = true;
                                                        });
                                                        await deleteHelper(
                                                            helperId: helperId);
                                                        if (mounted) {
                                                          setState(() {
                                                            _isLoading = false;
                                                          });
                                                        }
                                                      },
                                                      child: const Text(
                                                        'Delete',
                                                        style: textStyle2,
                                                      )),
                                                ),

                                                //Update Current helper
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  width: _size!.width / 2.5,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color.fromARGB(
                                                                255,
                                                                122,
                                                                108,
                                                                233),
                                                        fixedSize: Size(
                                                            _size!.width / 2,
                                                            45),
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        25))),
                                                    onPressed: () async {
                                                      if (_formKey.currentState!
                                                          .validate()) {
                                                        _formKey.currentState!
                                                            .save();
                                                        setState(() {
                                                          _helperSelected =
                                                              false;
                                                          _isLoading = true;
                                                        });

                                                        var result = await db
                                                            .updateHelper(
                                                                uid:
                                                                    selectedHelper!
                                                                        .uid,
                                                                firstName:
                                                                    helperFirstName
                                                                        .text,
                                                                lastName:
                                                                    helperLastName
                                                                        .text,
                                                                mobileNumber:
                                                                    helperPhone
                                                                        .text);
                                                        selectedHelper = null;
                                                        setState(() {
                                                          _isLoading = false;
                                                        });

                                                        Navigator.pop(context);
                                                        _snackBarWidget
                                                            .content = result;
                                                        _snackBarWidget
                                                            .showSnack();
                                                      }
                                                    },
                                                    child: const Text(
                                                      'Update',
                                                      style: textStyle2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ]),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      )
                    ]),
              ),
            );
          }),
    );
  }

  //Add new helper
  Future<void> addHelper() async {
    final _formKeyOne = GlobalKey<FormState>();
    String? firstName, lastName, phoneNumber;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('New Helper'),
              content: Form(
                  key: _formKeyOne,
                  child: SizedBox(
                    height: _size!.height / 4,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'First Name ',
                              style: textStyle3,
                            ),
                            SizedBox(
                              width: _size!.width / 2.5,
                              child: TextFormField(
                                initialValue: '',
                                validator: (val) {
                                  if (val!.isEmpty) {
                                    return 'First name is required';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  if (value != null) {
                                    firstName = value.trim();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            const Text(
                              'Last Name ',
                              style: textStyle3,
                            ),
                            SizedBox(
                              width: _size!.width / 2.5,
                              child: TextFormField(
                                initialValue: '',
                                validator: (val) {
                                  if (val!.isEmpty) {
                                    return 'Last name is required';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  if (value != null) {
                                    lastName = value.trim();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            const Text(
                              'Mobile Number ',
                              style: textStyle3,
                            ),
                            SizedBox(
                              width: _size!.width / 2.5,
                              child: TextFormField(
                                initialValue: '',
                                validator: (val) {
                                  if (val!.isEmpty) {
                                    return 'Mobile number is required';
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    phoneNumber = value.trim();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () async {
                        if (_formKeyOne.currentState!.validate()) {
                          //will add the user to the database
                          var result = await db.addNewHelper(
                              firstName: firstName,
                              lastName: lastName,
                              mobileNumber: phoneNumber);
                          Navigator.pop(context);
                          _snackBarWidget.content = result;
                          _snackBarWidget.showSnack();
                        }
                      },
                      child: const Text(
                        'Save',
                        style: textStyle5,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: textStyle5,
                      ),
                    ),
                  ],
                )
              ],
            ));
  }

  //Stream the current helpers

  //Add new Helpers

  //Delete a Helper
  Future<void> deleteHelper({String? helperId}) async {
    //remove the helper from the list of assigned users
    if (assignedHelpers.contains(helperId)) {
      assignedHelpers.remove(helperId);
    }
    //this function will remove selected helper from all users and from the database
    //Loop over mason and remove the following helper from them
    var masons = await db.getAllMasonsFuture();

    if (masons != null && masons.isNotEmpty) {
      //loop over all the mason
      for (UserData mason in masons) {
        if (mason.assingedHelpers != null &&
            mason.assingedHelpers!.isNotEmpty) {
          //loop over the helpers in each mason

          for (var id in mason.assingedHelpers!) {
            if (id == helperId) {
              //remove this helper's id from this mason
              await db.userCollection.doc(mason.uid).update({
                'assignedHelpers': FieldValue.arrayRemove([id])
              }).catchError((err) {
                print('An error deletig helper: $err');
              });
            } else {
              continue;
            }
          }
        }
      }
    }
    //after removing this helper from all masons
    //Delete the helper
    await db.deleteHelper(uid: helperId!);
  }
}
