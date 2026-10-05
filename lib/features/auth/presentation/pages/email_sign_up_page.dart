import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/api_exception.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/brand_mark.dart';
import '../../../shell/presentation/pages/main_shell.dart';
import 'customer_onboarding_page.dart';

/// Matches [EmailLoginPage]: white canvas, brand header, boxed AppTheme
/// fields, forest 58 CTA with gold arrow — not the old underline form.
class EmailSignUpPage extends StatefulWidget {
  const EmailSignUpPage({super.key});

  @override
  State<EmailSignUpPage> createState() => _EmailSignUpPageState();
}

class _EmailSignUpPageState extends State<EmailSignUpPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool receivePromos = true;
  bool _isSigningUp = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// `POST /auth/signup` — creates a CUSTOMER account.
  /// First-time signups then complete onboarding
  /// (city + profile) before entering the app.
  Future<void> _enterApp() async {
    final name =
        '${firstNameController.text.trim()} ${lastNameController.text.trim()}'.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (name.isEmpty) {
      _showError('Enter your name');
      return;
    }
    if (!email.contains('@')) {
      _showError('Enter a valid email address');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSigningUp = true);
    try {
      final session = await AuthService.instance.signup(
        name: name,
        email: email,
        password: password,
      );
      AppHaptics.success();
      if (!mounted) return;

      final onboarded =
          session.user.isOnboarded ||
          await _fetchOnboarded();
      if (!mounted) return;

      if (onboarded) {
        _goToShell();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerOnboardingPage(
              name: name,
              phone: session.user.phone,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isSigningUp = false);
    }
  }

  Future<bool> _fetchOnboarded() async {
    try {
      final status = await OnboardingService.instance.getStatus();
      return status.isOnboarded;
    } on ApiException catch (_) {
      return false;
    }
  }

  void _goToShell() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: MainShell.routeName),
        builder: (_) => const MainShell(),
      ),
    );
  }

  void _showError(String message) {
    AppHaptics.press();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 4),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IconButton(
                        onPressed: () {
                          AppHaptics.press();
                          Navigator.pop(context);
                        },
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.brandForest,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const BrandMark(size: 32),
                    const SizedBox(width: 10),
                    const Text(
                      'MrBob',
                      style: TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: AppColors.brandGold,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sign up with email',
                        style: TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'One account for bookings, tracking and faster checkout.',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'First name',
                              child: TextField(
                                controller: firstNameController,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(
                                  color: AppColors.brandForest,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Aarav',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabeledField(
                              label: 'Last name',
                              child: TextField(
                                controller: lastNameController,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(
                                  color: AppColors.brandForest,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Sharma',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Email address',
                        child: TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: const TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'you@example.com',
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Password',
                        child: TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Minimum 8 characters',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                AppHaptics.tick();
                                setState(
                                  () => obscurePassword = !obscurePassword,
                                );
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Confirm password',
                        child: TextField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _enterApp(),
                          style: const TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Re-enter your password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                AppHaptics.tick();
                                setState(
                                  () => obscureConfirm = !obscureConfirm,
                                );
                              },
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Promo opt-in as a card, not a bare checkbox row.
                      GestureDetector(
                        onTap: () {
                          AppHaptics.tick();
                          setState(() => receivePromos = !receivePromos);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: receivePromos
                                ? AppColors.surfaceTint
                                : Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppColors.radiusCard,
                            ),
                            border: Border.all(
                              color: receivePromos
                                  ? AppColors.brandGold
                                  : AppColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: receivePromos
                                      ? AppColors.brandForest
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: receivePromos
                                        ? AppColors.brandForest
                                        : AppColors.border,
                                    width: 1.4,
                                  ),
                                ),
                                child: receivePromos
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Email me offers and booking updates',
                                  style: TextStyle(
                                    color: AppColors.brandForest,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  12 + MediaQuery.paddingOf(context).bottom * 0.4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 58,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSigningUp ? null : _enterApp,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandForest,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.only(left: 22, right: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: _isSigningUp
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Create account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: AppColors.brandGold,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: AppColors.brandForest,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            AppHaptics.press();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              color: AppColors.brandForest,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'By continuing you agree to Terms & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.brandForest,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
