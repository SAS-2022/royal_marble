import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/shared/constants.dart';

class ClientList extends StatefulWidget {
  const ClientList({Key key}) : super(key: key);

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
        title: const Text('Main Page'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _buildClientList(),
    );
  }

  Widget _buildClientList() {
    return SizedBox(
      height: size.height - 30,
      child: ListView.builder(
        itemCount: clientProvider.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              //once tapped it should allow us to view client details
            },
            child: ListTile(
              title: Text(
                clientProvider[index].clientName,
                style: textStyle3,
              ),
              subtitle: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Contact: ${clientProvider[index].contactPerson}'),
                  Text('Mobile: ${clientProvider[index].phoneNumber}'),
                  Text('Email: ${clientProvider[index].emailAddress}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
