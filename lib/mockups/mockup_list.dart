import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/mockups/mockup_form.dart';
import 'package:royal_marble/models/business_model.dart';

import '../models/user_model.dart';
import '../shared/constants.dart';
import '../shared/loading.dart';

class MockupList extends StatefulWidget {
  const MockupList({Key? key, this.currentUser, this.singleMockup})
      : super(key: key);
  final UserData? currentUser;
  final bool? singleMockup;
  @override
  State<MockupList> createState() => _MockupListState();
}

class _MockupListState extends State<MockupList> {
  var mockupProvider;
  List<UserData>? allWorkers;
  Size? size;
  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    if (widget.singleMockup != null) {
      mockupProvider = Provider.of<MockupData>(context);
      allWorkers = Provider.of<List<UserData>>(context);
      return allWorkers!.isNotEmpty
          ? MockupForm(
              selectedMockUp: mockupProvider,
              isNewMockup: false,
              allWorkers: allWorkers,
              currentUser: widget.currentUser,
            )
          : const Loading();
    } else {
      mockupProvider = Provider.of<List<ProjectData>>(context);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Project List'),
          backgroundColor: const Color.fromARGB(255, 191, 180, 66),
        ),
        body: _buildProjectList(),
      );
    }
  }

  Widget _buildProjectList() {
    return SizedBox(
      height: size!.height - 30,
      child: mockupProvider != null && mockupProvider.isNotEmpty
          ? ListView.builder(
              itemCount: mockupProvider.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(15)),
                    child: GestureDetector(
                      onTap: allWorkers != null && allWorkers!.isNotEmpty
                          ? () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => MockupForm(
                                          selectedMockUp: mockupProvider[index],
                                          isNewMockup: false,
                                          allWorkers: allWorkers,
                                          currentUser: widget.currentUser,
                                        )),
                              );
                            }
                          : null,
                      child: ListTile(
                        title: Text(
                          mockupProvider[index].projectName.toUpperCase(),
                          style: textStyle3,
                        ),
                        subtitle: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Contact: ${mockupProvider[index].contactPerson}'),
                            Text(
                                'Mobile: ${mockupProvider[index].phoneNumber}'),
                            Text(
                                'Email: ${mockupProvider[index].emailAddress}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: Text(
                'No Projects were found',
                style: textStyle4,
              ),
            ),
    );
  }
}
