import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_theme.dart';
import '../core/error_reporter.dart';
import '../core/format.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../core/roles.dart';
import '../models/attendance.dart' show siteAssignments;
import '../models/user_model.dart';
import '../services/database.dart';
import '../services/tracking_service.dart';
import '../widgets/helpers_card.dart';
import '../widgets/status_widgets.dart';
import 'site_form_screen.dart' show SitePinPicker;

/// The signed-in user's own profile: photo, name, contact, nationality and
/// home address are editable; role, sites and helpers are shown read-only.
/// Also where a user deletes their own account (required by the app stores).
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key, required this.user});
  final UserData user;

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.user.firstName);
  late final _last = TextEditingController(text: widget.user.lastName);
  late final _phone = TextEditingController(text: widget.user.phoneNumber);
  late final _company = TextEditingController(text: widget.user.company);
  late Map<String, dynamic>? _nationality = widget.user.nationality;
  late Map<String, dynamic>? _home = widget.user.homeAddress;
  XFile? _photo;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _company]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l = context.l10n;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l.takePhoto),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.chooseFromGallery),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final img = await ImagePicker().pickImage(
          source: source,
          preferredCameraDevice: CameraDevice.front,
          maxWidth: 800,
          imageQuality: 85);
      if (img != null) setState(() => _photo = img);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.cameraError)));
      }
    }
  }

  Future<void> _pickHome() async {
    final lat = (_home?['Lat'] as num?)?.toDouble();
    final lng = (_home?['Lng'] as num?)?.toDouble();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SitePinPicker(
          initial: lat == null || lng == null ? null : LatLng(lat, lng),
          radius: 0,
          title: context.l10n.homeAddress,
        ),
      ),
    );
    if (result != null) setState(() => _home = result);
  }

  /// One file per user, so a new photo replaces the old one.
  Future<String> _uploadPhoto() async {
    final ref = FirebaseStorage.instance.ref('profile_images/${widget.user.uid}.jpg');
    await ref.putFile(File(_photo!.path));
    return ref.getDownloadURL();
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await DatabaseService().updateMyProfile(widget.user.uid!, {
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'phoneNumber': normalizeUaeMobile(_phone.text),
        'company': _company.text.trim(),
        if (_nationality != null)
          'nationality': {
            // Older versions of this screen saved the misspelt `contryCode`.
            'countryCode': _nationality!['countryCode'] ?? _nationality!['contryCode'],
            'countryName': _nationality!['countryName'],
          },
        if (_home != null) 'homeAddress': _home,
        if (_photo != null) 'imageUrl': await _uploadPhoto(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.ok, content: Text(l.profileSaved)));
      Navigator.pop(context);
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.bad, content: Text(l.profileSaveFailed)));
    }
  }

  Future<void> _deleteAccount() async {
    final deleted = await showDialog<bool>(
        context: context, builder: (_) => _DeleteAccountDialog(user: widget.user));
    if (deleted != true || !mounted) return;
    // Back to the start; the wrapper shows sign-in now that nobody is signed in.
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final u = widget.user;
    final role = primaryRole(u.roles);
    final sites = [
      ...siteAssignments(u.assignedProject),
      ...siteAssignments(u.assignedMockups),
    ].map((a) => '${a['name']}').toList();
    final hasImage = u.imageUrl?.startsWith('http') == true;

    return Scaffold(
      appBar: AppBar(title: Text(l.myProfile)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Center(
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _pickPhoto,
                child: Stack(children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                    foregroundImage: _photo != null
                        ? FileImage(File(_photo!.path))
                        : hasImage
                            ? NetworkImage(u.imageUrl!) as ImageProvider
                            : null,
                    child: Text(
                      '${u.firstName?.characters.firstOrNull ?? ''}${u.lastName?.characters.firstOrNull ?? ''}',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldDeep),
                    ),
                  ),
                  const PositionedDirectional(
                    end: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.ink,
                      child: Icon(Icons.photo_camera, size: 16, color: Colors.white),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Wrap(spacing: 6, children: [
                StatusPill(role.localized(l), icon: Icons.badge_outlined),
                if (u.emailAddress != null)
                  Text(u.emailAddress!,
                      style: const TextStyle(color: AppColors.muted)),
              ]),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _first,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.firstName),
              validator: (v) => (v ?? '').trim().isEmpty ? l.required : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _last,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.lastName),
              validator: (v) => (v ?? '').trim().isEmpty ? l.required : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                  labelText: l.mobileNumber,
                  hintText: '05X XXX XXXX',
                  prefixIcon: const Icon(Icons.phone_outlined)),
              validator: (v) =>
                  uaeMobile.hasMatch((v ?? '').replaceAll(RegExp(r'[\s-]'), ''))
                      ? null
                      : l.mobileInvalid,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _company,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: l.company,
                  prefixIcon: const Icon(Icons.business_outlined)),
            ),
            const SizedBox(height: 12),
            _PickerField(
              icon: Icons.flag_outlined,
              label: l.nationality,
              value: _nationality?['countryName'] as String?,
              onTap: () => showCountryPicker(
                context: context,
                showPhoneCode: false,
                onSelect: (c) => setState(() => _nationality = {
                      'countryCode': c.countryCode,
                      'countryName': c.displayNameNoCountryCode,
                    }),
              ),
            ),
            const SizedBox(height: 12),
            _PickerField(
              icon: Icons.home_outlined,
              label: l.homeAddress,
              value: _home?['addressName'] == null
                  ? null
                  : prettyAddress(_home!['addressName']),
              onTap: _pickHome,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(l.saveChanges),
            ),

            if (!role.canMonitor && role != AppRole.sales) ...[
              SectionTitle(l.yourSites),
              Card(
                child: sites.isEmpty
                    ? ListTile(
                        leading: const Icon(Icons.location_city_outlined),
                        title: Text(l.noSiteAssigned))
                    : Column(children: [
                        for (final s in sites)
                          ListTile(
                              leading: const Icon(Icons.apartment_outlined),
                              title: Text(s)),
                      ]),
              ),
            ],
            if (role == AppRole.worker) HelpersCard(mason: u, canManage: false),

            SectionTitle(l.sectionAccount),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.bad),
              onPressed: _saving ? null : _deleteAccount,
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(l.deleteMyAccount),
            ),
          ],
        ),
      ),
    );
  }
}

