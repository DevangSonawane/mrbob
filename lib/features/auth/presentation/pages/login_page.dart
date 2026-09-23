import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import 'email_login_page.dart';
import '../../../shell/presentation/pages/main_shell.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTight = constraints.maxHeight < 720;

          return Stack(
            fit: StackFit.expand,
            children: [
              _LoginHeroImage(isTight: isTight),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(22, 0, 22, isTight ? 18 : 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _EmailButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmailLoginPage(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _SocialButton(
                                label: 'Google',
                                iconPath: 'assets/icons/google.svg',
                                onPressed: () => _enterApp(context),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SocialButton(
                                label: 'Apple',
                                iconPath: 'assets/icons/apple.svg',
                                onPressed: () => _enterApp(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'By continuing you agree Terms of Services & Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _enterApp(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }
}

class _LoginHeroImage extends StatelessWidget {
  const _LoginHeroImage({required this.isTight});

  final bool isTight;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: isTight ? 1.18 : 1.12,
      child: Image.asset(
        'assets/login/loginscreenfoto.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    );
  }
}

class _EmailButton extends StatelessWidget {
  const _EmailButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandGold,
          foregroundColor: Colors.black,
          shape: const StadiumBorder(
            side: BorderSide(color: Color(0x559A8C00)),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        child: const Text('Continue with E-mail', textAlign: TextAlign.center),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.iconPath,
    required this.onPressed,
  });

  final String label;
  final String iconPath;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF9B9B95)),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        ),
        icon: SvgPicture.asset(iconPath, width: 20, height: 20),
        label: Text(label),
      ),
    );
  }
}
