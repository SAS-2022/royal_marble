import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/loading.dart';
import 'package:royal_marble/shared/snack_bar.dart';
import '../models/user_model.dart';

class WorkerCurrentStream extends StatelessWidget {
  const WorkerCurrentStream(
      {Key? key, this.selectedProject, this.selectedMockup})
      : super(key: key);
  final ProjectData? selectedProject;
  final MockupData? selectedMockup;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        selectedProject != null
            ? StreamProvider<ProjectData>.value(
                initialData: ProjectData(),
                value: DatabaseService()
                    .getProjectById(projectId: selectedProject!.uid!),
                catchError: ((context, error) {
                  return ProjectData(error: error.toString());
                }),
              )
            : StreamProvider<MockupData>.value(
                initialData: MockupData(),
                value: DatabaseService()
                    .getMockupById(mockupId: selectedMockup!.uid!),
                catchError: ((context, error) {
                  return MockupData(error: error.toString());
                }),
              ),
      ],
      child: WorkerCurrentState(
        selectedProject: selectedProject,
        selectedMockup: selectedMockup,
      ),
    );
  }
}

class WorkerCurrentState extends StatefulWidget {
  const WorkerCurrentState(
      {Key? key, this.selectedProject, this.selectedMockup})
      : super(key: key);
  final ProjectData? selectedProject;
  final MockupData? selectedMockup;

  @override
  State<WorkerCurrentState> createState() => _WorkerCurrentStateState();
}

class _WorkerCurrentStateState extends State<WorkerCurrentState> {
  Size? _size;
  ProjectData _projectProvider = ProjectData();
  MockupData _mockupProvider = MockupData();
  DatabaseService db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    if (widget.selectedProject != null) {
      _projectProvider = Provider.of<ProjectData>(context);
    } else {
      _mockupProvider = Provider.of<MockupData>(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker State'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _projectProvider.uid != null
          ? _buildWorkerStateBodyProject()
          : _buildWorkerStateBodyMockup(),
    );
  }