/// Explains what deletion removes, asks for the password (Firebase only
/// deletes an account after a recent sign-in), then deletes the profile and
/// the login. Pops `true` once the account is gone.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.user});
  final UserData user;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final auth = FirebaseAuth.instance;
    final current = auth.currentUser;
    if (current == null || current.email == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await current.reauthenticateWithCredential(EmailAuthProvider.credential(
          email: current.email!, password: _password.text));
      await TrackingService.stop();
      await FirebaseFirestore.instance.collection('users').doc(current.uid).delete();
      await current.delete();
      await ErrorReporter.setUser();
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('appLocale');
      await prefs.clear();
      if (lang != null) await prefs.setString('appLocale', lang);
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _busy = false;
        _error = e.code == 'wrong-password' || e.code == 'invalid-credential'
            ? l.errWrongPassword
            : l.deleteAccountFailed;
      });
    } catch (e, st) {
      await ErrorReporter.record(e, stackTrace: st);
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l.deleteAccountFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.deleteMyAccountTitle),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(l.deleteMyAccountBody),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l.password, errorText: _error),
        ),
      ]),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.bad),
          onPressed: _busy || _password.text.isEmpty ? null : _delete,
          child: Text(l.delete),
        ),
      ],
    );
  }
}

/// A tappable field that looks like a text input but opens a picker.
class _PickerField extends StatelessWidget {
  const _PickerField(
      {required this.icon, required this.label, required this.value, required this.onTap});
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              suffixIcon: const Icon(Icons.chevron_right)),
          isEmpty: value == null,
          child: value == null ? null : Text(value!, maxLines: 2),
        ),
      );
}
