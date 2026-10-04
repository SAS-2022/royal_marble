import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/app_theme.dart';
import '../core/error_reporter.dart';
import '../core/format.dart';
import '../core/locale_controller.dart';
import '../services/checkin_service.dart' show SiteKind;
import '../services/database.dart';
import '../widgets/status_widgets.dart';
import '../models/user_model.dart';
import 'site_details_screen.dart' show SiteDetailsLoader, SiteRef;

/// Check-in radius choices in metres. Android geofences below ~150 m are
/// unreliable, so smaller sites are allowed but not suggested first.
const _radiusChoices = [100.0, 150.0, 200.0, 300.0, 500.0];

const siteStatuses = ['potential', 'active', 'closed'];

String siteStatusLabel(BuildContext context, String? status) {
  final l = context.l10n;
  return switch (status) {
    'active' => l.siteStatusActive,
    'potential' => l.siteStatusPotential,
    'closed' => l.siteStatusClosed,
    _ => status ?? '',
  };
}

Tone siteStatusTone(String? status) => switch (status) {
      'active' => Tone.ok,
      'potential' => Tone.warn,
      'closed' => Tone.neutral,
      _ => Tone.neutral,
    };

/// A readable one-line address from a reverse-geocoding result, e.g.
/// "Al Braih St, Dubai Marina, Dubai". Google often puts a plus code
/// ("34HR+M9V") or the whole formatted address in `street`/`name`, so those
/// are only used when nothing better is available.
String addressFromPlacemark(Placemark p) {
  final plusCode = RegExp(r'^[23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,3}\b\s*');
  String clean(String? v) {
    var t = (v ?? '').trim().replaceFirst(plusCode, '');
    // A full "street - area - city - country" line: keep its first part.
    if (t.contains(' - ')) t = t.split(' - ').first.trim();
    // A field that is just the separator ("- Hor Al Anz") keeps only the name.
    return t.replaceAll(RegExp(r'^[\s\-–]+|[\s\-–]+$'), '');
  }

  final parts = <String>[];
  for (final v in [
    clean(p.thoroughfare).isNotEmpty ? clean(p.thoroughfare) : clean(p.street),
    clean(p.subLocality),
    clean(p.locality),
    clean(p.administrativeArea),
  ]) {
    if (v.isNotEmpty && !parts.contains(v)) parts.add(v);
  }
  return parts.join(', ');
}

/// Create or edit a project or mock-up: details, contact, status, map pin and
/// check-in radius. The team is managed on the site details screen.
class SiteFormScreen extends StatefulWidget {
  const SiteFormScreen(
      {super.key,
      required this.kind,
      this.site,
      this.initialPin,
      this.createdBy,
      this.currentUser});

  final SiteKind kind;

  /// The site to edit; null creates a new one.
  final SiteRef? site;

  /// Pin to start a new site from (e.g. a long-press on the live map).
  final Map<String, dynamic>? initialPin;
  final String? createdBy;

  /// When set, a newly created site opens straight on its details screen so
  /// the team can be assigned next.
  final UserData? currentUser;

  @override
  State<SiteFormScreen> createState() => _SiteFormScreenState();
}

