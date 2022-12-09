import 'package:flutter/material.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:royal_marble/shared/loading.dart';

import '../models/business_model.dart';

class ProjectStatus extends StatefulWidget {
  const ProjectStatus({Key key, this.selectedProject}) : super(key: key);
  final ProjectData selectedProject;

  @override
  State<ProjectStatus> createState() => _ProjectStatusState();
}

class _ProjectStatusState extends State<ProjectStatus> {
  Size _size;
  bool _loading = false;
  ProjectData editedProject;
  DatabaseService db = DatabaseService();

  @override
  void initState() {
    super.initState();
    if (widget.selectedProject != null) {
      editedProject = widget.selectedProject;
    }
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Status'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: Stack(
        children: [
          _buildProjectState(),
          _loading
              ? const Center(
                  child: Loading(),
                )
              : const SizedBox.shrink()
        ],
      ),
    );
  }

  Widget _buildProjectState() {
    //Will show the current status of the project and the ability to update it
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
                'You can change the project status through this section'),
            const SizedBox(
              height: 25,
            ),
            Row(children: [
              const Expanded(
                flex: 1,
                child: Text(
                  'Project Name',
                  style: textStyle3,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.selectedProject.projectName,
                  style: textStyle4,
                ),
              )
            ]),
            const SizedBox(
              height: 15,
            ),
            Row(children: [
              const Expanded(
                flex: 1,
                child: Text(
                  'Project Details',
                  style: textStyle3,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.selectedProject.projectDetails,
                  style: textStyle4,
                ),
              )
            ]),
            const SizedBox(
              height: 15,
            ),
            Row(children: [
              const Expanded(
                flex: 1,
                child: Text(
                  'Contractor',
                  style: textStyle3,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.selectedProject.contactorCompany,
                  style: textStyle4,
                ),
              )
            ]),
            const SizedBox(
              height: 15,
            ),
            Row(children: [
              const Expanded(
                flex: 1,
                child: Text(
                  'Contact Name',
                  style: textStyle3,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.selectedProject.contactPerson,
                  style: textStyle4,
                ),
              )
            ]),
            const SizedBox(
              height: 15,
            ),
            Row(children: [
              const Expanded(
                flex: 1,
                child: Text(
                  'Phone Number',
                  style: textStyle3,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.selectedProject.phoneNumber.phoneNumber,
                  style: textStyle4,
                ),
              )
            ]),
            const SizedBox(
              height: 15,
            ),
            //Will set three button to switch the project status
            SizedBox(
              height: 100,
              width: _size.width - 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //for active projects
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 148, 218, 83),
                        disabledBackgroundColor: Colors.grey,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              bottomLeft: Radius.circular(25)),
                        ),
                      ),
                      onPressed:
                          widget.selectedProject.projectStatus != 'active'
                              ? () async {
                                  setState(() {
                                    _loading = true;
                                  });
                                  editedProject.projectStatus = 'active';
                                  //will change project status
                                  await db.updateProjectStatus(
                                      project: editedProject);

                                  Navigator.pop(context);
                                }
                              : null,
                      child: const Text('Activate'),
                    ),
                  ),
                  //for potential projects
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0)),
                        backgroundColor:
                            const Color.fromARGB(255, 214, 163, 238),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      onPressed:
                          widget.selectedProject.projectStatus != 'potential'
                              ? () async {
                                  setState(() {
                                    _loading = true;
                                  });
                                  editedProject.projectStatus = 'potential';
                                  //will change project status
                                  await db.updateProjectStatus(
                                      project: editedProject);

                                  Navigator.pop(context);
                                }
                              : null,
                      child: const Text('Hold'),
                    ),
                  ),
                  //for closed projects
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 243, 98, 49),
                        disabledBackgroundColor: Colors.grey,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(25),
                              bottomRight: Radius.circular(25)),
                        ),
                      ),
                      onPressed:
                          widget.selectedProject.projectStatus != 'closed'
                              ? () async {
                                  setState(() {
                                    _loading = true;
                                  });
                                  editedProject.projectStatus = 'closed';
                                  //will change project status
                                  await db.updateProjectStatus(
                                      project: editedProject);

                                  Navigator.pop(context);
                                }
                              : null,
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
