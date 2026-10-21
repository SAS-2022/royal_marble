import 'package:flutter_test/flutter_test.dart';
import 'package:royal_marble/core/page_access.dart';
import 'package:royal_marble/core/roles.dart';

void main() {
  group('defaults', () {
    const access = PageAccess();

    test('HR sees most pages but not sites, clients, team status or the map', () {
      for (final p in [AppPage.sites, AppPage.clients, AppPage.teamStatus, AppPage.liveMap]) {
        expect(access.sees(AppRole.hr, p), isFalse, reason: p.name);
      }
      expect(access.pagesFor(AppRole.hr), hasLength(AppPage.values.length - 4));
    });

    test('coordinator: team status, map, users, sites, reports, overtime', () {
      expect(access.pagesFor(AppRole.coordinator), {
        AppPage.teamStatus,
        AppPage.liveMap,
        AppPage.users,
        AppPage.sites,
        AppPage.reports,
        AppPage.overtime,
      });
      expect(access.sees(AppRole.coordinator, AppPage.payroll), isFalse);
    });

    test('admin always sees everything; masons nothing', () {
      expect(access.pagesFor(AppRole.admin), AppPage.values.toSet());
      expect(access.pagesFor(AppRole.worker), isEmpty);
    });
  });

  group('stored settings', () {
    final access = PageAccess.fromMap({
      'roles': {
        'isHR': ['payroll', 'liveMap', 'notAPage'],
        'isCoordinator': <String>[],
        'isAdmin': <String>[],
      },
    });

    test('a stored list replaces the default; unknown names are ignored', () {
      expect(access.pagesFor(AppRole.hr), {AppPage.payroll, AppPage.liveMap});
      expect(access.isDefault(AppRole.hr), isFalse);
    });

    test('an empty list hides every page', () {
      expect(access.pagesFor(AppRole.coordinator), isEmpty);
    });

    test('roles without a list keep their defaults', () {
      expect(access.isDefault(AppRole.supervisor), isTrue);
      expect(access.pagesFor(AppRole.supervisor), defaultPages[AppRole.supervisor]);
    });

    test('admins can never be locked out', () {
      expect(access.pagesFor(AppRole.admin), AppPage.values.toSet());
    });

    test('a missing or malformed doc means defaults', () {
      expect(PageAccess.fromMap(null).isDefault(AppRole.hr), isTrue);
      expect(PageAccess.fromMap({'roles': 'x'}).isDefault(AppRole.hr), isTrue);
    });
  });

  test('coordinator role: key, rank, powers', () {
    expect(AppRole.coordinator.key, 'isCoordinator');
    expect(primaryRole(['isCoordinator']), AppRole.coordinator);
    expect(primaryRole(['isSupervisor', 'isCoordinator']), AppRole.coordinator);
    expect(AppRole.coordinator.isTracked, isTrue);
    expect(AppRole.coordinator.allSites, isTrue);
    expect(AppRole.coordinator.managesTeams, isTrue);
    expect(AppRole.coordinator.managesPay, isFalse);
    expect(AppRole.coordinator.usesWeb, isTrue);
    expect(AppRole.supervisor.allSites, isFalse);
  });
}
