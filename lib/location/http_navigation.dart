import 'dart:io';
import 'package:flutter/material.dart';
import 'package:royal_marble/shared/snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class HttpNavigation {
  double? lat;
  double? lng;
  SnackBarWidget _snackBarWidget = SnackBarWidget();
  BuildContext? context;

  Future<void> startNaviagtionGoogleMap() async {
    _snackBarWidget.context = context!;
    var uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    var iosUri = 'comgooglemaps://?q=$lat,$lng&zoom=14';
    var uriIos = Uri.parse('comgooglemaps://?q=$lat,$lng&zoom=14');
    if (Platform.isAndroid) {
      await launchUrl(uri).onError((error, stackTrace) {
        _snackBarWidget.content = 'Error: $error';
        _snackBarWidget.showSnack();
        return false;
      }).then((value) {
        _snackBarWidget.content = 'Launching google maps. Please wait';
        _snackBarWidget.showSnack();
      });
    } else {
      if (await canLaunchUrl(uriIos)) {
        await launchUrl(uriIos).onError((error, stackTrace) {
          _snackBarWidget.content = 'Error: $error';
          _snackBarWidget.showSnack();
          return false;
        }).then((value) {
          _snackBarWidget.content = 'Launching google maps. Please wait';
          _snackBarWidget.showSnack();
        });
      } else {
        _snackBarWidget.content =
            'Cannot launch google maps, check if app is installed';
        _snackBarWidget.showSnack();
      }
    }
  }
}
