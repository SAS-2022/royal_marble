import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/shared/constants.dart';

class VisitList extends StatefulWidget {
  const VisitList({Key key, this.currentUser}) : super(key: key);
  final UserData currentUser;

  @override
  State<VisitList> createState() => _VisitListState();
}

class _VisitListState extends State<VisitList> {
  List<VisitDetails> visitProvider;
  Size size;

  @override
  Widget build(BuildContext context) {
    visitProvider = Provider.of<List<VisitDetails>>(context);
    size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Visits List'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height - 10,
          width: size.width - 10,
          child: visitProvider.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text(
                      'No visits for selected dates!',
                      style: textStyle3,
                    ),
                  ],
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: visitProvider.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      height: size.height - 30,
                      width: size.width - 30,
                      child: Card(
                        elevation: 4,
                        color: Colors.grey[200],
                        child: Column(),
                      ),
                    );
                  }),
        ),
      ),
    );
  }
}
