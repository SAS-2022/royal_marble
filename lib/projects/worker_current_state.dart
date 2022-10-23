import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/loading.dart';
import '../models/user_model.dart';

class WorkerCurrentStream extends StatelessWidget {
  const WorkerCurrentStream({Key key, this.selectedProject}) : super(key: key);
  final ProjectData selectedProject;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<ProjectData>.value(
          initialData: ProjectData(),
          value:
              DatabaseService().getProjectById(projectId: selectedProject.uid),
          catchError: ((context, error) {
            return ProjectData(error: error);
          }),
        ),
      ],
      child: WorkerCurrentState(
        selectedProject: selectedProject,
      ),
    );
  }
}

class WorkerCurrentState extends StatefulWidget {
  const WorkerCurrentState({Key key, this.selectedProject}) : super(key: key);
  final ProjectData selectedProject;

  @override
  State<WorkerCurrentState> createState() => _WorkerCurrentStateState();
}

class _WorkerCurrentStateState extends State<WorkerCurrentState> {
  Size _size;
  ProjectData _projectProvider;
  DatabaseService db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    _projectProvider = Provider.of<ProjectData>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker State'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _buildWorkerStateBody(),
    );
  }

  Widget _buildWorkerStateBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
            child: SizedBox(
              height: _size.height - 120,
              child: _projectProvider.assignedWorkers != null
                  ? ListView.builder(
                      itemCount: _projectProvider.assignedWorkers.length,
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
                                          .assignedWorkers[index]),
                                  catchError: ((context, error) =>
                                      UserData(error: error)),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(width: 2),
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    child: WorkerWidget(
                                      currentProject: widget.selectedProject,
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
  const WorkerWidget({Key key, this.currentProject}) : super(key: key);
  final ProjectData currentProject;

  @override
  State<WorkerWidget> createState() => _WorkerWidgetState();
}

class _WorkerWidgetState extends State<WorkerWidget> {
  UserData _userProvider;
  bool _arrivedToSite = false;
  Size _size;
  double totalDistance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _userProvider = Provider.of<UserData>(context);
    _size = MediaQuery.of(context).size;

    return SingleChildScrollView(
      child: ListTile(
        leading: const Text('User Photo'),
        title: Text('${_userProvider.firstName} ${_userProvider.lastName}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile: ${_userProvider.phoneNumber}'),
            Text(
                'Distance To Site: ${_userProvider.distanceToProject.toString()}')
          ],
        ),
        trailing: Container(
          width: 20,
          decoration: BoxDecoration(
              color: _userProvider.distanceToProject != null &&
                      _userProvider.distanceToProject <=
                          _userProvider.assignedProject['radius']
                  ? Colors.green
                  : Colors.yellow),
        ),
      ),
    );
  }

  //the following function will check if user arrived to the location or not yet
  // _checkUserLocation() {
  //   double calculateDistance(lat1, lon1, lat2, lon2) {
  //     var p = 0.017453292519943295;
  //     var c = cos;
  //     var a = 0.5 -
  //         c((lat2 - lat1) * p) / 2 +
  //         c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  //     return 12742 * asin(sqrt(a));
  //   }

  //   if (_userProvider.currentLocation != null) {
  //     totalDistance = calculateDistance(
  //         _userProvider.currentLocation['Lat'],
  //         _userProvider.currentLocation['Lng'],
  //         widget.currentProject.projectAddress['Lat'],
  //         widget.currentProject.projectAddress['Lng']);
  //     if (totalDistance < (widget.currentProject.radius / 1000)) {
  //       _arrivedToSite = true;
  //       if (mounted) {
  //         setState(() {});
  //       }
  //     } else {
  //       _arrivedToSite = false;
  //     }
  //   }
  // }
}
