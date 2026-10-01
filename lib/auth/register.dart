import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/format.dart';
import 'package:royal_marble/location/google_map_navigation.dart';
import 'package:royal_marble/services/auth.dart';

/// UAE mobile: 05XXXXXXXX, 5XXXXXXXX, +9715XXXXXXXX or 009715XXXXXXXX.
final _uaeMobile = RegExp(r'^(?:\+971|00971|0)?5\d{8}$');

/// Stores numbers the way older accounts have them: 05XXXXXXXX.
String _normalizePhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'[\s-]'), '');
  final m = RegExp(r'5\d{8}$').firstMatch(digits);
  return m == null ? digits : '0${m.group(0)}';
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = AuthService();
  final _forms = List.generate(3, (_) => GlobalKey<FormState>());
  int _step = 0;
  bool _submitting = false;
  String? _error;

  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController(text: 'Royal Marble');
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  bool _obscure = true;

  XFile? _photo;
  Map<String, dynamic>? _nationality;
  Map<String, dynamic>? _home;

  static const _titles = ['About you', 'Contact', 'Account'];

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _company, _email, _password, _password2]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
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
        imageQuality: 85,
      );
      if (img != null) setState(() => _photo = img);
    } catch (e) {
      _snack('Could not open the camera or gallery.');
    }
  }

  Future<void> _pickHome() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GoogleMapNavigation(
          navigate: false,
          getLocation: ({String? locationName, LatLng? locationAddress}) async {
            if (locationName == null || locationAddress == null) return;
            setState(() => _home = {
                  'addressName': locationName,
                  'Lat': locationAddress.latitude,
                  'Lng': locationAddress.longitude,
                });
          },
        ),
      ),
    );
  }

  bool _validateStep() {
    if (!_forms[_step].currentState!.validate()) return false;
    if (_step == 0 && _photo == null) {
      _snack('Add a photo so your supervisor can recognise you.');
      return false;
    }
    if (_step == 0 && _nationality == null) {
      _snack('Select your nationality.');
      return false;
    }
    if (_step == 1 && _home == null) {
      _snack('Set your home address on the map.');
      return false;
    }
    return true;
  }

  Future<String?> _uploadPhoto() async {
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${_email.text.trim().hashCode.abs()}.jpg';
    final ref = FirebaseStorage.instance.ref('profile_images/$name');
    await ref.putFile(File(_photo!.path));
    return ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_validateStep()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final imageUrl = await _uploadPhoto();
      final result = await _auth.registerWithEmailandPassword(
        email: _email.text.trim(),
        password: _password.text,
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        company: _company.text.trim(),
        phoneNumber: _normalizePhone(_phone.text),
        nationality: _nationality,
        homeAddress: _home,
        isActive: false,
        imageUrl: imageUrl,
        roles: ['isNormalUser'],
      );
      // registerWithEmailandPassword returns the uid on success, or the
      // error text ("[firebase_auth/<code>] ...") on failure.
      if (result is String && result.startsWith('[')) {
        throw result.contains('email-already-in-use')
            ? 'An account with this email already exists. Try signing in.'
            : result.contains('network-request-failed')
                ? 'No internet connection.'
                : 'Could not create the account. Check your details and try again.';
      }
      if (!mounted) return;
      // The auth stream now shows the "waiting for approval" screen.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      setState(() => _error = e is String ? e : 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Column(children: [
        // Progress
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(children: [
            for (var i = 0; i < 3; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _step ? AppColors.gold : AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < 2) const SizedBox(width: 6),
            ],
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(children: [
            Text('Step ${_step + 1} of 3',
                style: const TextStyle(color: AppColors.muted)),
            const Spacer(),
            Text(_titles[_step],
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: IndexedStack(index: _step, children: [
              _aboutYou(),
              _contact(),
              _account(),
            ]),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _step--),
                    child: const Text('Back'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _submitting
                      ? null
                      : _step < 2
                          ? () {
                              if (_validateStep()) setState(() => _step++);
                            }
                          : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(_step < 2 ? 'Continue' : 'Create account'),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _aboutYou() => Form(
        key: _forms[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                    foregroundImage:
                        _photo != null ? FileImage(File(_photo!.path)) : null,
                    child: const Icon(Icons.person,
                        size: 56, color: AppColors.goldDeep),
                  ),
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.charcoal,
                      child: Icon(Icons.photo_camera,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Text(_photo == null ? 'Add a clear photo of your face' : 'Tap to change',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _first,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'First name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _last,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Last name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _PickerField(
              icon: Icons.flag_outlined,
              label: 'Nationality',
              value: _nationality?['countryName'],
              onTap: () => showCountryPicker(
                context: context,
                showPhoneCode: false,
                onSelect: (c) => setState(() => _nationality = {
                      'countryCode': c.countryCode,
                      'countryName': c.displayNameNoCountryCode,
                    }),
              ),
            ),
          ],
        ),
      );

  Widget _contact() => Form(
        key: _forms[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                hintText: '05X XXX XXXX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) => _uaeMobile
                      .hasMatch((v ?? '').replaceAll(RegExp(r'[\s-]'), ''))
                  ? null
                  : 'Enter a UAE mobile number (05X XXX XXXX)',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _company,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Company',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _PickerField(
              icon: Icons.home_outlined,
              label: 'Home address',
              value: _home == null ? null : prettyAddress(_home!['addressName']),
              onTap: _pickHome,
            ),
          ],
        ),
      );

  Widget _account() => Form(
        key: _forms[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) => EmailValidator.validate((v ?? '').trim())
                  ? null
                  : 'Enter a valid email',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'At least 6 characters',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                ),
              ),
              validator: (v) =>
                  (v ?? '').length < 6 ? 'Use at least 6 characters' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password2,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) =>
                  v != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: AppColors.goldDeep),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'An admin reviews new accounts. You can sign in once yours is approved.',
                    style: TextStyle(color: AppColors.ink),
                  ),
                ),
              ]),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.bad)),
            ],
          ],
        ),
      );
}

/// A tappable field that looks like a text input but opens a picker.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.chevron_right),
        ),
        isEmpty: value == null,
        child: value == null ? null : Text(value!, maxLines: 2),
      ),
    );
  }
}
