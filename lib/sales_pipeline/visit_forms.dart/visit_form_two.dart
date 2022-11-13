import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:royal_marble/shared/constants.dart';

class VisitFormTwo extends StatefulWidget {
  const VisitFormTwo({Key key}) : super(key: key);

  @override
  State<VisitFormTwo> createState() => _VisitFormTwoState();
}

class _VisitFormTwoState extends State<VisitFormTwo> {
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
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
                  decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(25)),
                  child: TextFormField(
                    textCapitalization: TextCapitalization.sentences,
                    initialValue: '',
                    style: textStyle1,
                    decoration: InputDecoration(
                        border: InputBorder.none, fillColor: Colors.grey[200]),
                    maxLines: 5,
                    validator: (val) {
                      if (val.isEmpty) {
                        return 'This field cannot be empty';
                      }
                      if (val.length < 30) {
                        return '30 letters at least, you have ${val.length} letters';
                      }
                      return null;
                    },
                    onChanged: (val) {},
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
