/// The role strings stored in `users/{uid}.roles`.
///
/// A user can hold several role strings; [primaryRole] picks the one that
/// decides which home screen and permissions they get.
enum AppRole { admin, supervisor, sales, siteEngineer, worker }

const _roleKeys = {
  AppRole.admin: 'isAdmin',
  AppRole.supervisor: 'isSupervisor',
  AppRole.sales: 'isSales',
  AppRole.siteEngineer: 'isSiteEngineer',
  AppRole.worker: 'isNormalUser',
};

extension AppRoleKey on AppRole {
  String get key => _roleKeys[this]!;

  String get label => switch (this) {
        AppRole.admin => 'Admin',
        AppRole.supervisor => 'Supervisor',
        AppRole.sales => 'Sales',
        AppRole.siteEngineer => 'Site Engineer',
        AppRole.worker => 'Worker',
      };

  /// Roles that can see other people's locations, device alerts and reports.
  bool get canMonitor => this == AppRole.admin || this == AppRole.supervisor;
}

/// Highest-privilege role in [roles]; users with no recognised role are workers.
AppRole primaryRole(List<dynamic>? roles) {
  final r = roles ?? const [];
  for (final role in [
    AppRole.admin,
    AppRole.supervisor,
    AppRole.sales,
    AppRole.siteEngineer,
  ]) {
    if (r.contains(role.key)) return role;
  }
  return AppRole.worker;
}
