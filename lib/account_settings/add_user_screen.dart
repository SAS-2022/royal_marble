import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/l10n_helpers.dart';
import '../core/locale_controller.dart';
import '../core/roles.dart';
import '../core/usernames.dart';
import '../models/user_model.dart';
import '../services/account_service.dart';
import '../widgets/status_widgets.dart';

/// Admins and HR add someone who signs in with a username and a password
/// they set. The account is active at once.
class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key, required this.viewer});
  final UserData viewer;

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  AppRole _role = AppRole.worker;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  /// Until it is edited, the username follows the name and the server may
  /// add a number if it's taken.
  bool _typedUsername = false;

  late final _admin = primaryRole(widget.viewer.roles) == AppRole.admin;

  /// HR can't give Admin, HR or Coordinator (same as the role chips).
  late final _roles = [
    for (final r in AppRole.values)
      if (_admin ||
          (r != AppRole.admin && r != AppRole.hr && r != AppRole.coordinator))
        r,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in [_first, _last]) {
      c.addListener(() {
        if (!_typedUsername) {
          _username.text = suggestUsername(_first.text, _last.text);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _username, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    final phone = _phone.text.trim();
    final (username, error) = await AccountService.create(
      l,
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      phoneNumber: phone.isEmpty ? '' : normalizeUaeMobile(phone),
      role: _role,
      username: _typedUsername ? _username.text.trim().toLowerCase() : '',
      password: _password.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (username == null) return;
    await showSignInDetails(context,
        name: '${_first.text.trim()} ${_last.text.trim()}',
        username: username,
        password: _password.text);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.addUser)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText: l.mobileNumberOptional,
                hintText: '05XXXXXXXX',
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              validator: (v) =>
                  (v ?? '').isEmpty || RegExp(r'^05\d{8}$').hasMatch(v!)
                      ? null
                      : l.mobileInvalid,
            ),
            SectionTitle(l.sectionRole),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final r in _roles)
                ChoiceChip(
                  label: Text(r.localized(l)),
                  selected: _role == r,
                  onSelected: (_) => setState(() => _role = r),
                ),
            ]),
            SectionTitle(l.sectionSignIn),
            TextFormField(
              controller: _username,
              autocorrect: false,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                labelText: l.username,
                helperText: l.usernameHelp,
                helperMaxLines: 3,
                prefixIcon: const Icon(Icons.alternate_email),
              ),
              onChanged: (_) => _typedUsername = true,
              validator: (v) {
                final u = (v ?? '').trim().toLowerCase();
                if (u.isEmpty) return l.errUsernameNeeded;
                return validUsername(u) ? null : l.usernameInvalid;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l.password,
                helperText: l.passwordHelper,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon:
                      Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                ),
              ),
              validator: (v) =>
                  (v ?? '').length < 6 ? l.passwordTooShort : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.bad)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.person_add_alt_1),
              label: Text(l.createAccount),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sign-in details to hand over, with a copy button.
Future<void> showSignInDetails(BuildContext context,
    {required String name,
    required String username,
    required String password}) {
  final l = context.l10n;
  final text = '${l.username}: $username\n${l.password}: $password';
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(l.accountCreatedTitle),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.accountCreatedBody(name)),
            const SizedBox(height: 16),
            SelectableText(text,
                textDirection: TextDirection.ltr,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.copied)));
          },
          icon: const Icon(Icons.copy),
          label: Text(l.copy),
        ),
        FilledButton(
            onPressed: () => Navigator.pop(context), child: Text(l.done)),
      ],
    ),
  );
}
