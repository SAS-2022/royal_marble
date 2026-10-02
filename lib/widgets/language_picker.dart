import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/locale_controller.dart';

/// Native name and English name for each supported language.
const _names = {
  'en': ('English', 'English'),
  'ar': ('العربية', 'Arabic'),
  'hi': ('हिन्दी', 'Hindi'),
  'ur': ('اردو', 'Urdu'),
};

Future<void> showLanguagePicker(BuildContext context) {
  final controller = context.read<LocaleController>();
  final current = Localizations.localeOf(context).languageCode;
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(context.l10n.chooseLanguage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        for (final l in LocaleController.supported)
          ListTile(
            title: Text(_names[l.languageCode]!.$1,
                style: const TextStyle(fontSize: 18)),
            subtitle: l.languageCode == 'en'
                ? null
                : Text(_names[l.languageCode]!.$2),
            trailing: l.languageCode == current
                ? const Icon(Icons.check_circle, color: AppColors.ok)
                : null,
            onTap: () {
              controller.set(l);
              Navigator.pop(sheet);
            },
          ),
      ]),
    ),
  );
}

/// Compact "🌐 English" button, e.g. on the sign-in screen.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key, this.color = Colors.white});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: color),
      onPressed: () => showLanguagePicker(context),
      icon: const Icon(Icons.language, size: 20),
      label: Text(_names[code]?.$1 ?? code),
    );
  }
}
