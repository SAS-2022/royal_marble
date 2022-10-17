import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/location/show_map.dart';
import 'package:royal_marble/services/database.dart';
import '../models/business_model.dart';
import '../models/user_model.dart';

class MapProviders extends StatelessWidget {
  MapProviders({Key key, this.currentUser, this.listOfMarkers})
      : super(key: key);
  final UserData currentUser;
  final String listOfMarkers;
  final db = DatabaseService();
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        //a provider for projects
        StreamProvider<List<ProjectData>>.value(
            value: db.getAllProjects(),
            initialData: [],
            catchError: (context, err) => [ProjectData(error: err)]),

        //a provider for users
        StreamProvider<List<UserData>>.value(
            value: db.getAllUsers(),
            initialData: [],
            catchError: (context, err) => [UserData(error: err)]),
      ],
      child: ShowMap(
        currentUser: currentUser,
        listOfMarkers: listOfMarkers,
      ),
    );
  }
}
