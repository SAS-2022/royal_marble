import '../l10n/app_localizations.dart';
import 'roles.dart';

extension LocalizedRole on AppRole {
  String localized(AppLocalizations l) => switch (this) {
        AppRole.admin => l.roleAdmin,
        AppRole.supervisor => l.roleSupervisor,
        AppRole.sales => l.roleSales,
        AppRole.siteEngineer => l.roleSiteEngineer,
        AppRole.worker => l.roleMason,
      };
}

/// "2h 14m" / "14m" in the user's language.
String localizedDuration(AppLocalizations l, Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return h > 0 ? l.durationHm(h, m) : l.durationM(m);
}
