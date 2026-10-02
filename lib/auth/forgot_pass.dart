import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/services/auth.dart';

class ForgotPassScreen extends StatefulWidget {
  const ForgotPassScreen({super.key, this.emailAddress});
  final String? emailAddress;

  @override
  State<ForgotPassScreen> createState() => _ForgotPassScreenState();
}

class _ForgotPassScreenState extends State<ForgotPassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  late final _email = TextEditingController(text: widget.emailAddress);
  bool _loading = false;
  bool _sent = false;
  bool _failed = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final result = await _auth.resetPassword(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      // resetPassword returns an error string on failure, null on success.
      if (result is String) {
        _failed = true;
      } else {
        _sent = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPassword)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? Column(children: [
                const SizedBox(height: 40),
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.okSoft,
                  child: Icon(Icons.mark_email_read,
                      size: 36, color: AppColors.ok),
                ),
                const SizedBox(height: 20),
                Text(l10n.checkYourEmail,
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  l10n.resetSent(_email.text.trim()),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.backToSignIn),
                ),
              ])
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.resetIntro,
                      style: TextStyle(color: AppColors.ink, fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) => EmailValidator.validate((v ?? '').trim())
                          ? null
                          : l10n.enterValidEmail,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_failed) ...[
                      const SizedBox(height: 12),
                      Text(l10n.resetError,
                          style: const TextStyle(color: AppColors.bad)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(l10n.sendResetLink),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
