import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/sales_pipeline/visits/visit_details.dart';
import 'package:royal_marble/shared/constants.dart';
import 'package:intl/intl.dart';

class VisitList extends StatefulWidget {
  const VisitList({Key key, this.currentUser, this.selectedUser})
      : super(key: key);
  final UserData currentUser;
  final UserData selectedUser;

  @override
  State<VisitList> createState() => _VisitListState();
}

class _VisitListState extends State<VisitList> with TickerProviderStateMixin {
  List<ClientVisitDetails> visitProviderClients;
  List<ProjectVisitDetails> visitProviderProjects;
  TabController _tabController;
  Size size;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    visitProviderClients = Provider.of<List<ClientVisitDetails>>(context);
    visitProviderProjects = Provider.of<List<ProjectVisitDetails>>(context);
    size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Visits List'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.work),
            ),
            Tab(
              icon: Icon(Icons.build),
            )
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        SizedBox(
          height: size.height - 10,
          width: size.width - 10,
          child: visitProviderClients.isEmpty
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
              : SizedBox(
                  height: size.height - 10,
                  child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: visitProviderClients.length,
                      itemBuilder: (context, index) {
                        if (visitProviderClients[index] != null) {
                          var date = visitProviderClients[index]
                              .visitTime
                              .toDate()
                              .toString()
                              .split(' ');

                          var time = date[1].split(':');
                          return GestureDetector(
                            onTap: () async => await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VisitDetailsClass(
                                  currentUser: widget.currentUser,
                                  selectedUser: widget.selectedUser,
                                  currentVisit: visitProviderClients[index],
                                  visitType: 'Client',
                                ),
                              ),
                            ),
                            child: SizedBox(
                              height: size.height / 4,
                              width: size.width - 30,
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Card(
                                  elevation: 4,
                                  color: Colors.grey[200],
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Text(
                                            DateFormat('EEEE').format(
                                                visitProviderClients[index]
                                                    .visitTime
                                                    .toDate()),
                                            style: textStyle7,
                                          ),
                                        ),
                                        const Divider(
                                          thickness: 1,
                                        ),
                                        Text(
                                          'Client Name: ${visitProviderClients[index].clientName}',
                                          style: textStyle5,
                                        ),
                                        Text(
                                          'Visit Purpose: ${visitProviderClients[index].visitPurpose}',
                                          style: textStyle5,
                                        ),
                                        Text(
                                          'Visit Details: ${visitProviderClients[index].visitDetails}',
                                          style: textStyle5,
                                          softWrap: true,
                                        ),
                                        const Divider(
                                          thickness: 1,
                                        ),
                                        Text(
                                          'Date: ${date[0]} - ${time[0]}:${time[1]}',
                                          style: textStyle6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      }),
                ),
        ),

        //Build the project tab
        SingleChildScrollView(
          child: SizedBox(
            height: size.height - 10,
            width: size.width - 10,
            child: visitProviderClients.isEmpty
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
                : SizedBox(
                    height: size.height - 10,
                    width: size.width - 10,
                    child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: visitProviderProjects.length,
                        itemBuilder: (context, index) {
                          if (visitProviderClients[index] != null) {
                            var date = visitProviderClients[index]
                                .visitTime
                                .toDate()
                                .toString()
                                .split(' ');

                            var time = date[1].split(':');
                            return GestureDetector(
                              onTap: () async => await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VisitDetailsClass(
                                    currentUser: widget.currentUser,
                                    selectedUser: widget.selectedUser,
                                    projectVisit: visitProviderProjects[index],
                                    visitType: 'Project',
                                  ),
                                ),
                              ),
                              child: SizedBox(
                                height: size.height / 4,
                                width: size.width - 30,
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Card(
                                    elevation: 4,
                                    color: Colors.grey[200],
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: Text(
                                              DateFormat('EEEE').format(
                                                  visitProviderClients[index]
                                                      .visitTime
                                                      .toDate()),
                                              style: textStyle7,
                                            ),
                                          ),
                                          const Divider(
                                            thickness: 1,
                                          ),
                                          Text(
                                            'Project Name: ${visitProviderClients[index].clientName}',
                                            style: textStyle5,
                                          ),
                                          Text(
                                            'Visit Purpose: ${visitProviderClients[index].visitPurpose}',
                                            style: textStyle5,
                                          ),
                                          Text(
                                            'Visit Details: ${visitProviderClients[index].visitDetails}',
                                            style: textStyle5,
                                            softWrap: true,
                                          ),
                                          const Divider(
                                            thickness: 1,
                                          ),
                                          Text(
                                            'Date: ${date[0]} - ${time[0]}:${time[1]}',
                                            style: textStyle6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }),
                  ),
          ),
        ),
      ]),
    );
  }
}
