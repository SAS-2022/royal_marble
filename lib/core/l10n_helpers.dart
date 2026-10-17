import '../l10n/app_localizations.dart';
import '../models/leave.dart';
import '../models/salary.dart';
import 'roles.dart';

extension LocalizedRole on AppRole {
  String localized(AppLocalizations l) => switch (this) {
        AppRole.admin => l.roleAdmin,
        AppRole.hr => l.roleHR,
        AppRole.supervisor => l.roleSupervisor,
        AppRole.sales => l.roleSales,
        AppRole.siteEngineer => l.roleSiteEngineer,
        AppRole.worker => l.roleMason,
      };
}

/// "2h 14m" / "14m" in the user's language.
String localizedDuration(AppLocalizations l, Duration d) {
  // A clock mismatch between phone and server must never show "-5m".
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return h > 0 ? l.durationHm(h, m) : l.durationM(m);
}

extension LocalizedPayType on PayType {
  String localized(AppLocalizations l) => switch (this) {
        PayType.monthly => l.payTypeMonthly,
        PayType.daily => l.payTypeDaily,
        PayType.hourly => l.payTypeHourly,
      };

  String localizedUnit(AppLocalizations l) => switch (this) {
        PayType.monthly => l.perMonth,
        PayType.daily => l.perDay,
        PayType.hourly => l.perHour,
      };
}

extension LocalizedLeaveType on LeaveType {
  String localized(AppLocalizations l) => switch (this) {
        LeaveType.annual => l.leaveAnnual,
        LeaveType.emergency => l.leaveEmergency,
        LeaveType.sick => l.leaveSick,
      };

  /// For tight spots (the type picker, balance tiles).
  String short(AppLocalizations l) => switch (this) {
        LeaveType.annual => l.leaveAnnualShort,
        LeaveType.emergency => l.leaveEmergencyShort,
        LeaveType.sick => l.leaveSickShort,
      };
}

extension LocalizedLeaveStatus on LeaveStatus {
  String localized(AppLocalizations l) => switch (this) {
        LeaveStatus.pending => l.overtimeWaiting,
        LeaveStatus.approved => l.overtimeApproved,
        LeaveStatus.rejected => l.overtimeRejected,
        LeaveStatus.cancelled => l.leaveCancelled,
      };
}
