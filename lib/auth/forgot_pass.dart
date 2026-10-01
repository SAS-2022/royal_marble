import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/core/app_theme.dart';
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
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _auth.resetPassword(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      // resetPassword returns an error string on failure, null on success.
      if (result is String) {
        _error = 'Could not send the email. Check the address and try again.';
      } else {
        _sent = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
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
                const Text('Check your email',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'We sent a reset link to ${_email.text.trim()}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to sign in'),
                ),
              ])
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter the email you sign in with and we\'ll send you a link to choose a new password.',
                      style: TextStyle(color: AppColors.ink, fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) => EmailValidator.validate((v ?? '').trim())
                          ? null
                          : 'Enter a valid email',
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
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
                          : const Text('Send reset link'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
