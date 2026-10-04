import 'package:url_launcher/url_launcher.dart';

/// Opens turn-by-turn directions in Google Maps (app or browser).
Future<void> openDirections(num lat, num lng) => launchUrl(
    Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
    mode: LaunchMode.externalApplication);
