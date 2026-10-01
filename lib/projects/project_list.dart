import 'package:flutter/material.dart';
import 'package:royal_marble/screens/site_details_screen.dart';
import 'package:royal_marble/core/roles.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/projects/project_form.dart';
import 'package:royal_marble/shared/loading.dart';

import '../shared/constants.dart';

class ProjectList extends StatefulWidget {
  const ProjectList({Key? key, this.currentUser, this.singleProject})
      : super(key: key);
  final UserData? currentUser;
  final bool? singleProject;

  @override
  State<ProjectList> createState() => _ProjectListState();
}

class _ProjectListState extends State<ProjectList> {
  var projectProvider;
  List<UserData>? allWorkers;
  Size? size;
  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    if (widget.singleProject != null) {
      projectProvider = Provider.of<ProjectData>(context);
      allWorkers = Provider.of<List<UserData>>(context);
      final role = primaryRole(widget.currentUser?.roles);
      // Workers never receive the roster (see the grid), so don't wait for it.
      final needsRoster =
          role != AppRole.worker && role != AppRole.siteEngineer;
      return projectProvider.uid != null && (!needsRoster || allWorkers!.isNotEmpty)
          ? SiteDetailsScreen.project(
              project: projectProvider,
              currentUser: widget.currentUser!,
              allWorkers: allWorkers!,
            )
          : const Scaffold(body: Loading());
    } else {
      projectProvider = Provider.of<List<ProjectData>>(context);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Project List'),
        ),
        body: _buildProjectList(),
      );
    }
  }

  Widget _buildProjectList() {
    return SizedBox(
      height: size!.height - 30,
      child: projectProvider != null && projectProvider.isNotEmpty
          ? ListView.builder(
              itemCount: projectProvider.length,
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
                                    builder: (_) => ProjectForm(
                                          selectedProject:
                                              projectProvider[index],
                                          isNewProject: false,
                                          allWorkers: allWorkers,
                                          currentUser: widget.currentUser,
                                        )),
                              );
                            }
                          : null,
                      child: ListTile(
                        title: Text(
                          projectProvider[index].projectName.toUpperCase(),
                          style: textStyle3,
                        ),
                        subtitle: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Contact: ${projectProvider[index].contactPerson}'),
                            Text(
                                'Mobile: ${projectProvider[index].phoneNumber}'),
                            Text(
                                'Email: ${projectProvider[index].emailAddress}'),
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
