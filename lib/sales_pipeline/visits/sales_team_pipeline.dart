import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/sales_pipeline/visits/visit_grid.dart';

import '../../shared/constants.dart';
import '../../shared/date_picker.dart';

class SalesTeamPipeline extends StatefulWidget {
  const SalesTeamPipeline({Key? key, this.currentUser}) : super(key: key);
  final UserData? currentUser;
  @override
  State<SalesTeamPipeline> createState() => _SalesTeamPipelineState();
}

class _SalesTeamPipelineState extends State<SalesTeamPipeline> {
  List<UserData>? salesProvider;
  Size? size;

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    salesProvider = Provider.of<List<UserData>>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Team'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _buildSalesTeamList(),
    );
  }

  Widget _buildSalesTeamList() {
    return SingleChildScrollView(
      child: SizedBox(
        height: size!.height - 100,
        child: widget.currentUser!.roles!.contains('isAdmin')
            ? ListView.builder(
                itemCount: salesProvider!.length,
                itemBuilder: ((context, index) {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                                content: DatePicker(
                                  currentUser: widget.currentUser!,
                                  reportType: 'pipeline',
                                  selectedUser: salesProvider![index],
                                ),
                              ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 25),
                      child: Card(
                        color: const Color.fromARGB(255, 181, 160, 130),
                        elevation: 4,
                        child: ListTile(
                          title: Text(
                            '${salesProvider![index].firstName} ${salesProvider![index].lastName}',
                            style: textStyle3,
                          ),
                          subtitle: Text(
                            '${salesProvider![index].phoneNumber} - ${salesProvider![index].emailAddress}',
                            style: textStyle5,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              )
            : Center(
                child: SizedBox(
                  height: 150,
                  width: size!.width - 30,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                                content: DatePicker(
                                  currentUser: widget.currentUser!,
                                  reportType: 'pipeline',
                                  selectedUser: widget.currentUser!,
                                ),
                              ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 25),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        color: const Color.fromARGB(255, 181, 160, 130),
                        elevation: 4,
                        child: ListTile(
                          title: Text(
                            '${widget.currentUser!.firstName} ${widget.currentUser!.lastName}',
                            style: textStyle3,
                          ),
                          subtitle: Text(
                            '${widget.currentUser!.phoneNumber} - ${widget.currentUser!.emailAddress}',
                            style: textStyle5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
