/// The role strings stored in `users/{uid}.roles`.
///
/// A user can hold several role strings; [primaryRole] picks the one that
/// decides which home screen and permissions they get.
enum AppRole { admin, hr, coordinator, supervisor, sales, siteEngineer, worker }

const _roleKeys = {
  AppRole.admin: 'isAdmin',
  AppRole.hr: 'isHR',
  AppRole.coordinator: 'isCoordinator',
  AppRole.supervisor: 'isSupervisor',
  AppRole.sales: 'isSales',
  AppRole.siteEngineer: 'isSiteEngineer',
  AppRole.worker: 'isNormalUser',
};

extension AppRoleKey on AppRole {
  String get key => _roleKeys[this]!;

  String get label => switch (this) {
        AppRole.admin => 'Admin',
        AppRole.hr => 'HR',
        AppRole.coordinator => 'Coordinator',
        AppRole.supervisor => 'Supervisor',
        AppRole.sales => 'Sales',
        AppRole.siteEngineer => 'Site Engineer',
        AppRole.worker => 'Mason',
      };

  /// Roles that can see other people's locations, device alerts and reports.
  bool get canMonitor =>
      this == AppRole.admin || this == AppRole.supervisor || this == AppRole.coordinator;

  /// Roles that look after every site, not only the ones they're assigned to.
  bool get allSites => this == AppRole.admin || this == AppRole.coordinator;

  /// Roles that can change who works at a site.
  bool get managesTeams => allSites || this == AppRole.supervisor;

  /// Roles that can use the web dashboard; everyone else uses the phone app.
  bool get usesWeb => this == AppRole.admin || this == AppRole.hr || this == AppRole.coordinator;

  /// Admins and HR see everyone's pay, set it and approve overtime.
  bool get managesPay => this == AppRole.admin || this == AppRole.hr;

  /// Office roles aren't location-tracked.
  bool get isTracked => this != AppRole.admin && this != AppRole.hr;

  /// People whose phones, sites and alerts the team screens show.
  bool get inField => !canMonitor && this != AppRole.hr;
}

/// Highest-privilege role in [roles]; users with no recognised role are workers.
AppRole primaryRole(List<dynamic>? roles) {
  final r = roles ?? const [];
  for (final role in [
    AppRole.admin,
    AppRole.hr,
    AppRole.coordinator,
    AppRole.supervisor,
    AppRole.sales,
    AppRole.siteEngineer,
  ]) {
    if (r.contains(role.key)) return role;
  }
  return AppRole.worker;
}