class _SiteFormScreenState extends State<SiteFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.site?.name);
  late final _details = TextEditingController(text: widget.site?.details);
  late final _contractor = TextEditingController(text: widget.site?.contractor);
  late final _contact = TextEditingController(text: widget.site?.contactPerson);
  late final _phone = TextEditingController(text: widget.site?.phone);
  late final _email = TextEditingController(text: widget.site?.email);
  late final _address = TextEditingController(
      text: prettyAddress((widget.site?.address ?? widget.initialPin)?['addressName']));
  late String _status = widget.site?.status ?? 'potential';
  late double _radius = widget.site?.radius ?? 150;
  late Map<String, dynamic>? _pin = widget.site?.address ?? widget.initialPin;
  bool _saving = false;
  bool _pinMissing = false;

  bool get _isNew => widget.site == null;
  bool get _mockup => widget.kind == SiteKind.mockup;

  @override
  void dispose() {
    for (final c in [_name, _details, _contractor, _contact, _phone, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  LatLng? get _pinLatLng {
    final lat = (_pin?['Lat'] as num?)?.toDouble();
    final lng = (_pin?['Lng'] as num?)?.toDouble();
    return lat == null || lng == null ? null : LatLng(lat, lng);
  }

  Future<void> _pickPin() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SitePinPicker(initial: _pinLatLng, radius: _radius),
      ),
    );
    if (result != null) {
      setState(() {
        _pin = result;
        _pinMissing = false;
        _address.text = '${result['addressName']}';
      });
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    final valid = _form.currentState!.validate();
    setState(() => _pinMissing = _pin == null);
    if (!valid || _pin == null) return;
    setState(() => _saving = true);
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    try {
      final id = await DatabaseService().saveSite(
        mockup: _mockup,
        id: widget.site?.id,
        name: _name.text.trim(),
        details: _details.text.trim(),
        // The admin may have written a clearer address than the geocoder's.
        address: {
          ..._pin!,
          if (_address.text.trim().isNotEmpty) 'addressName': _address.text.trim(),
        },
        radius: _radius,
        status: _status,
        contractor: text(_contractor),
        contactPerson: text(_contact),
        phone: contactPhoneMap(_phone.text),
        email: text(_email),
        createdBy: widget.createdBy,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.ok, content: Text(l.siteSaved)));
      if (_isNew && widget.currentUser != null) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => SiteDetailsLoader(
                    kind: widget.kind, id: id, currentUser: widget.currentUser!)));
      } else {
        Navigator.pop(context, true);
      }
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.bad, content: Text(l.siteSaveFailed)));
    }
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final site = widget.site!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteSiteTitle(site.name)),
        content: Text(l.deleteSiteBody(site.workerIds.length)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel)),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.bad),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await DatabaseService().deleteSite(mockup: _mockup, id: site.id);
      if (!mounted) return;
      // Back past the details screen of the site that no longer exists.
      Navigator.of(context)
        ..pop()
        ..pop();
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pin = _pinLatLng;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew
            ? (_mockup ? l.newMockup : l.newProject)
            : (_mockup ? l.editMockup : l.editProject)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.siteName),
              validator: (v) => v == null || v.trim().isEmpty ? l.required : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _details,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.siteDetails),
            ),

            SectionTitle(l.siteStatus),
            SegmentedButton<String>(
              segments: [
                for (final s in siteStatuses)
                  ButtonSegment(value: s, label: Text(siteStatusLabel(context, s))),
              ],
              selected: {_status},
              onSelectionChanged: (v) => setState(() => _status = v.first),
            ),

            SectionTitle(l.siteLocation),
            Card(
              clipBehavior: Clip.antiAlias,
              shape: _pinMissing
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.bad))
                  : null,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (pin != null)
                  SizedBox(
                    height: 180,
                    child: IgnorePointer(
                      child: GoogleMap(
                        key: ValueKey('$pin|$_radius'),
                        initialCameraPosition: CameraPosition(
                            target: pin, zoom: _zoomFor(_radius)),
                        liteModeEnabled: true,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        markers: {Marker(markerId: const MarkerId('pin'), position: pin)},
                        circles: {_radiusCircle(pin, _radius)},
                      ),
                    ),
                  ),
                if (pin == null)
                  ListTile(
                    leading: Icon(Icons.place_outlined,
                        color: _pinMissing ? AppColors.bad : null),
                    title: Text(l.noPinYet),
                    subtitle: _pinMissing
                        ? Text(l.pinRequired,
                            style: const TextStyle(color: AppColors.bad))
                        : null,
                    trailing: TextButton(onPressed: _pickPin, child: Text(l.setPin)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                    child: Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _address,
                          minLines: 1,
                          maxLines: 2,
                          decoration: InputDecoration(
                              labelText: l.siteAddress,
                              prefixIcon: const Icon(Icons.place_outlined),
                              isDense: true),
                        ),
                      ),
                      TextButton(onPressed: _pickPin, child: Text(l.movePin)),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            Text(l.checkInRadiusLabel,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final r in {..._radiusChoices, _radius}.toList()..sort())
                ChoiceChip(
                  label: Text(l.metersShort(r.round())),
                  selected: _radius == r,
                  onSelected: (_) => setState(() => _radius = r),
                ),
            ]),
            const SizedBox(height: 4),
            Text(l.radiusHint, style: const TextStyle(color: AppColors.muted, fontSize: 12)),

            SectionTitle(l.contractor),
            TextFormField(
              controller: _contractor,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: l.contractorCompany,
                  prefixIcon: const Icon(Icons.business_outlined)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contact,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: l.contactPerson,
                  prefixIcon: const Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                  labelText: l.contactPhone,
                  hintText: '05X XXX XXXX',
                  prefixIcon: const Icon(Icons.phone_outlined)),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'[^\d]'), '');
                return digits.isEmpty || digits.length >= 9 ? null : l.enterValidPhone;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                  labelText: l.email, prefixIcon: const Icon(Icons.mail_outline)),
              validator: (v) => v == null || v.trim().isEmpty ||
                      EmailValidator.validate(v.trim())
                  ? null
                  : l.enterValidEmail,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isNew ? l.createSite : l.saveChanges),
            ),
            if (!_isNew) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.bad),
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(l.deleteSite),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Zoom that fits a site of [radius] metres comfortably on a phone screen.
double _zoomFor(double radius) => radius <= 100
    ? 17
    : radius <= 200
        ? 16
        : radius <= 500
            ? 15
            : 14;

