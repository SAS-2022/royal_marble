import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:royal_marble/auth/social_buttons.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/core/format.dart';
import 'package:royal_marble/screens/site_form_screen.dart' show SitePinPicker;
import 'package:royal_marble/services/auth.dart';
import 'package:royal_marble/services/database.dart';

/// UAE mobile: 05XXXXXXXX, 5XXXXXXXX, +9715XXXXXXXX or 009715XXXXXXXX.
///
/// With [socialUser] (signed in with Google or Apple, no profile yet) the
/// account step is skipped and the profile is saved under that login.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.socialUser});
  final User? socialUser;

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

  bool get _social => widget.socialUser != null;
  int get _steps => _social ? 2 : 3;
  bool get _lastStep => _step == _steps - 1;

  List<String> get _titles =>
      [context.l10n.stepAboutYou, context.l10n.stepContact, context.l10n.stepAccount];

  @override
  void initState() {
    super.initState();
    // Google gives a display name; Apple only on the very first sign-in.
    final name = (widget.socialUser?.displayName ?? '').trim();
    if (name.isNotEmpty) {
      final i = name.indexOf(' ');
      _first.text = i < 0 ? name : name.substring(0, i);
      _last.text = i < 0 ? '' : name.substring(i + 1).trim();
    }
  }

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
    final l10n = context.l10n;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.takePhoto),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.chooseFromGallery),
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
      _snack(l10n.cameraError);
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

  bool _validateStep() {
    if (!_forms[_step].currentState!.validate()) return false;
    if (_step == 0 && _photo == null) {
      _snack(context.l10n.photoRequired);
      return false;
    }
    if (_step == 0 && _nationality == null) {
      _snack(context.l10n.nationalityRequired);
      return false;
    }
    if (_step == 1 && _home == null) {
      _snack(context.l10n.homeRequired);
      return false;
    }
    return true;
  }

  Future<String?> _uploadPhoto() async {
    // Same name the profile screen uses, so a later change replaces it.
    final name = _social
        ? '${widget.socialUser!.uid}.jpg'
        : '${DateTime.now().millisecondsSinceEpoch}_${_email.text.trim().hashCode.abs()}.jpg';
    final ref = FirebaseStorage.instance.ref('profile_images/$name');
    await ref.putFile(File(_photo!.path));
    return ref.getDownloadURL();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_validateStep()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (_social) {
        if (!await _saveSocialProfile()) throw l10n.registerFailed;
        return; // The wrapper now shows the "waiting for approval" screen.
      }
      final imageUrl = await _uploadPhoto();
      final result = await _auth.registerWithEmailandPassword(
        email: _email.text.trim(),
        password: _password.text,
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        company: _company.text.trim(),
        phoneNumber: normalizeUaeMobile(_phone.text),
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
            ? l10n.emailInUse
            : result.contains('network-request-failed')
                ? l10n.errNoInternet
                : l10n.registerFailed;
      }
      if (!mounted) return;
      // The auth stream now shows the "waiting for approval" screen.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      setState(() => _error = e is String ? e : l10n.somethingWrong);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Saves the profile for a Google/Apple login; false if the write failed.
  Future<bool> _saveSocialProfile() async {
    final user = widget.socialUser!;
    // Never overwrite a profile that exists but wasn't loaded yet.
    final existing = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));
    if (existing.exists) return true;
    final imageUrl = await _uploadPhoto();
    final result = await DatabaseService().updateUser(
      uid: user.uid,
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      company: _company.text.trim(),
      phoneNumber: normalizeUaeMobile(_phone.text),
      emailAddress: user.email,
      nationality: _nationality,
      homeAddress: _home,
      isActive: false,
      imageUrl: imageUrl,
      roles: ['isNormalUser'],
    );
    // updateUser returns its error text instead of throwing.
    return !result.startsWith(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_social ? context.l10n.finishSignUp : context.l10n.createAccount),
        // Signed in but not registered: the way out is signing out.
        leading: _social
            ? IconButton(
                tooltip: context.l10n.signOut,
                icon: const Icon(Icons.close),
                onPressed: _submitting ? null : () => _auth.signOut(),
              )
            : null,
      ),
      body: Column(children: [
        // Progress
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(children: [
            for (var i = 0; i < _steps; i++) ...[
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
              if (i < _steps - 1) const SizedBox(width: 6),
            ],
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(children: [
            Text(context.l10n.stepOf(_step + 1, _steps),
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
              if (!_social) _account(),
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
                    child: Text(context.l10n.back),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _submitting
                      ? null
                      : !_lastStep
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
                      : Text(!_lastStep ? context.l10n.continueLabel : context.l10n.createAccount),
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
            if (_social)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  context.l10n.signedInAs(widget.socialUser!.email ?? ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              )
            else
              SocialSignInButtons(
                dividerOnTop: false,
                // The wrapper underneath shows the rest of the registration.
                onSignedIn: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
              ),
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
                  const PositionedDirectional(
                    end: 0,
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
            Text(_photo == null ? context.l10n.addPhotoHint : context.l10n.tapToChange,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _first,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: context.l10n.firstName),
              validator: (v) => (v ?? '').trim().isEmpty ? context.l10n.required : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _last,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: context.l10n.lastName),
              validator: (v) => (v ?? '').trim().isEmpty ? context.l10n.required : null,
            ),
            const SizedBox(height: 14),
            _PickerField(
              icon: Icons.flag_outlined,
              label: context.l10n.nationality,
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
              decoration: InputDecoration(
                labelText: context.l10n.mobileNumber,
                hintText: '05X XXX XXXX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) => uaeMobile
                      .hasMatch((v ?? '').replaceAll(RegExp(r'[\s-]'), ''))
                  ? null
                  : context.l10n.mobileInvalid,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _company,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: context.l10n.company,
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? context.l10n.required : null,
            ),
            const SizedBox(height: 14),
            _PickerField(
              icon: Icons.home_outlined,
              label: context.l10n.homeAddress,
              value: _home == null ? null : prettyAddress(_home!['addressName']),
              onTap: _pickHome,
            ),
            if (_social) ..._approvalNotice(),
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
              decoration: InputDecoration(
                labelText: context.l10n.email,
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) => EmailValidator.validate((v ?? '').trim())
                  ? null
                  : context.l10n.enterValidEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: context.l10n.password,
                helperText: context.l10n.passwordHelper,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                ),
              ),
              validator: (v) =>
                  (v ?? '').length < 6 ? context.l10n.passwordTooShort : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password2,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: context.l10n.confirmPassword,
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) =>
                  v != _password.text ? context.l10n.passwordsDontMatch : null,
            ),
            ..._approvalNotice(),
          ],
        ),
      );

  List<Widget> _approvalNotice() => [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, color: AppColors.goldDeep),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.approvalNotice,
                style: TextStyle(color: AppColors.ink),
              ),
            ),
          ]),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.bad)),
        ],
      ];
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
