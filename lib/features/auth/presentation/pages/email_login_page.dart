import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import 'email_sign_up_page.dart';
import '../../../shell/presentation/pages/main_shell.dart';

/// Continue-with-email as a Uiverse-style centered card,
/// re-skinned in MrBob tokens (no blue).
///
/// Snippet structure kept: heading → email input → password input →
/// forgot-password → gradient login button → "Or Sign in with" circles →
/// agreement link. Blue palette swapped for forest/gold/warm neutrals.
class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final emailController = TextEditingController(text: 'test@gmail.com');
  final passwordController = TextEditingController(text: 'test123');
  bool obscurePassword = true;
  String? errorText;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _enterApp() {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    if (email != 'test@gmail.com' || password != 'test123') {
      setState(() {
        errorText = 'Use the demo account below to explore the app.';
      });
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: MainShell.routeName),
        builder: (_) => const MainShell(),
      ),
    );
  }

  void _socialEnter() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: MainShell.routeName),
        builder: (_) => const MainShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 30,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.brandForest,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ---------------- the card (.container) ------------
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.white, AppColors.surfaceTint],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandForest.withValues(
                                    alpha: 0.10,
                                  ),
                                  blurRadius: 30,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // .heading
                                const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: AppColors.brandForest,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.6,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // .form .input — email
                                _CardInput(
                                  controller: emailController,
                                  hint: 'E-mail',
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) {
                                    if (errorText != null) {
                                      setState(() => errorText = null);
                                    }
                                  },
                                  suffix: ValueListenableBuilder(
                                    valueListenable: emailController,
                                    builder: (context, value, _) {
                                      if (value.text.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return IconButton(
                                        onPressed: emailController.clear,
                                        icon: const Icon(
                                          Icons.cancel_rounded,
                                          size: 18,
                                        ),
                                        color: AppColors.mutedText,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // .form .input — password
                                _CardInput(
                                  controller: passwordController,
                                  hint: 'Password',
                                  obscureText: obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _enterApp(),
                                  onChanged: (_) {
                                    if (errorText != null) {
                                      setState(() => errorText = null);
                                    }
                                  },
                                  suffix: IconButton(
                                    onPressed: () => setState(
                                      () => obscurePassword = !obscurePassword,
                                    ),
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                    ),
                                    color: AppColors.mutedText,
                                  ),
                                ),
                                if (errorText != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    errorText!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFC0392B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],

                                // .forgot-password
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 10,
                                      top: 10,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: const Text(
                                        'Forgot Password ?',
                                        style: TextStyle(
                                          color: AppColors.brandForest,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.brandGold,
                                          decorationThickness: 1.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // demo autofill helper
                                GestureDetector(
                                  onTap: () => setState(() {
                                    emailController.text = 'test@gmail.com';
                                    passwordController.text = 'test123';
                                    errorText = null;
                                  }),
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppColors.borderSubtle,
                                      ),
                                    ),
                                    child: const Text(
                                      'Demo: test@gmail.com · test123 — tap to autofill',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.mutedText,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // .login-button → forest gradient
                                _PressableScale(
                                  onTap: _enterApp,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF143014),
                                          AppColors.brandForest,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.brandForest
                                              .withValues(alpha: 0.32),
                                          blurRadius: 18,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'Sign In',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),

                                // .social-account-container
                                const Text(
                                  'Or Sign in with',
                                  style: TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _SocialCircle(
                                      onTap: _socialEnter,
                                      child: SvgPicture.asset(
                                        'assets/icons/google.svg',
                                        width: 22,
                                        height: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    _SocialCircle(
                                      onTap: _socialEnter,
                                      child: SvgPicture.asset(
                                        'assets/icons/apple.svg',
                                        width: 22,
                                        height: 22,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // .agreement
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: AppColors.mutedText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const EmailSignUpPage(),
                                        ),
                                      ),
                                      child: const Text(
                                        'Sign up',
                                        style: TextStyle(
                                          color: AppColors.brandForest,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.brandGold,
                                          decorationThickness: 1.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Learn user licence agreement',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Snippet `.form .input`: white, radius 20, soft shadow,
/// transparent sides → gold focus ring (brand swap for the cyan).
class _CardInput extends StatefulWidget {
  const _CardInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_CardInput> createState() => _CardInputState();
}

class _CardInputState extends State<_CardInput> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGold.withValues(
              alpha: _focused ? 0.28 : 0.16,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Focus(
        onFocusChange: (value) => setState(() => _focused = value),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscureText,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: const TextStyle(
            color: AppColors.brandForest,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 14.5,
              fontWeight: FontWeight.w400,
            ),
            suffixIcon: widget.suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.transparent, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(
                color: AppColors.brandGold,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Press-scale wrapper for the snippet's hover 1.03 / active 0.95.
class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Snippet `.social-button`: circle, white ring, soft shadow.
/// White (not black) so Google/Apple glyphs stay legible on the card.
class _SocialCircle extends StatefulWidget {
  const _SocialCircle({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_SocialCircle> createState() => _SocialCircleState();
}

class _SocialCircleState extends State<_SocialCircle> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandForest.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
