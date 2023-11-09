import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:royal_marble/shared/constants.dart';

class LocationRequirement extends StatelessWidget {
  const LocationRequirement({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size _size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        //Describe why we need the location
        const Padding(
          padding: EdgeInsets.only(top: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Royal Marble collects location data and motion data for app functionality',
                  style: textStyle19,
                  textAlign: TextAlign.center,
                ),
              ),
              Text(
                'Location and Motion make tracking, check In, and check Out features possible even when the app is closed or not in use',
                style: textStyle18,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 35,
        ),
        //Button to open phone settings
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 7, 45, 97),
              fixedSize: Size(_size.width - 100, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: () async {
              await ph.openAppSettings();
            },
            child: const Text(
              'Open Phone Settings',
              style: textStyle2,
            )),
      ]),
    );
  }
}
