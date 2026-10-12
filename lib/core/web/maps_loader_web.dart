import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Adds the Maps JavaScript API to the page before the first map is built.
/// The key comes from the build (`MAPS_API_KEY_WEB`), so it isn't in git.
Future<void> loadGoogleMapsScript(String key) async {
  if (key.isEmpty) return;
  final done = Completer<void>();
  final script = web.HTMLScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$key&loading=async'
    ..async = true;
  script.onload = ((web.Event _) => done.complete()).toJS;
  script.onerror = ((web.Event _) => done.complete()).toJS;
  web.document.head!.append(script);
  return done.future.timeout(const Duration(seconds: 10), onTimeout: () {});
}
