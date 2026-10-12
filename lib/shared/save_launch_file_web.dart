import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Web dashboard: hands the file to the browser as a download.
Future<void> saveAndLaunchFile(List<int> bytes, String fileName) async {
  final blob = web.Blob([Uint8List.fromList(bytes).toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..click();
  web.URL.revokeObjectURL(url);
}
