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
