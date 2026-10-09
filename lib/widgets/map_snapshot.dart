import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../screens/site_form_screen.dart' show siteRadiusCircle, siteZoomFor;

/// A still picture of a pin (and a site's radius, if given): a lite-mode map
/// on Android, a map with gestures off on iOS. Taps go to [onTap].
class MapSnapshot extends StatelessWidget {
  const MapSnapshot(
      {super.key, required this.pin, this.radius = 0, this.height = 150, this.onTap});

  final LatLng pin;
  final double radius;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(fit: StackFit.expand, children: [
        IgnorePointer(
          child: GoogleMap(
            key: ValueKey('$pin|$radius'),
            initialCameraPosition: CameraPosition(
                target: pin, zoom: radius > 0 ? siteZoomFor(radius) - 0.5 : 16),
            liteModeEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            markers: {Marker(markerId: const MarkerId('pin'), position: pin)},
            circles: {if (radius > 0) siteRadiusCircle(pin, radius)},
          ),
        ),
        if (onTap != null)
          Material(type: MaterialType.transparency, child: InkWell(onTap: onTap)),
      ]),
    );
  }
}
