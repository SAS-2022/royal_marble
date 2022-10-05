import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/shared/constants.dart';

class CountryDropDownPicker extends StatefulWidget {
  const CountryDropDownPicker({Key key, this.countryOfResidence})
      : super(key: key);
  final String countryOfResidence;

  @override
  _CountryDropDownPickerState createState() => _CountryDropDownPickerState();
}

class _CountryDropDownPickerState extends State<CountryDropDownPicker> {
  String newCountryOfResidence;
  Country selectedCountry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: InkWell(
          onTap: () => showCountryPicker(
              context: context,
              onSelect: (Country country) {
                setState(() {
                  selectedCountry = country;
                });
              }),
          child: Center(
              child: selectedCountry != null
                  ? Text(
                      selectedCountry.displayName,
                      style: textStyle5,
                    )
                  : const Text(
                      'Select Country',
                      style: textStyle5,
                    ))),
    );
  }
}
