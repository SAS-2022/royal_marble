import 'package:cloud_firestore/cloud_firestore.dart';

import 'roles.dart';

/// The menu pages an admin can turn on or off per role on the Page access
/// screen. Personal pages (My profile, My pay, My leave, Settings) are always
/// on. The names are stored in `settings/page_access` and read by the
/// Firestore rules, so don't rename them.
enum AppPage {
  teamStatus,
  liveMap,
  users,
  sites,
  clients,
  visits,
  reports,
  overtime,
  payroll,
  leaveRequests,
}

/// What each role sees until an admin changes it. Keep in step with
/// `roleSees()` in firestore.rules and `DEFAULT_PAGES` in functions/src/notify.ts.
const defaultPages = <AppRole, Set<AppPage>>{
  AppRole.hr: {
    AppPage.users,
    AppPage.visits,
    AppPage.reports,
    AppPage.overtime,
    AppPage.payroll,
    AppPage.leaveRequests,
  },
  AppRole.coordinator: {
    AppPage.teamStatus,
    AppPage.liveMap,
    AppPage.users,
    AppPage.sites,
    AppPage.reports,
    AppPage.overtime,
  },
  AppRole.supervisor: {
    AppPage.teamStatus,
    AppPage.liveMap,
    AppPage.users,
    AppPage.sites,
    AppPage.reports,
  },
  AppRole.sales: {AppPage.sites, AppPage.clients, AppPage.visits},
  AppRole.siteEngineer: {},
  AppRole.worker: {},
};

/// Which pages each role sees: `settings/page_access` → `roles.{roleKey}`, a
/// list of [AppPage] names. A role with no list there gets [defaultPages].
class PageAccess {
  const PageAccess([this._stored = const {}]);
  final Map<AppRole, Set<AppPage>> _stored;

  static final doc = FirebaseFirestore.instance.doc('settings/page_access');

  factory PageAccess.fromMap(Map<String, dynamic>? data) {
    final roles = data?['roles'];
    if (roles is! Map) return const PageAccess();
    return PageAccess({
      for (final r in AppRole.values)
        if (roles[r.key] is List)
          r: {
            for (final name in roles[r.key] as List)
              ...AppPage.values.where((p) => p.name == name),
          },
    });
  }

  /// The last settings read, for pages opened with the Navigator (they sit
  /// above the wrapper's providers).
  static PageAccess latest = const PageAccess();

  static Stream<PageAccess> watch() => doc
      .snapshots()
      .map((s) => latest = PageAccess.fromMap(s.data()))
      // No connection or no access yet: the defaults are the safe guess.
      .handleError((_) {});

  Set<AppPage> pagesFor(AppRole role) => role == AppRole.admin
      ? AppPage.values.toSet()
      : _stored[role] ?? defaultPages[role] ?? const {};

  bool sees(AppRole role, AppPage page) => pagesFor(role).contains(page);

  /// Whether [role] still has its default pages.
  bool isDefault(AppRole role) => !_stored.containsKey(role);

  /// Admin only (rules): saves [pages] as [role]'s list.
  static Future<void> save(AppRole role, Set<AppPage> pages, {required String byUid}) =>
      doc.set({
        'roles': {role.key: [for (final p in AppPage.values) if (pages.contains(p)) p.name]},
        'updatedBy': byUid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  /// Admin only: back to [defaultPages] for [role].
  static Future<void> reset(AppRole role, {required String byUid}) => doc.set({
        'roles': {role.key: FieldValue.delete()},
        'updatedBy': byUid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
