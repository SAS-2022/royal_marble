import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/locale_controller.dart';

/// Stands in for a map in the web dashboard until a browser Maps key is set
/// (`MAPS_API_KEY_WEB`), instead of a crashed map.
class MapUnavailable extends StatelessWidget {
  const MapUnavailable({super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.line.withValues(alpha: 0.5),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.map_outlined, color: AppColors.muted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(context.l10n.mapUnavailable,
                style: const TextStyle(color: AppColors.muted)),
          ),
        ]),
      );
}
