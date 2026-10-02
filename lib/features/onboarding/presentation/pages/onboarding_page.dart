import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shell/presentation/pages/main_shell.dart';

/// Functional onboarding like Urban Company / Snabbit / Pronto —
/// phone -> location -> notifications -> Home. No service tour, never
/// names a service (the app isn't limited to any).
///
/// Visual direction: dark cinematic welcome with drifting aurora +
/// live booking mock, then calm paper forms. All artwork is original
/// in-code (no stock, no copyright to clear).
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final controller = PageController();
  int index = 0;

  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  String? phoneError;

  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    controller.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void _go(int page) {
    controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 480),
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
    final dark = index == 0;
    final canvas = dark ? const Color(0xFF0A1F0E) : const Color(0xFFF7F5F0);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: canvas,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: canvas),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(step: index, total: 4, dark: dark, onSkip: _enterApp),
              Expanded(
                child: PageView(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (v) => setState(() => index = v),
                  children: [
                    _WelcomeStep(
                      drift: _drift,
                      onStart: () => _go(1),
                      onBrowse: _enterApp,
                    ),
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
                    _NotifyStep(onAllow: _enterApp, onSkip: _enterApp),
                  ],
                ),
              ),
              _Bottom(
                index: index,
                dark: dark,
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
  const _TopBar({
    required this.step,
    required this.total,
    required this.dark,
    required this.onSkip,
  });

  final int step;
  final int total;
  final bool dark;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : AppColors.brandForest;
    final sub = dark ? Colors.white70 : AppColors.mutedText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 16, 2),
      child: Row(
        children: [
          Text(
            'MrBob',
            style: TextStyle(
              color: fg,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(width: 12),
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
                          ? (dark ? AppColors.brandGold : AppColors.brandForest)
                          : (dark
                                ? Colors.white.withValues(alpha: 0.18)
                                : AppColors.brandForest.withValues(alpha: 0.14)),
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
              foregroundColor: sub,
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
  const _Bottom({
    required this.index,
    required this.dark,
    required this.bottomInset,
    required this.onBack,
  });

  final int index;
  final bool dark;
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
                foregroundColor: dark ? Colors.white70 : AppColors.mutedText,
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
            index == 0 ? 'Welcome' : 'Step $index of 3',
            style: TextStyle(
              color: dark ? Colors.white54 : AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------- motion bits

/// Staggered rise-in for step content. Cheap, no controllers needed.
class _Rise extends StatelessWidget {
  const _Rise({required this.delay, required this.child});

  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delay * 110),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 22),
          child: c,
        ),
      ),
      child: child,
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: 8 + _c.value * 3,
        height: 8 + _c.value * 3,
        decoration: BoxDecoration(
          color: const Color(0xFF4ADE80),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.55),
              blurRadius: 8 + _c.value * 8,
            ),
          ],
        ),
      ),
    );
  }
}

