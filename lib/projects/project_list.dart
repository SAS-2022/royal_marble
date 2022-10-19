import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/projects/project_form.dart';

import '../shared/constants.dart';

class ProjectList extends StatefulWidget {
  const ProjectList({Key key, this.currentUser, this.singleProject})
      : super(key: key);
  final UserData currentUser;
  final bool singleProject;

  @override
  State<ProjectList> createState() => _ProjectListState();
}

class _ProjectListState extends State<ProjectList> {
  var projectProvider;
  Size size;
  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    if (widget.singleProject != null) {
      projectProvider = Provider.of<ProjectData>(context);
      return ProjectForm(
        selectedProject: projectProvider,
        isNewProject: false,
      );
    } else {
      projectProvider = Provider.of<List<ProjectData>>(context);
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
      height: size.height - 30,
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
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProjectForm(
                                    selectedProject: projectProvider[index],
                                    isNewProject: false,
                                  )),
                        );
                      },
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
