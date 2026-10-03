import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../auth/presentation/pages/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    _OnboardingSlide(
      imagePath: 'assets/mrbob_onboarding/OnBoarding.png',
      title: 'Every home fix, one app.',
      subtitle:
          'Cleaning, repairs, AC and plumbing — book a verified pro in a couple of taps, with no call queue to sit in.',
    ),
    _OnboardingSlide(
      imagePath: 'assets/mrbob_onboarding/MrBob HVAC Ductwork Installation.png',
      title: 'Know the moment they arrive.',
      subtitle:
          'Track your pro live, see the price before you confirm, and pay only once the job is done.',
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    AppHaptics.press();

    if (!_isLast) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        // Both onboarding photos are bright at the top, so the status bar needs
        // dark icons now that the scrim is gone.
        value: SystemUiOverlayStyle.dark,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _SlidePager(
              controller: _controller,
              slides: _slides,
              onPageChanged: (value) => setState(() => _index = value),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _OnboardingDialog(
                  key: ValueKey(_index),
                  slide: _slides[_index],
                  index: _index,
                  count: _slides.length,
                  isLast: _isLast,
                  onContinue: _continue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  final String imagePath;
  final String title;
  final String subtitle;
}

/// Full-bleed photo pager with a subtle depth scale: the outgoing photo eases
/// back while the incoming one settles in, so the swipe reads as parallax
/// instead of a flat slide.
class _SlidePager extends StatelessWidget {
  const _SlidePager({
    required this.controller,
    required this.slides,
    required this.onPageChanged,
  });

  final PageController controller;
  final List<_OnboardingSlide> slides;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: slides.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: controller,
          child: Image.asset(slides[index].imagePath, fit: BoxFit.cover),
          builder: (context, child) {
            var page = index.toDouble();
            if (controller.hasClients && controller.position.haveDimensions) {
              page = controller.page ?? page;
            }
            final distance = (index - page).abs().clamp(0.0, 1.0);
            return Transform.scale(scale: 1.0 + 0.06 * distance, child: child);
          },
        );
      },
    );
  }
}

/// The bottom dialog: one solid white panel, flush with the left, right and
/// bottom edges. Colour runs under the home indicator on purpose — only the
/// content is inset, so the fill never breaks the edge-to-edge block.
class _OnboardingDialog extends StatelessWidget {
  const _OnboardingDialog({
    super.key,
    required this.slide,
    required this.index,
    required this.count,
    required this.isLast,
    required this.onContinue,
  });

  final _OnboardingSlide slide;
  final int index;
  final int count;
  final bool isLast;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(26, 30, 26, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slide.title,
              style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.08,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              slide.subtitle,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                _ProgressDots(count: count, index: index),
                const Spacer(),
                _ContinueButton(isLast: isLast, onPressed: onContinue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Slide ${index + 1} of $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var dot = 0; dot < count; dot++)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: dot == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dot == index
                      ? AppColors.brandGold
                      : AppColors.brandForest.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.isLast, required this.onPressed});

  final bool isLast;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isLast ? 'Get started' : 'Next',
      child: SizedBox(
        width: 56,
        height: 56,
        child: FilledButton(
          key: const Key('onboarding-next-button'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandGold,
            foregroundColor: AppColors.brandForest,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
          ),
          child: Icon(
            isLast ? LucideIcons.arrowRight : LucideIcons.chevronRight,
            size: 26,
          ),
        ),
      ),
    );
  }
}