/// Original aurora — two gold/green blobs drifting on Lissajous paths.
class _Aurora extends StatelessWidget {
  const _Aurora({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, _) => CustomPaint(
          painter: _AuroraPainter(animation.value),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final p = t * 2 * math.pi;
    _blob(
      canvas,
      Offset(
        size.width * (0.5 + 0.42 * math.sin(p * 0.7)),
        size.height * (0.32 + 0.14 * math.cos(p * 0.9)),
      ),
      size.width * 0.55,
      const Color(0xFFFCB723).withValues(alpha: 0.20),
    );
    _blob(
      canvas,
      Offset(
        size.width * (0.5 + 0.40 * math.cos(p * 0.55 + 1.6)),
        size.height * (0.62 + 0.16 * math.sin(p * 0.8 + 0.6)),
      ),
      size.width * 0.62,
      const Color(0xFF2E7D4F).withValues(alpha: 0.34),
    );
    _blob(
      canvas,
      Offset(
        size.width * (0.5 + 0.36 * math.sin(p * 0.6 + 3.4)),
        size.height * (0.85 + 0.10 * math.cos(p + 1.1)),
      ),
      size.width * 0.5,
      const Color(0xFFFFE3A3).withValues(alpha: 0.10),
    );
  }

  void _blob(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.t != t;
}

// --------------------------------------------------------------- steps

/// Step 0 — cinematic, generic, no services named.
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    required this.drift,
    required this.onStart,
    required this.onBrowse,
  });

  final Animation<double> drift;
  final VoidCallback onStart;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: _Aurora(animation: drift)),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Rise(
                delay: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LiveDot(),
                      SizedBox(width: 8),
                      Text(
                        '2,400+ pros online now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _Rise(
                delay: 1,
                child: const Text(
                  'Home help,\nin minutes.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.6,
                    height: 1.02,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Rise(
                delay: 2,
                child: const Text(
                  'Verified pros at your door — cleaning, repairs and everything in between. Upfront price, pay after service.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              // Live booking mock — plain content card (skill §1: content
              // stays clean), glass CTA below stays a sibling, never nested.
              _Rise(delay: 3, child: const _BookingMock()),
              const SizedBox(height: 20),
              _Rise(
                delay: 4,
                // Proven vendor pattern (quality_comparison_demo +
                // home_page): forest-tinted GlassButton.custom, onTap,
                // own layer, sibling of all other glass.
                child: GlassButton.custom(
                  width: double.infinity,
                  height: 58,
                  shape: const LiquidRoundedSuperellipse(borderRadius: 29),
                  useOwnLayer: true,
                  settings: const LiquidGlassSettings(
                    glassColor: AppColors.brandGold,
                  ),
                  onTap: onStart,
                  child: const Center(
                    child: Text(
                      'Get started',
                      style: TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _Rise(
                delay: 5,
                child: Center(
                  child: TextButton(
                    onPressed: onBrowse,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Browse the app first'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Frosted live-booking preview. Static layout + animated progress bar.
class _BookingMock extends StatefulWidget {
  const _BookingMock();

  @override
  State<_BookingMock> createState() => _BookingMockState();
}

class _BookingMockState extends State<_BookingMock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.brandGold,
                child: Text(
                  'R',
                  style: TextStyle(
                    color: AppColors.brandForest,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ravi K. · 4.9 ★',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Background-checked · 2.1 km away',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '12 min',
                style: TextStyle(
                  color: AppColors.brandGold,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: 0.35 + _c.value * 0.45,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.brandGold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              _MockStep(icon: Icons.search_rounded, label: 'Tell us'),
              _MockDash(),
              _MockStep(icon: Icons.calendar_month_outlined, label: 'Pick slot'),
              _MockDash(),
              _MockStep(icon: Icons.spa_outlined, label: 'Relax'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MockStep extends StatelessWidget {
  const _MockStep({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MockDash extends StatelessWidget {
  const _MockDash();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 1,
      margin: const EdgeInsets.only(bottom: 18),
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}

// --------------------------------------------------------- form steps

class _FormShell extends StatelessWidget {
  const _FormShell({
    required this.icon,
    required this.tint,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.child,
  });

  final IconData icon;
  final Color tint;
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
          _Rise(
            delay: 0,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(icon, color: AppColors.brandForest, size: 24),
            ),
          ),
          const SizedBox(height: 18),
          _Rise(
            delay: 1,
            child: Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Rise(
            delay: 2,
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.9,
                height: 1.06,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Rise(delay: 3, child: Text(body, style: _bodyStyle)),
          const SizedBox(height: 24),
          _Rise(delay: 4, child: child),
        ],
      ),
    );
  }

  static const _bodyStyle = TextStyle(
    color: AppColors.mutedText,
    fontSize: 14.5,
    height: 1.6,
  );
}

class _GlassCta extends StatelessWidget {
  const _GlassCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassButton.custom(
      width: double.infinity,
      height: 56,
      shape: const LiquidRoundedSuperellipse(borderRadius: 28),
      useOwnLayer: true,
      settings: const LiquidGlassSettings(
        glassColor: AppColors.brandForest,
      ),
      onTap: onTap,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
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
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        prefixIcon: prefix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.brandForest,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

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
    return _FormShell(
      icon: Icons.smartphone_outlined,
      tint: const Color(0xFFFFF3D1),
      eyebrow: 'Step 1 · Account',
      title: "What's your\nnumber?",
      body: 'Booking confirmations and your pro’s live arrival. No spam, ever.',
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
                      fontWeight: FontWeight.w700,
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
          _GlassCta(label: 'Continue', onTap: onContinue),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'OTP auto-fills — no password to remember',
              style: TextStyle(color: AppColors.mutedText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return _FormShell(
      icon: Icons.location_on_outlined,
      tint: const Color(0xFFE7F0E7),
      eyebrow: 'Step 2 · Location',
      title: 'Where do you\nneed help?',
      body:
          'We match you with the fastest nearby pros. Not serviceable yet? Look around anyway.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuietInput(
            controller: controller,
            hint: 'Area, landmark or pincode',
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
          _GlassCta(label: 'Confirm location', onTap: onContinue),
          const SizedBox(height: 4),
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

class _NotifyStep extends StatelessWidget {
  const _NotifyStep({required this.onAllow, required this.onSkip});

  final VoidCallback onAllow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      icon: Icons.notifications_outlined,
      tint: const Color(0xFFF0EBDD),
      eyebrow: 'Step 3 · Updates',
      title: 'Know the second\nyour pro arrives.',
      body: 'Confirmations + live arrival only. Off anytime, no spam calls.',
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
            child: const Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.brandForest,
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Booking confirmed · Today, 4 PM',
                        style: TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'now',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.brandGold,
                      child: Icon(
                        Icons.directions_bike_outlined,
                        color: AppColors.brandForest,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your pro is 10 mins away',
                        style: TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '2m',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCta(label: 'Allow notifications', onTap: onAllow),
          const SizedBox(height: 4),
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
