import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shell/presentation/pages/main_shell.dart';

/// Functional onboarding like Urban Company / Snabbit / Pronto.
///
/// Flownato UC flow (5 steps): phone -> location setup -> service area ->
/// notifications -> Home. Snabbit: OTP -> location -> book -> OTP & relax.
/// No service tour, no cards, no service-specific claims — the app is not
/// limited to 3 services, so we never list any.
///
/// 4 quiet steps on warm paper:
/// 0. Welcome (generic promise + social proof, one CTA)
/// 1. Phone (UC step 1)
/// 2. Location (UC steps 2-3, with Browse-anyway for non-serviceable)
/// 3. Notifications (UC step 4, soft ask with skip)
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final controller = PageController();
  int index = 0;

  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  String? phoneError;

  @override
  void dispose() {
    controller.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void _go(int page) {
    controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _enterApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: MainShell.routeName),
        builder: (_) => const MainShell(),
      ),
    );
  }

  void _submitPhone() {
    final digits = phoneController.text.replaceAll(RegExp(r'\D'), '');
    final number = digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : digits;
    if (number.length != 10) {
      setState(() => phoneError = 'Enter a valid 10-digit mobile number.');
      return;
    }
    setState(() => phoneError = null);
    FocusScope.of(context).unfocus();
    _go(2);
  }

  @override
  Widget build(BuildContext context) {
    const canvas = Color(0xFFF7F5F0);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: canvas,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: canvas),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                step: index,
                total: 4,
                onSkip: _enterApp,
              ),
              Expanded(
                child: PageView(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (v) => setState(() => index = v),
                  children: [
                    _WelcomeStep(onStart: () => _go(1), onBrowse: _enterApp),
                    _PhoneStep(
                      controller: phoneController,
                      error: phoneError,
                      onChanged: (_) {
                        if (phoneError != null) {
                          setState(() => phoneError = null);
                        }
                      },
                      onContinue: _submitPhone,
                    ),
                    _LocationStep(
                      controller: locationController,
                      onContinue: () => _go(3),
                      onBrowse: _enterApp,
                    ),
                    _NotifyStep(
                      onAllow: _enterApp,
                      onSkip: _enterApp,
                    ),
                  ],
                ),
              ),
              _Bottom(
                index: index,
                bottomInset: bottomInset,
                onBack: index == 0 ? null : () => _go(index - 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- chrome

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.total, required this.onSkip});

  final int step;
  final int total;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 16, 2),
      child: Row(
        children: [
          const Text(
            'MrBob',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(width: 12),
          // Slim quiet progress — functional, not marketing dots.
          Expanded(
            child: Row(
              children: List.generate(
                total,
                (i) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: i <= step
                          ? AppColors.brandForest
                          : AppColors.brandForest.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mutedText,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

class _Bottom extends StatelessWidget {
  const _Bottom({required this.index, required this.bottomInset, required this.onBack});

  final int index;
  final double bottomInset;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 14 + bottomInset * 0.5),
      child: Row(
        children: [
          if (onBack != null)
            TextButton(
              onPressed: onBack,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mutedText,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Back'),
            ),
          const Spacer(),
          Text(
            'Step ${index + 1} of 4',
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------- shared bits

class _StepShell extends StatelessWidget {
  const _StepShell({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 30,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 14.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 26),
          child,
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandForest,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _QuietInput extends StatelessWidget {
  const _QuietInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.prefix,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      style: const TextStyle(
        color: AppColors.brandForest,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        prefixIcon: prefix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.brandForest, width: 1.2),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- steps

/// Step 0 — generic promise. No services named, no cards.
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onStart, required this.onBrowse});

  final VoidCallback onStart;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      eyebrow: 'MrBob',
      title: 'Home help,\nwithout the hassle.',
      body:
          'Verified pros for whatever your home needs — cleaning, repairs and everything in between. Upfront pricing, on-time arrival.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrimaryButton(label: 'Get started', onTap: onStart),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onBrowse,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandForest,
              minimumSize: const Size.fromHeight(56),
              side: const BorderSide(color: AppColors.borderSubtle),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Browse the app'),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Icon(Icons.verified_outlined,
                  size: 15, color: AppColors.mutedText),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Background-checked pros · 4.8 rated · Pay after service',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Step 1 — UC "Enter phone number".
class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    required this.controller,
    required this.error,
    required this.onChanged,
    required this.onContinue,
  });

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      eyebrow: 'Step 1 · Account',
      title: "What's your\nnumber?",
      body:
          'We use it to confirm bookings and share your pro’s arrival updates. No spam, ever.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuietInput(
            controller: controller,
            hint: '98765 43210',
            keyboardType: TextInputType.phone,
            onChanged: onChanged,
            onSubmitted: onContinue,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 18, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+91',
                    style: TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    height: 22,
                    child: VerticalDivider(
                      color: AppColors.borderSubtle,
                      thickness: 1,
                      width: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(
                color: Color(0xFFC0392B),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _PrimaryButton(label: 'Continue', onTap: onContinue),
        ],
      ),
    );
  }
}

/// Steps 2-3 — UC "Choose location setup / Select service area".
/// Includes Browse-anyway so non-serviceable users are never blocked
/// (Snabbit teardown lesson).
class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.controller,
    required this.onContinue,
    required this.onBrowse,
  });

  final TextEditingController controller;
  final VoidCallback onContinue;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      eyebrow: 'Step 2 · Location',
      title: 'Where do you\nneed help?',
      body:
          'We check which pros can reach you fastest. If we’re not in your area yet, you can still look around.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuietInput(
            controller: controller,
            hint: 'Search area, landmark or pincode',
            keyboardType: TextInputType.text,
            onSubmitted: onContinue,
            prefix: const Icon(
              Icons.location_on_outlined,
              color: AppColors.mutedText,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandForest,
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.borderSubtle),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.my_location_outlined, size: 18),
            label: const Text('Use my current location'),
          ),
          const SizedBox(height: 16),
          _PrimaryButton(label: 'Confirm location', onTap: onContinue),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onBrowse,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mutedText,
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('Not sure yet? Browse the app first'),
          ),
        ],
      ),
    );
  }
}

/// Step 4 — UC "Choose notifications", soft version with skip.
class _NotifyStep extends StatelessWidget {
  const _NotifyStep({required this.onAllow, required this.onSkip});

  final VoidCallback onAllow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      eyebrow: 'Step 3 · Updates',
      title: 'Know when\nyour pro arrives.',
      body:
          'Booking confirmations and arrival alerts only. You can turn these off anytime.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Row(
              children: [
                Icon(Icons.notifications_outlined,
                    color: AppColors.brandForest, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '“Your pro is 10 mins away”\n“Booking confirmed for today, 4 PM”',
                    style: TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 13.5,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PrimaryButton(label: 'Allow notifications', onTap: onAllow),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mutedText,
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('Maybe later'),
          ),
        ],
      ),
    );
  }
}
