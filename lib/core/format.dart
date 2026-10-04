/// Older projects store `addressName` as a raw `Placemark.toString()` dump
/// ("Name: 14,\n Street: 14 11B St, ... Locality: Dubai, ..."). Turn that into
/// "14 11B St, Al Quoz, Dubai"; plain addresses pass through unchanged.
String prettyAddress(Object? raw) {
  final s = '${raw ?? ''}'.trim();
  if (!s.contains('Street:')) return s;
  final fields = <String, String>{};
  for (final m in RegExp(r'([A-Za-z ]+):\s*([^,\n]*)').allMatches(s)) {
    fields[m.group(1)!.trim()] = m.group(2)!.trim();
  }
  final parts = <String>[];
  for (final k in ['Street', 'Sublocality', 'Locality', 'Administrative area']) {
    final v = fields[k];
    if (v != null && v.isNotEmpty && !parts.contains(v)) parts.add(v);
  }
  return parts.isEmpty ? s : parts.join(', ');
}

/// A UAE mobile number in any common form (05X…, +9715X…, 009715X…).
final uaeMobile = RegExp(r'^(?:\+971|00971|0)?5\d{8}$');

/// A contact phone as sites and clients store it. UAE numbers typed locally
/// (05X…) are kept in international form.
Map<String, dynamic> contactPhoneMap(String typed) {
  var raw = typed.replaceAll(RegExp(r'[\s-]'), '');
  // The 2023 app reads `phoneNumber.phoneNumber` without a null check.
  if (raw.isEmpty) return {'phoneNumber': '', 'isoCode': 'AE', 'dialCode': '+971'};
  if (raw.startsWith('00')) raw = '+${raw.substring(2)}';
  if (raw.startsWith('0')) raw = '+971${raw.substring(1)}';
  final uae = raw.startsWith('+971');
  return {
    'phoneNumber': raw,
    'isoCode': uae ? 'AE' : null,
    'dialCode': uae ? '+971' : null,
  };
}

/// Stores numbers the way older accounts have them: 05XXXXXXXX.
String normalizeUaeMobile(String raw) {
  final digits = raw.replaceAll(RegExp(r'[\s-]'), '');
  final m = RegExp(r'5\d{8}$').firstMatch(digits);
  return m == null ? digits : '0${m.group(0)}';
}
