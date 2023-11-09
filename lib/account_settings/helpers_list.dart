import 'package:flutter/material.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/loading.dart';

class HelpersList extends StatefulWidget {
  const HelpersList({Key? key, this.currentUser}) : super(key: key);
  final UserData? currentUser;

  @override
  State<HelpersList> createState() => _HelpersListState();
}

class _HelpersListState extends State<HelpersList> {
  DatabaseService db = DatabaseService();
  Future? _getAssignedHelpers;
  Size? _size;
  @override
  void initState() {
    super.initState();
    _getAssignedHelpers = getAssignedHelpers();
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Helpers'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: widget.currentUser!.assingedHelpers != null &&
                widget.currentUser!.assingedHelpers.isNotEmpty
            ? FutureBuilder(
                future: _getAssignedHelpers,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Loading(),
                      );
                    } else {
                      return SizedBox(
                        height: _size!.height - 20,
                        child: ListView.builder(
                            itemCount: snapshot.data.length,
                            itemBuilder: (context, index) {
                              if (widget.currentUser!.assingedHelpers
                                  .contains(snapshot.data[index].uid)) {
                                return ListTile(
                                  tileColor:
                                      const Color.fromARGB(255, 224, 175, 30),
                                  title: Text(
                                      '${snapshot.data[index].firstName} ${snapshot.data[index].lastName}'),
                                  subtitle: Text(
                                      '${snapshot.data[index].mobileNumber}'),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            }),
                      );
                    }
                  } else {}
                  return Container();
                })
            : const Center(
                child: Text(
                  'There are no assigned Helpers',
                  style: textStyle4,
                ),
              ),
      ),
    );
  }

  //Future to hget assigned Helpers
  Future<List<Helpers>> getAssignedHelpers({String? uid}) async {
    return db.getAssignedHelper();
  }
}
