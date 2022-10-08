import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/clients/clients_form.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/shared/constants.dart';

class ClientList extends StatefulWidget {
  const ClientList({Key key, this.currentUser}) : super(key: key);
  final UserData currentUser;
  @override
  State<ClientList> createState() => _ClientListState();
}

class _ClientListState extends State<ClientList> {
  List<ClientData> clientProvider;
  Size size;
  @override
  Widget build(BuildContext context) {
    clientProvider = Provider.of<List<ClientData>>(context);
    size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client List'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _buildClientList(),
    );
  }

  Widget _buildClientList() {
    return SizedBox(
      height: size.height - 30,
      child: clientProvider != null && clientProvider.isNotEmpty
          ? ListView.builder(
              itemCount: clientProvider.length,
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
                              builder: (_) => ClientForm(
                                    client: clientProvider[index],
                                    isNewClient: false,
                                    currentUser: widget.currentUser,
                                  )),
                        );
                      },
                      child: ListTile(
                        title: Text(
                          clientProvider[index].clientName.toUpperCase(),
                          style: textStyle3,
                        ),
                        subtitle: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Contact: ${clientProvider[index].contactPerson}'),
                            Text(
                                'Mobile: ${clientProvider[index].phoneNumber}'),
                            Text(
                                'Email: ${clientProvider[index].emailAddress}'),
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
                'No Clients were found',
                style: textStyle4,
              ),
            ),
    );
  }
}
