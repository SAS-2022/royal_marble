import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Wide browser windows: the menu stays on the left and pages open beside it
/// in their own navigator, instead of a drawer and full-screen pages.
bool useWebShell(BuildContext context) =>
    kIsWeb && MediaQuery.sizeOf(context).width >= 1000;

/// Opens [page] in the content area, or goes back to the dashboard when null.
typedef OpenPage = void Function(Widget? page);

class WebShell extends StatefulWidget {
  const WebShell({super.key, required this.sidebar, required this.home});

  /// Builds the menu; its items call `open` instead of pushing full-screen.
  /// `current` is the type of the page on show (null: the dashboard).
  final Widget Function(OpenPage open, Type? current) sidebar;
  final Widget home;

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  final _nav = GlobalKey<NavigatorState>();
  Type? _current;
  // The dashboard route is built once; this keeps it showing the latest data.
  late final _home = ValueNotifier<Widget>(widget.home);

  @override
  void didUpdateWidget(WebShell old) {
    super.didUpdateWidget(old);
    _home.value = widget.home;
  }

  @override
  void dispose() {
    _home.dispose();
    super.dispose();
  }

  // A menu page replaces whatever is shown, so it has no back arrow; pages
  // opened from it (a user, a site) still do.
  void _open(Widget? page) {
    _nav.currentState?.pushAndRemoveUntil(
        page == null ? _homeRoute() : _route(page), (_) => false);
    setState(() => _current = page?.runtimeType);
  }

  Route<void> _route(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );

  Route<void> _homeRoute() => _route(ValueListenableBuilder(
      valueListenable: _home, builder: (_, home, __) => home));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        SizedBox(width: 272, child: widget.sidebar(_open, _current)),
        const VerticalDivider(width: 1, color: AppColors.line),
        Expanded(
          child: ColoredBox(
            color: AppColors.surface,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                // Pages and their back buttons stay in this area.
                child: HeroControllerScope.none(
                  child: Navigator(
                    key: _nav,
                    onGenerateRoute: (_) => _homeRoute(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
