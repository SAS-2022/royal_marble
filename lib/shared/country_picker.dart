import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/shared/constants.dart';

class CountryDropDownPicker extends StatefulWidget {
  const CountryDropDownPicker(
      {Key? key, this.countryOfResidence, this.selectCountry})
      : super(key: key);
  final Map<String, dynamic>? countryOfResidence;
  final Function? selectCountry;

  @override
  _CountryDropDownPickerState createState() => _CountryDropDownPickerState();
}

class _CountryDropDownPickerState extends State<CountryDropDownPicker> {
  String? newCountryOfResidence;
  Map<String, dynamic>? selectedCountry;

  @override
  void initState() {
    super.initState();
    if (widget.countryOfResidence != null) {
      selectedCountry = widget.countryOfResidence;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: InkWell(
        onTap: () => showCountryPicker(
            context: context,
            onSelect: (Country country) {
              setState(() {
                selectedCountry = {
                  'countryCode': country.countryCode,
                  'countryName': country.displayNameNoCountryCode
                };
                setState(() {
                  widget.selectCountry!(selectedCountry);
                });
              });
            }),
        child: Center(
          child: selectedCountry != null
              ? Text(
                  selectedCountry!['countryName'],
                  style: textStyle5,
                )
              : const Text(
                  'Select Country',
                  style: textStyle5,
                ),
        ),
      ),
    );
  }
}
