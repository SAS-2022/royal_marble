import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:royal_marble/auth/forgot_pass.dart';
import 'package:royal_marble/core/usernames.dart';
import 'package:royal_marble/auth/register.dart';
import 'package:royal_marble/auth/social_buttons.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/widgets/language_picker.dart';
import 'package:royal_marble/services/auth.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInState();
}

class _SignInState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  SignInError? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    // On success the auth stream swaps this screen for the home screen.
    final error = await _auth.signIn(signInEmail(_email.text), _password.text);
    if (mounted) {
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  /// Username accounts get no reset emails: admins and HR set a new one.
  void _forgotPassword() {
    final typed = _email.text.trim();
    if (typed.isNotEmpty && !typed.contains('@')) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.resetPassword),
          content: Text(context.l10n.usernameResetBody),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(context), child: Text(context.l10n.ok)),
          ],
        ),
      );
      return;
    }
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ForgotPassScreen(emailAddress: typed)));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final l10n = context.l10n;
    final errorText = signInErrorText(l10n, _error);
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: top + 4, end: 8),
                  child: const LanguageButton(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/images/logo_2.jpg', height: 170),
                ),
              ),
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - top - 242),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.welcomeBack,
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(l10n.signInToContinue,
                            style: TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email, AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.emailOrUsername,
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          // People added by an admin or HR have a username.
                          validator: (v) {
                            final t = (v ?? '').trim();
                            return EmailValidator.validate(t) ||
                                    validUsername(t.toLowerCase())
                                ? null
                                : l10n.enterEmailOrUsername;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                          ),
                          validator: (v) =>
                              (v ?? '').isEmpty ? l10n.enterPassword : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            child: Text(l10n.forgotPassword),
                          ),
                        ),
                        if (errorText != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.badSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.bad, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(errorText,
                                    style:
                                        const TextStyle(color: AppColors.bad)),
                              ),
                            ]),
                          ),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(l10n.signIn),
                        ),
                        const SocialSignInButtons(),
                        const SizedBox(height: 12),
                        // The web dashboard is for admins; sign-up is on phones.
                        if (!kIsWeb)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l10n.newToApp,
                                style: TextStyle(color: AppColors.muted)),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen()),
                              ),
                              child: Text(l10n.createAccount),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
