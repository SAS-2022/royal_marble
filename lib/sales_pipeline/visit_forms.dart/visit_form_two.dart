import 'package:flutter/material.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/services/database.dart';
import 'package:royal_marble/shared/constants.dart';
import '../../models/user_model.dart';

class VisitFormTwo extends StatefulWidget {
  const VisitFormTwo(
      {Key key,
      this.selectedClient,
      this.contactPerson,
      this.visitPurpose,
      this.currentUser})
      : super(key: key);
  final ClientData selectedClient;
  final String contactPerson;
  final String visitPurpose;
  final UserData currentUser;

  @override
  State<VisitFormTwo> createState() => _VisitFormTwoState();
}

class _VisitFormTwoState extends State<VisitFormTwo> {
  final _formKey = GlobalKey<FormState>();
  DatabaseService db = DatabaseService();
  DateTime _time;
  String visitDetails;
  var size;

  @override
  void initState() {
    super.initState();
    _time = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Pipeline '),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _buildSalesVisitFormTwo(),
    );
  }

  Widget _buildSalesVisitFormTwo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(),
            child: Column(children: [
              //Describe what happened with the client
              const Text(
                'Please decribe your client visit with details',
                style: textStyle6,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(25)),
                  child: TextFormField(
                    textCapitalization: TextCapitalization.sentences,
                    initialValue: '',
                    style: textStyle3,
                    decoration: InputDecoration(
                        labelStyle: textStyle6,
                        label: const Text('What did you do?'),
                        border: InputBorder.none,
                        fillColor: Colors.grey[200]),
                    maxLines: 8,
                    validator: (val) {
                      if (val.isEmpty) {
                        return 'This field cannot be empty';
                      }
                      if (val.length < 20) {
                        return '20 letters at least, you have ${val.length} letters';
                      }
                      return null;
                    },
                    onChanged: (val) {
                      setState(() {
                        visitDetails = val.trim();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 191, 180, 66),
                      fixedSize: Size(size.width, 45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25))),
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      await db.addNewSalesVisit(
                          userId: widget.currentUser.uid,
                          selectedClient: widget.selectedClient,
                          contact: widget.contactPerson,
                          visitPurpose: widget.visitPurpose,
                          visitDetails: visitDetails,
                          visitTime: _time);

                      Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (route) => false);
                    }
                  },
                  child: const Text(
                    'Submit',
                    style: textStyle2,
                  )),
            ]),
          ),
        ),
      ),
    );
  }
}
