import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:royal_marble/core/app_theme.dart';
import 'package:royal_marble/core/locale_controller.dart';
import 'package:royal_marble/l10n/app_localizations.dart';
import 'package:royal_marble/services/auth.dart';

/// Apple sign-in is offered on iOS only. On Android it needs an Apple
/// "Services ID" set up in the Apple developer account and in Firebase.
final bool appleSignInAvailable = Platform.isIOS;

/// What to show for a failed sign-in, or null when there is nothing to say.
String? signInErrorText(AppLocalizations l10n, SignInError? error) =>
    switch (error) {
      null || SignInError.cancelled => null,
      SignInError.invalidEmail => l10n.errInvalidEmail,
      SignInError.userDisabled => l10n.errUserDisabled,
      SignInError.tooManyRequests => l10n.errTooManyRequests,
      SignInError.noInternet => l10n.errNoInternet,
      SignInError.wrongCredentials => l10n.errWrongCredentials,
      SignInError.accountExists => l10n.errAccountExists,
      SignInError.other => l10n.errSignInGeneric,
    };

/// "or" divider plus "Continue with Google" (and Apple on iOS). The same
/// buttons sign in existing people and start registration for new ones.
class SocialSignInButtons extends StatefulWidget {
  const SocialSignInButtons({super.key, this.onSignedIn, this.dividerOnTop = true});

  /// Called after a successful sign-in (e.g. to close the registration
  /// screen so the wrapper underneath can take over).
  final VoidCallback? onSignedIn;
  final bool dividerOnTop;

  @override
  State<SocialSignInButtons> createState() => _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends State<SocialSignInButtons> {
  final _auth = AuthService();
  String? _busy; // 'google' or 'apple'
  SignInError? _error;

  Future<void> _run(String which, Future<SignInError?> Function() signIn) async {
    setState(() {
      _busy = which;
      _error = null;
    });
    final error = await signIn();
    if (!mounted) return;
    setState(() {
      _busy = null;
      _error = error;
    });
    if (error == null) widget.onSignedIn?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final errorText = signInErrorText(l10n, _error);
    final divider = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(l10n.orDivider, style: const TextStyle(color: AppColors.muted)),
        ),
        const Expanded(child: Divider()),
      ]),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.dividerOnTop) divider,
      _ProviderButton(
        busy: _busy == 'google',
        enabled: _busy == null,
        icon: const _GoogleLogo(size: 20),
        label: l10n.continueWithGoogle,
        onPressed: () => _run('google', _auth.signInWithGoogle),
      ),
      if (appleSignInAvailable) ...[
        const SizedBox(height: 10),
        _ProviderButton(
          busy: _busy == 'apple',
          enabled: _busy == null,
          icon: const Icon(Icons.apple, size: 22, color: AppColors.charcoal),
          label: l10n.continueWithApple,
          onPressed: () => _run('apple', _auth.signInWithApple),
        ),
      ],
      if (errorText != null) ...[
        const SizedBox(height: 10),
        Text(errorText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.bad)),
      ],
      if (!widget.dividerOnTop) divider,
    ]);
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.busy,
    required this.enabled,
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final bool busy;
  final bool enabled;
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.charcoal,
        minimumSize: const Size.fromHeight(52),
      ),
      onPressed: enabled ? onPressed : null,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5))
            : icon,
        const SizedBox(width: 12),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

/// The four-colour Google "G", drawn so no image asset is needed.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GoogleLogoPainter());
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromCircle(
        center: Offset(s / 2, s / 2), radius: (s - stroke) / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double deg(double d) => d * math.pi / 180;
    // Angles clockwise from 3 o'clock; the gap at the right holds the bar.
    canvas.drawArc(rect, deg(-40), deg(85), false, paint..color = _blue);
    canvas.drawArc(rect, deg(45), deg(90), false, paint..color = _green);
    canvas.drawArc(rect, deg(135), deg(90), false, paint..color = _yellow);
    canvas.drawArc(rect, deg(225), deg(90), false, paint..color = _red);
    canvas.drawRect(
      Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2 - stroke / 10, stroke),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