Circle _radiusCircle(LatLng center, double radius) => Circle(
      circleId: const CircleId('radius'),
      center: center,
      radius: radius,
      strokeWidth: 2,
      strokeColor: AppColors.goldDeep,
      fillColor: AppColors.gold.withValues(alpha: 0.18),
    );

/// Full-screen map to place a site's pin: the pin stays in the middle while
/// the map moves underneath. Returns `{addressName, Lat, Lng}`.
class SitePinPicker extends StatefulWidget {
  const SitePinPicker(
      {super.key, this.initial, required this.radius, this.title});
  final LatLng? initial;

  /// Circle drawn around the pin; 0 hides it (e.g. a home address).
  final double radius;
  final String? title;

  @override
  State<SitePinPicker> createState() => _SitePinPickerState();
}

class _SitePinPickerState extends State<SitePinPicker> {
  /// Dubai, when there is no pin and no GPS fix yet.
  static const _dubai = LatLng(25.2048, 55.2708);

  /// Stored addresses stay in English, whatever the admin's phone language.
  final _geocoder = Geocoding(locale: const Locale('en'));
  GoogleMapController? _map;
  late LatLng _center = widget.initial ?? _dubai;
  final _search = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initial == null) _goToMe();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _moveTo(LatLng p, {double? zoom}) async {
    _center = p;
    await _map?.animateCamera(zoom == null
        ? CameraUpdate.newLatLng(p)
        : CameraUpdate.newLatLngZoom(p, zoom));
    if (mounted) setState(() {});
  }

  Future<void> _goToMe() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final p = await Geolocator.getCurrentPosition();
      await _moveTo(LatLng(p.latitude, p.longitude), zoom: _zoomFor(widget.radius));
    } catch (_) {
      // No fix: the admin can still search or move the map by hand.
    }
  }

  Future<void> _find() async {
    final q = _search.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final found = await _geocoder.locationFromAddress(q);
      if (found.isEmpty) throw StateError('none');
      await _moveTo(LatLng(found.first.latitude, found.first.longitude),
          zoom: _zoomFor(widget.radius));
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.addressNotFound);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    var name = '';
    try {
      final marks = await _geocoder.placemarkFromCoordinates(
          _center.latitude, _center.longitude);
      if (marks.isNotEmpty) name = addressFromPlacemark(marks.first);
    } catch (e) {
      // Offline or no geocoder: keep the coordinates as the address.
    }
    if (name.isEmpty) {
      name = '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}';
    }
    if (!mounted) return;
    Navigator.pop(context, {
      'addressName': name,
      'Lat': _center.latitude,
      'Lng': _center.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? l.placePin)),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition:
              CameraPosition(target: _center, zoom: widget.initial == null ? 11 : _zoomFor(widget.radius)),
          onMapCreated: (c) => _map = c,
          onCameraMove: (p) => setState(() => _center = p.target),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          circles: {if (widget.radius > 0) _radiusCircle(_center, widget.radius)},
        ),
        // The pin's tip sits on the map centre.
        const IgnorePointer(
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 44),
              child: Icon(Icons.location_on, size: 48, color: AppColors.bad),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _find(),
                decoration: InputDecoration(
                  hintText: l.searchAddress,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  errorText: _error,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                      onPressed: _busy ? null : _find,
                      icon: const Icon(Icons.arrow_forward)),
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          end: 16,
          bottom: 104,
          child: FloatingActionButton.small(
            heroTag: 'me',
            tooltip: l.myLocation,
            onPressed: _goToMe,
            child: const Icon(Icons.my_location),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: SafeArea(
            top: false,
            child: FilledButton.icon(
              onPressed: _busy ? null : _confirm,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.check),
              label: Text(l.usePinHere),
            ),
          ),
        ),
      ]),
    );
  }
}
