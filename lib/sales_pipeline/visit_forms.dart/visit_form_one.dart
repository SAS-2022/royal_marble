import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/sales_pipeline/visit_forms.dart/visit_form_two.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/snack_bar.dart';
import '../../shared/constants.dart';

class VisitFormOne extends StatefulWidget {
  const VisitFormOne({Key key}) : super(key: key);

  @override
  State<VisitFormOne> createState() => _VisitFormOneState();
}

enum VisitType { Client, Project }

class _VisitFormOneState extends State<VisitFormOne> {
  final _formKey = GlobalKey<FormState>();
  final db = DatabaseService();
  final _snackBarWidget = SnackBarWidget();
  Size size;
  VisitType _type;
  bool _isTypeSelected = false;
  List<ClientData> clientProvider;
  final TextEditingController _clientNameText = TextEditingController();
  final TextEditingController _projectNameText = TextEditingController();
  String contactPerson;
  String visitPurpose;
  final List<String> _visitPurposeList = [
    'Collecting payment',
    'Requesting payment',
    'New order',
    'Order follow up',
    'Quotation follow up',
    'Sample Submission',
    'Handling complaint',
    'Presenting new product',
    'Project discussion',
    'New client',
    're-establishing business',
    'Catching up visit',
    'Others...'
  ];

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    clientProvider = Provider.of<List<ClientData>>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Pipeline'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _buildSalesVisitFormOne(),
    );
  }

  Widget _buildSalesVisitFormOne() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following form will allow you to record your sales progres through either clients or projects',
                style: textStyle6,
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Client', style: textStyle3),
                      leading: Radio<VisitType>(
                        value: VisitType.Client,
                        groupValue: _type,
                        onChanged: (VisitType type) {
                          setState(() {
                            _type = type;
                            _isTypeSelected = true;
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Project', style: textStyle3),
                      leading: Radio<VisitType>(
                        value: VisitType.Project,
                        groupValue: _type,
                        onChanged: (VisitType type) {
                          setState(() {
                            _type = type;
                            _isTypeSelected = true;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              _isTypeSelected
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Client Name o project name
                          _type == VisitType.Client
                              ? TypeAheadFormField(
                                  onSuggestionSelected: (suggestions) {
                                    _clientNameText.text =
                                        suggestions.toString();
                                  },
                                  textFieldConfiguration:
                                      TextFieldConfiguration(
                                    controller: _clientNameText,
                                    style: textStyle3,
                                    autofocus: false,
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(15.0)),
                                          borderSide:
                                              BorderSide(color: Colors.grey)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(15.0)),
                                          borderSide: BorderSide(
                                              width: 3, color: Colors.green)),
                                      hintText: 'Client Name',
                                      filled: true,
                                    ),
                                  ),
                                  errorBuilder: (context, err) {
                                    return Text(err.toString());
                                  },
                                  keepSuggestionsOnLoading: true,
                                  autoFlipDirection: true,
                                  transitionBuilder:
                                      (context, suggestionsBox, controller) {
                                    return suggestionsBox;
                                  },
                                  validator: (val) {
                                    return val.isEmpty
                                        ? 'Client name cannot be empty'
                                        : null;
                                  },
                                  itemBuilder: (context, suggestion) {
                                    return ListTile(
                                      title: suggestion == null
                                          ? const Text(' ')
                                          : Text(suggestion.toString()),
                                    );
                                  },
                                  suggestionsCallback: (pattern) async {
                                    return await clientSuggestions(pattern);
                                  })
                              : TypeAheadFormField(
                                  noItemsFoundBuilder: (BuildContext context) {
                                    return null;
                                  },
                                  textFieldConfiguration:
                                      TextFieldConfiguration(
                                    controller: _projectNameText,
                                    style: textStyle3,
                                    autofocus: false,
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(15.0)),
                                          borderSide:
                                              BorderSide(color: Colors.grey)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(15.0)),
                                          borderSide: BorderSide(
                                              width: 3, color: Colors.green)),
                                      hintText: 'Project Name',
                                      filled: true,
                                    ),
                                  ),
                                  errorBuilder: (context, err) {
                                    return Text(err.toString());
                                  },
                                  keepSuggestionsOnLoading: true,
                                  onSuggestionSelected: (suggestions) {
                                    _projectNameText.text =
                                        suggestions.toString();
                                  },
                                  autoFlipDirection: true,
                                  transitionBuilder:
                                      (context, suggestionsBox, controller) {
                                    return suggestionsBox;
                                  },
                                  validator: (val) {
                                    return val.isEmpty
                                        ? 'Project name cannot be empty'
                                        : null;
                                  },
                                  itemBuilder: (context, suggestion) {
                                    return ListTile(
                                      title: suggestion == null
                                          ? const Text(' ')
                                          : Text(suggestion.toString()),
                                    );
                                  },
                                  suggestionsCallback: (pattern) async {
                                    return await projectSuggestions(pattern);
                                  }),
                          const SizedBox(height: 15),
                          //Contact Person
                          TextFormField(
                            autofocus: false,
                            initialValue: contactPerson,
                            style: textStyle3,
                            decoration: InputDecoration(
                              filled: true,
                              label: const Text('Contact Person'),
                              hintText: 'Ex: Sam Henry',
                              fillColor: Colors.grey[100],
                              enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  borderSide: BorderSide(
                                      width: 3, color: Colors.green)),
                            ),
                            validator: (val) => val.isEmpty
                                ? 'Contact person name is required'
                                : null,
                            onChanged: (val) {
                              setState(() {
                                contactPerson = val.trim();
                              });
                            },
                          ),
                          const SizedBox(height: 15),
                          //Purpose of visit
                          Container(
                            decoration: BoxDecoration(color: Colors.grey[100]),
                            width: MediaQuery.of(context).size.width,
                            height: 70,
                            alignment: AlignmentDirectional.centerStart,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField(
                                decoration: const InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(15.0)),
                                        borderSide:
                                            BorderSide(color: Colors.grey)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(15.0)),
                                        borderSide: BorderSide(
                                            width: 3, color: Colors.green)),
                                    hintText: ''),
                                isExpanded: true,
                                value: visitPurpose,
                                hint: const Center(
                                  child: Text('Visit Purpose'),
                                ),
                                validator: (val) => val != null
                                    ? null
                                    : 'Visit purpose it a required field',
                                onChanged: (val) {
                                  setState(() {
                                    FocusScope.of(context)
                                        .requestFocus(FocusNode());
                                    visitPurpose = val.toString();
                                  });
                                },
                                selectedItemBuilder: (BuildContext context) {
                                  return _visitPurposeList
                                      .map<Widget>(
                                        (item) => Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8.0),
                                          child: Text(
                                            item,
                                            style: textStyle3,
                                          ),
                                        ),
                                      )
                                      .toList();
                                },
                                items: _visitPurposeList
                                    .map(
                                      (item) => DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(
                                          item,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 191, 180, 66),
                                  fixedSize: Size(size.width, 45),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25))),
                              onPressed: () async {
                                if (_formKey.currentState.validate()) {
                                  await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => VisitFormTwo()));
                                }
                              },
                              child: const Text(
                                'Submit',
                                style: textStyle2,
                              )),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  //Client Suggestions
  Future<List<dynamic>> clientSuggestions(String query) async {
    var matches = [];
    matches.addAll(clientProvider.map((e) => e.clientName));
    matches.retainWhere((element) =>
        element.toString().toLowerCase().contains(query.toLowerCase()));
    return matches;
  }

  //Project Suggestions
  Future<List<dynamic>> projectSuggestions(String query) async {
    var matches = [];

    return matches;
  }
}
