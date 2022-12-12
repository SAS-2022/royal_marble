import 'package:flutter/material.dart';
import 'package:royal_marble/models/business_model.dart';
import 'package:royal_marble/services/database.dart';

import '../models/user_model.dart';
import '../shared/constants.dart';
import '../shared/snack_bar.dart';

class WorkCompleted extends StatefulWidget {
  const WorkCompleted(
      {Key key,
      this.currentUser,
      this.timeSheetId,
      this.selectedProject,
      this.checkIn,
      this.checkOut,
      this.isAtSite})
      : super(key: key);
  final UserData currentUser;
  final String timeSheetId;
  final ProjectData selectedProject;
  final String checkIn;
  final String checkOut;
  final bool isAtSite;
  @override
  State<WorkCompleted> createState() => _WorkCompletedState();
}

class _WorkCompletedState extends State<WorkCompleted> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _workType = [
    'Installing System',
    'Installing Tiles',
  ];
  String workType;
  double squareMeteres;
  Size _size;
  DatabaseService db = DatabaseService();
  final _snackBarWidget = SnackBarWidget();

  @override
  void initState() {
    super.initState();
    _snackBarWidget.context = context;
    print('the checkin: ${widget.checkIn} - ${widget.checkOut}');
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Work'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _buildWorkCompleteForm(),
    );
  }

  Widget _buildWorkCompleteForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Please specify what have you completed today',
                style: textStyle6,
              ),
              const SizedBox(
                height: 15,
              ),
              //List to select Type of work
              Container(
                alignment: AlignmentDirectional.centerStart,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(15.0),
                  ),
                  border: Border.all(width: 1.0, color: Colors.grey),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration.collapsed(hintText: ''),
                    isExpanded: true,
                    value: workType,
                    hint: const Center(
                      child: Text(
                        'Select User',
                      ),
                    ),
                    onChanged: (String val) {
                      if (val != null) {
                        setState(() {
                          workType = val;
                        });
                      }
                    },
                    selectedItemBuilder: (BuildContext context) {
                      return _workType
                          .map<Widget>(
                            (item) => Center(
                              child: Text(
                                item,
                                style: textStyle5,
                              ),
                            ),
                          )
                          .toList();
                    },
                    validator: (val) =>
                        val == null ? 'Please select work type' : null,
                    items: _workType
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Center(
                                  child: Text(
                                item,
                                style: textStyle5,
                              )),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              //how many sqaure meteres were completed
              Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Square Meters',
                      style: textStyle5,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                            borderSide: BorderSide(color: Colors.blue)),
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'value cannot be empty';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value != null) {
                          squareMeteres = double.parse(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              //A submit button to save changes
              SizedBox(
                width: _size.width - 50,
                child: ElevatedButton(
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed)) {
                            return const Color.fromARGB(255, 103, 48, 11);
                          }
                          return const Color.fromARGB(255, 37, 36, 25);
                        },
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: buttonStyle,
                    ),
                    onPressed: () async {
                      var result;
                      if (_formKey.currentState.validate()) {
                        //save the work achieved to the worker's timesheet
                        result = await db.updateWorkerTimeSheet(
                            isAtSite: widget.isAtSite,
                            currentUser: widget.currentUser,
                            userRole: widget.currentUser.roles.first,
                            selectedProject: widget.selectedProject,
                            today: widget.timeSheetId,
                            checkOut: widget.checkOut,
                            checkIn: widget.checkIn,
                            workType: workType,
                            squareMeters: squareMeteres);

                        _snackBarWidget.content = result;
                        _snackBarWidget.showSnack();
                      }

                      Navigator.pop(context);
                      Navigator.pop(context);
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
