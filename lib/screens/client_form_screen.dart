import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/app_theme.dart';
import '../core/error_reporter.dart';
import '../core/format.dart';
import '../core/locale_controller.dart';
import '../models/business_model.dart';
import '../services/database.dart';
import '../widgets/status_widgets.dart';
import 'site_form_screen.dart' show SitePinPicker;

/// Create or edit a sales client. A new client is returned to the caller
/// (`Navigator.pop(context, client)`), so the visit form can pick it at once.
class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, this.client, required this.ownerId});

  /// The client to edit; null creates a new one.
  final ClientData? client;

  /// Salesperson a new client belongs to.
  final String ownerId;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.client?.clientName);
  late final _contact = TextEditingController(text: widget.client?.contactPerson);
  late final _phone = TextEditingController(text: widget.client?.phone);
  late final _email = TextEditingController(text: widget.client?.emailAddress);
  late final _address = TextEditingController(
      text: prettyAddress(widget.client?.clientAddress?['addressName']));
  late Map<String, dynamic>? _pin =
      widget.client?.hasPin == true ? widget.client!.clientAddress : null;
  bool _saving = false;

  bool get _isNew => widget.client == null;

  @override
  void dispose() {
    for (final c in [_name, _contact, _phone, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  LatLng? get _pinLatLng => _pin == null
      ? null
      : LatLng((_pin!['Lat'] as num).toDouble(), (_pin!['Lng'] as num).toDouble());

  Future<void> _pickPin() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SitePinPicker(
            initial: _pinLatLng, radius: 0, title: context.l10n.placeClient),
      ),
    );
    if (result != null) {
      setState(() {
        _pin = result;
        _address.text = '${result['addressName']}';
      });
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final address = _pin == null
        // An address typed without a pin is still worth keeping.
        ? (_address.text.trim().isEmpty
            ? null
            : {'addressName': _address.text.trim()})
        : {
            ..._pin!,
            if (_address.text.trim().isNotEmpty) 'addressName': _address.text.trim(),
          };
    final email = _email.text.trim();
    final phone = contactPhoneMap(_phone.text);
    try {
      final id = await DatabaseService().saveClient(
        id: widget.client?.uid,
        name: _name.text.trim(),
        contactPerson: _contact.text.trim(),
        phone: phone,
        email: email.isEmpty ? null : email,
        address: address,
        ownerId: widget.client?.userId ?? widget.ownerId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.ok, content: Text(l.clientSaved)));
      Navigator.pop(
          context,
          ClientData.fromMap(id, {
            'clientName': _name.text.trim(),
            'contactPerson': _contact.text.trim(),
            'phoneNumber': phone,
            'emailAddress': email,
            'clientAddress': address,
            'userId': widget.client?.userId ?? widget.ownerId,
          }));
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.bad, content: Text(l.clientSaveFailed)));
    }
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteClientTitle(widget.client!.name)),
        content: Text(l.deleteClientBody),
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
      await DatabaseService().deleteClient(widget.client!.uid!);
      if (!mounted) return;
      // Back past the details screen of the client that no longer exists.
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
      appBar: AppBar(title: Text(_isNew ? l.addClient : l.editClient)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: l.clientName,
                  prefixIcon: const Icon(Icons.storefront_outlined)),
              validator: (v) => v == null || v.trim().isEmpty ? l.required : null,
            ),

            SectionTitle(l.contactPerson),
            TextFormField(
              controller: _contact,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: l.contactPerson,
                  prefixIcon: const Icon(Icons.person_outline)),
              validator: (v) => v == null || v.trim().isEmpty ? l.required : null,
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
                return digits.length >= 9 ? null : l.enterValidPhone;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                  labelText: l.email, prefixIcon: const Icon(Icons.mail_outline)),
              validator: (v) => v == null ||
                      v.trim().isEmpty ||
                      EmailValidator.validate(v.trim())
                  ? null
                  : l.enterValidEmail,
            ),

            SectionTitle(l.clientLocation),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (pin != null)
                  SizedBox(
                    height: 160,
                    child: IgnorePointer(
                      child: GoogleMap(
                        key: ValueKey('$pin'),
                        initialCameraPosition: CameraPosition(target: pin, zoom: 16),
                        liteModeEnabled: true,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        markers: {Marker(markerId: const MarkerId('pin'), position: pin)},
                      ),
                    ),
                  ),
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
                    TextButton(
                        onPressed: _pickPin,
                        child: Text(pin == null ? l.setPin : l.movePin)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            Text(l.clientLocationHint,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
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
              label: Text(_isNew ? l.addClient : l.saveChanges),
            ),
            if (!_isNew) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.bad),
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(l.deleteClient),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
