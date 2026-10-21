import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/locale_controller.dart';
import '../models/user_model.dart';
import '../services/account_service.dart';

/// A password field with a show/hide eye.
class _PasswordField extends StatefulWidget {
  const _PasswordField(
      {required this.controller, required this.label, this.validator});
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          ),
        ),
        validator: widget.validator,
      );
}

/// A form dialog that runs [save] (null = success, else the error shown)
/// and closes with true once it succeeds.
Future<bool> _passwordDialog(BuildContext context,
    {required String title,
    required List<Widget> Function(BuildContext) fields,
    required Future<String?> Function() save}) async {
  final form = GlobalKey<FormState>();
  String? error;
  var busy = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 360,
          child: Form(
            key: form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ...fields(context),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: AppColors.bad)),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel)),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    final e = await save();
                    if (!context.mounted) return;
                    if (e == null) return Navigator.pop(context, true);
                    setState(() {
                      busy = false;
                      error = e;
                    });
                  },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    ),
  );
  return ok == true;
}

/// Admins and HR give [user] a new password (username accounts get no
/// reset emails).
Future<void> showSetPasswordDialog(BuildContext context, UserData user) async {
  final l = context.l10n;
  final password = TextEditingController();
  final name = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
  final saved = await _passwordDialog(
    context,
    title: l.setNewPassword,
    fields: (_) => [
      _PasswordField(
          controller: password,
          label: l.newPassword,
          validator: (v) => (v ?? '').length < 6 ? l.passwordTooShort : null),
    ],
    save: () =>
        AccountService.setPassword(l, uid: user.uid!, password: password.text),
  );
  if (saved && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.passwordSetFor(name))));
  }
}

/// The signed-in person changes their own password.
Future<void> showChangePasswordDialog(BuildContext context) async {
  final l = context.l10n;
  final current = TextEditingController();
  final next = TextEditingController();
  final again = TextEditingController();
  final saved = await _passwordDialog(
    context,
    title: l.changePassword,
    fields: (_) => [
      _PasswordField(
          controller: current,
          label: l.currentPassword,
          validator: (v) => (v ?? '').isEmpty ? l.enterPassword : null),
      const SizedBox(height: 8),
      _PasswordField(
          controller: next,
          label: l.newPassword,
          validator: (v) => (v ?? '').length < 6 ? l.passwordTooShort : null),
      const SizedBox(height: 8),
      _PasswordField(
          controller: again,
          label: l.confirmPassword,
          validator: (v) => v != next.text ? l.passwordsDontMatch : null),
    ],
    save: () =>
        AccountService.changeOwn(l, current: current.text, next: next.text),
  );
  if (saved && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.passwordChanged)));
  }
}
