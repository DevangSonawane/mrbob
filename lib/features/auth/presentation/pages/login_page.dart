import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'email_login_page.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../shell/presentation/pages/main_shell.dart';

// Exact clone of Trumarks onboarding design
// (trumarkz/lib/features/onboarding/presentation/pages/onboarding_page.dart)
// applied to the MrBob Get Started / login page, using
// assets/login/loginpage.png as the hero image.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Image.asset(
                  'assets/login/loginpage.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withAlpha(0),
                        Colors.black.withAlpha(0),
                        Colors.black.withAlpha(150),
                      ],
                      stops: const <double>[0, 0.58, 1],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    48 + systemBottomInset,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Column(
                          children: <Widget>[
                            _LoginTitleLine(text: 'Every care,'),
                            SizedBox(height: 8),
                            _LoginTitleLine(text: 'handled.'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Align(
                          child: SizedBox(
                            width: 252,
                            child: _PrimaryLoginButton(
                              onPressed: null,
                              label: 'Continue with E-mail',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Divider(color: Colors.white.withAlpha(45)),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Or',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withAlpha(105),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Divider(color: Colors.white.withAlpha(45)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: 76,
                              child: _IconAuthButton(
                                onPressed: () => _enterApp(context),
                                icon: SvgPicture.asset(
                                  'assets/icons/google.svg',
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 76,
                              child: _IconAuthButton(
                                onPressed: () => _enterApp(context),
                                icon: SvgPicture.asset(
                                  'assets/icons/apple.svg',
                                  width: 22,
                                  height: 22,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withAlpha(165),
                              height: 1.35,
                            ),
                            children: <InlineSpan>[
                              const TextSpan(
                                text: 'By continuing you agree to\n',
                              ),
                              TextSpan(
                                text: 'Terms of Services & Privacy Policy.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                  decorationThickness: 1.1,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
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

  void _enterApp(BuildContext context) {
    AppHaptics.confirm();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: MainShell.routeName),
        builder: (_) => const MainShell(),
      ),
    );
  }
}

// Builder wrapper so the primary button can navigate while staying
// visually identical to the Trumarks onboarding button.
class _PrimaryLoginButton extends StatelessWidget {
  const _PrimaryLoginButton({required this.onPressed, required this.label});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return ElevatedButton(
          onPressed: () {
            AppHaptics.press();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmailLoginPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            elevation: 0,
            foregroundColor: Colors.black,
            disabledForegroundColor: Colors.grey,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        );
      },
    );
  }
}

class _LoginTitleLine extends StatelessWidget {
  const _LoginTitleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 26,
          color: Colors.white,
          fontWeight: FontWeight.w300,
          height: 1,
        ),
      ),
    );
  }
}

class _IconAuthButton extends StatelessWidget {
  const _IconAuthButton({required this.onPressed, required this.icon});

  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.white.withAlpha(enabled ? 64 : 28),
                    Colors.white.withAlpha(enabled ? 22 : 12),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withAlpha(enabled ? 130 : 54),
                  width: 1,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha(18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withAlpha(28),
                    blurRadius: 10,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: IconTheme(
                data: IconThemeData(
                  color: enabled ? Colors.white : Colors.grey,
                ),
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
