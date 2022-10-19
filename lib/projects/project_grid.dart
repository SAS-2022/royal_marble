import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/projects/project_list.dart';
import 'package:royal_marble/services/database.dart';

class ProjectGrid extends StatelessWidget {
  const ProjectGrid({Key key, this.currentUser, this.selectedProject})
      : super(key: key);
  final UserData currentUser;
  final ProjectData selectedProject;

  @override
  Widget build(BuildContext context) {
    var db = DatabaseService();
    print('the selected Project: $selectedProject');
    return MultiProvider(
      providers: [
        selectedProject == null
            ? StreamProvider<List<ProjectData>>.value(
                value: db.getAllProjects(),
                initialData: const [],
                catchError: (context, err) {
                  print('Error getting Project: $err');
                  return [ProjectData(error: err)];
                },
              )
            : StreamProvider<ProjectData>.value(
                value: db.getProjectById(projectId: selectedProject.uid),
                initialData: ProjectData(),
                catchError: (context, err) {
                  print('Error getting Project: $err');
                  return ProjectData(error: err);
                },
              )
      ],
      child: ProjectList(
        currentUser: currentUser,
        singleProject: selectedProject == null ? false : true,
      ),
    );
  }
}