  Widget _buildWorkerStateBodyProject() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
            child: SizedBox(
              height: _size!.height - 120,
              child: _projectProvider.assignedWorkers != null &&
                      _projectProvider.assignedWorkers!.isNotEmpty
                  ? ListView.builder(
                      itemCount: _projectProvider.assignedWorkers!.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: StreamBuilder<UserData>(
                              stream: null,
                              builder: (context, snapshot) {
                                return StreamProvider<UserData>.value(
                                  initialData: UserData(),
                                  value: db.getUserPerId(
                                      uid: _projectProvider
                                          .assignedWorkers![index]),
                                  catchError: ((context, error) =>
                                      UserData(error: error.toString())),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(width: 2),
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    child: WorkerWidget(
                                      currentProject: widget.selectedProject!,
                                    ),
                                  ),
                                );
                              }),
                        );
                      })
                  : const Center(
                      child: Text(
                        'No Workers were assigned to this project!',
                        style: textStyle3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerStateBodyMockup() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
            child: SizedBox(
              height: _size!.height - 120,
              child: _mockupProvider.assignedWorkers != null &&
                      _mockupProvider.assignedWorkers!.isNotEmpty
                  ? ListView.builder(
                      itemCount: _mockupProvider.assignedWorkers!.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: StreamBuilder<UserData>(
                              stream: null,
                              builder: (context, snapshot) {
                                return StreamProvider<UserData>.value(
                                  initialData: UserData(),
                                  value: db.getUserPerId(
                                      uid: _mockupProvider
                                          .assignedWorkers![index]),
                                  catchError: ((context, error) =>
                                      UserData(error: error.toString())),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(width: 2),
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    child: WorkerWidget(
                                      currentMockup: widget.selectedMockup!,
                                    ),
                                  ),
                                );
                              }),
                        );
                      })
                  : const Center(
                      child: Text(
                        'No Workers were assigned to this project!',
                        style: textStyle3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkerWidget extends StatefulWidget {
  const WorkerWidget({Key? key, this.currentProject, this.currentMockup})
      : super(key: key);
  final ProjectData? currentProject;
  final MockupData? currentMockup;

  @override
  State<WorkerWidget> createState() => _WorkerWidgetState();
}

class _WorkerWidgetState extends State<WorkerWidget> {
  UserData? _userProvider;
  SnackBarWidget _snackBarWidget = SnackBarWidget();
  bool _arrivedToSite = false;
  Size? _size;
  double? totalDistance;
  DatabaseService db = DatabaseService();
  String? role;
  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;
  }

  void _selectUserRole() {
    if (_userProvider != null && _userProvider!.roles != null) {
      switch (_userProvider!.roles!.first) {
        case 'isNormalUser':
          role = 'Worker';
          break;
        case 'isSiteEngineer':
          role = 'Site Engineer';
          break;
        case 'isSupervisor':
          role = 'Supervisor';
          break;
        default:
          role = 'Un-releated';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _userProvider = Provider.of<UserData>(context);
    _size = MediaQuery.of(context).size;

    _selectUserRole();
    return _userProvider!.uid != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SingleChildScrollView(
                child: Dismissible(
                  key: Key(_userProvider!.uid!),
                  direction: DismissDirection.endToStart,
                  background: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Container(
                      color: Colors.red,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: const Text(
                            'Remove',
                            style: textStyle3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  confirmDismiss: ((val) async {
                    var result;
                    //will call a function to confirm that the admin wants to remove this user
                    result = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: const Text('Removing Worker'),
                              content: const Text(
                                  'Are you sure you want to remove this worker from the project, this cannot be undone?'),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, 'no delete');
                                    },
                                    child: const Text('No')),
                                TextButton(
                                    onPressed: () {
                                      if (mounted) {
                                        Navigator.pop(context, 'Delete');
                                      }
                                    },
                                    child: const Text('Yes'))
                              ],
                            )).then((val) {
                      result = val;
                      return val;
                    });

                    if (result == 'Delete') {
                      if (widget.currentProject != null) {
                        await db.removeUserFromProject(
                            selectedProject: widget.currentProject!,
                            userId: _userProvider!.uid!,
                            removedUser: _userProvider!);
                      } else {
                        await db.removeUserFromMockup(
                            selectedMockup: widget.currentMockup!,
                            userId: _userProvider!.uid!,
                            removedUser: _userProvider!);
                      }

                      return true;
                    }

                    return null;
                  }),
                  onDismissed: (direction) async {
                    //The following code with remove user from the project
                    _snackBarWidget.content =
                        'User have been removed from this project';
                    _snackBarWidget.showSnack();
                  },
                  child: ListTile(
                    leading: _userProvider!.imageUrl == null
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
                              _userProvider!.imageUrl!,
                              scale: 2,
                            )),
                    title: Text(
                        '${_userProvider!.firstName} ${_userProvider!.lastName} - $role'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mobile: ${_userProvider!.phoneNumber}'),
                        Text(
                            'Distance To Site: ${_userProvider!.distanceToProject != null ? _userProvider!.distanceToProject.toStringAsFixed(2) : ''}'),
                      ],
                    ),
                    trailing: Container(
                      width: 20,
                      decoration: BoxDecoration(
                          color: widget.currentProject != null
                              ? getColorDistanceProject()
                              : null),
                    ),
                  ),
                ),
              ),
              _userProvider!.assingedHelpers != null &&
                      _userProvider!.assingedHelpers!.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                          alignment: Alignment.centerRight,
                          height: 80,
                          width: _size!.width / 2,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all()),
                          child: ListView.builder(
                              itemCount: _userProvider!.assingedHelpers!.length,
                              itemBuilder: (context, index) {
                                return FutureBuilder(
                                    future: db.readSingleHelper(
                                        uid: _userProvider!
                                            .assingedHelpers![index]),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              left: 30, top: 5, bottom: 5),
                                          child: ListTile(
                                            leading: Text('${index + 1}'),
                                            minLeadingWidth: 0,
                                            contentPadding:
                                                const EdgeInsets.all(2),
                                            title: Text(
                                                '${snapshot.data!.firstName} ${snapshot.data!.lastName}'),
                                            subtitle: Text(
                                                '${snapshot.data!.mobileNumber}'),
                                          ),
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    });
                              })),
                    )
                  : const SizedBox.shrink()
            ],
          )
        : const CircularProgressIndicator();
  }

  //Define color based on distance
  Color getColorDistanceProject() {
    Color? currentColor;
    if (_userProvider!.roles != null) {
      if (_userProvider!.roles!.contains('isSupervisor')) {
        if (_userProvider!.assignedProject != null) {
          for (var project in _userProvider!.assignedProject) {
            if (project['id'] == widget.currentProject!.uid) {
              if (_userProvider!.distanceToProject != null &&
                  _userProvider!.distanceToProject <= project['radius']) {
                currentColor = Colors.green;
              } else {
                currentColor = Colors.yellow;
              }
            }
          }
        }
      } else {
        if (_userProvider!.distanceToProject != null &&
            _userProvider!.distanceToProject <=
                _userProvider!.assignedProject['radius']) {
          currentColor = Colors.green;
        } else {
          currentColor = Colors.yellow;
        }
      }
    }

    return currentColor!;
  }
}
