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
  final _searchController = TextEditingController();
  List<ClientData> _searchResult = [];
  bool _emptySearchResults = false;
  Size size;

  @override
  void initState() {
    super.initState();
    _onSearchTextChnaged('');
  }

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
      resizeToAvoidBottomInset: false,
    );
  }

  Widget _buildClientList() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'List of avaialble clients',
            style: textStyle10,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
          child: TextField(
            autofocus: false,
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search',
              filled: true,
              fillColor: Colors.grey[100],
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: BorderSide(width: 1.0),
              ),
            ),
            onChanged: (val) {
              _onSearchTextChnaged(val.toString());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _searchResult != null && _searchResult.isNotEmpty
              ? SizedBox(
                  height: size.height * 0.73,
                  child: ListView.builder(
                    itemCount: _searchResult.length,
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
                                          client: _searchResult[index],
                                          isNewClient: false,
                                          currentUser: widget.currentUser,
                                        )),
                              );
                            },
                            child: ListTile(
                              title: Text(
                                _searchResult[index].clientName.toUpperCase(),
                                style: textStyle3,
                              ),
                              subtitle: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Contact: ${_searchResult[index].contactPerson}'),
                                  Text(
                                      'Mobile: ${_searchResult[index].phoneNumber.phoneNumber}'),
                                  Text(
                                      'Email: ${_searchResult[index].emailAddress}'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              : SizedBox(
                  height: size.height * 0.73,
                  child: const Center(
                    child: Text(
                      'No Clients were found',
                      style: textStyle4,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  //will show the client name relative the the typed data in the search field
  void _onSearchTextChnaged(String text) {
    var results = [];
    // _searchResult.clear();
    if (text.isEmpty) {
      //waits for the stream provider to load
      Future.delayed(const Duration(milliseconds: 750), () {
        setState(() {
          _searchResult = clientProvider;
        });
      });
      return;
    }
    results = clientProvider
        .where((client) => client.clientName
            .toString()
            .toLowerCase()
            .contains(text.toLowerCase()))
        .toList();
    setState(() {
      _searchResult = results;
      if (_searchResult.isEmpty) {
        _emptySearchResults = true;
      } else {
        _emptySearchResults = false;
      }
    });
  }
}
