import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brand_mark.dart';
import '../../../auth/presentation/pages/login_page.dart';

/// Premium 2026 home-services onboarding.
///
/// Market pattern (Urban Company / Thumbtack / Taskrabbit):
/// - clean white canvas, no baked waves or full-bleed stretched art
/// - hero lives inside a rounded card so photography feels contained
/// - one clear headline, muted body, slim segmented progress
/// - single dark CTA with one gold arrow affordance
///
/// The existing assets are good illustrations but they ship with a baked
/// yellow/green wave footer (~bottom 18%). We deliberately crop that off
/// in-code with [BoxFit.cover] + topCenter alignment inside a fixed card,
/// so the design you liked stays, minus the cheap-looking wave.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final controller = PageController();
  int index = 0;

  static const _steps = [
    _StepData(
      imagePath: 'assets/mrbob_onboarding/1.png',
      eyebrow: 'Electrical',
      title: 'Expert fixes at your doorstep',
      body:
          'Book verified electricians for safe switch, wiring and panel repairs — upfront pricing, on-time arrival.',
      chip: 'Verified electricians',
    ),
    _StepData(
      imagePath: 'assets/mrbob_onboarding/2.png',
      eyebrow: 'Plumbing',
      title: 'Plumbing help, right on time',
      body:
          'Get trained pros for leaks, fittings and bathroom repairs, with photo diagnosis before the visit.',
      chip: 'Same-day slots',
    ),
    _StepData(
      imagePath: 'assets/mrbob_onboarding/3.png',
      eyebrow: 'Paint & finish',
      title: 'Fresh finishes after move-in',
      body:
          'Handle paint touch-ups and post-construction snags without contractor chaos. One booking, done right.',
      chip: 'Move-in ready',
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (index == _steps.length - 1) {
      _finish();
    } else {
      controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
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
              _Header(isLast: index == _steps.length - 1, onSkip: _finish),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: _steps.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (value) => setState(() => index = value),
                  itemBuilder: (context, i) => _StepBody(step: _steps[i]),
                ),
              ),
              _Footer(
                index: index,
                pageCount: _steps.length,
                title: _steps[index].title,
                body: _steps[index].body,
                eyebrow: _steps[index].eyebrow,
                onNext: _goNext,
                onBack: () => controller.previousPage(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepData {
  const _StepData({
    required this.imagePath,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.chip,
  });

  final String imagePath;
  final String eyebrow;
  final String title;
  final String body;
  final String chip;
}

// ---------------------------------------------------------------- header

class _Header extends StatelessWidget {
  const _Header({required this.isLast, required this.onSkip});

  final bool isLast;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: Row(
        children: [
          const BrandMark(size: 34),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MrBob',
                style: TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
              ),
              Text(
                'Home services, done right',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Ghost skip — no frosted pill floating over photography.
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mutedText,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(isLast ? 'Done' : 'Skip'),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- page body

class _StepBody extends StatelessWidget {
  const _StepBody({required this.step});

  final _StepData step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [Expanded(child: _HeroCard(step: step))],
      ),
    );
  }
}

/// Contained hero card — this is the core "un-zoomed + premium" fix.
///
/// The source PNGs are tall portraits with a baked wave footer. By fixing
/// the card height (flex) and using cover+topCenter, Flutter scales the
/// image to fill the width and crops the bottom wave away. Nothing is
/// stretched, faces stay in frame, edges get a soft premium treatment.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.step});

  final _StepData step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Top-anchored so the baked bottom wave is the first thing
            // cropped out on every screen size.
            Image.asset(
              step.imagePath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
            ),
            // Soft bottom scrim so the floating chip always reads well,
            // without the old full-screen white wash that looked muddy.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.62, 1.0],
                  colors: [Color(0x00000000), Color(0x140D230D)],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.brandForest,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '4.8 · Trusted pros',
                      style: TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandForest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.brandGold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: AppColors.brandForest,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          step.chip,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- footer

class _Footer extends StatelessWidget {
  const _Footer({
    required this.index,
    required this.pageCount,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.onNext,
    required this.onBack,
  });

  final int index;
  final int pageCount;
  final String eyebrow;
  final String title;
  final String body;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isLast = index == pageCount - 1;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 12 + bottomInset * 0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(title),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                    Text(
                      eyebrow.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(
                    pageCount,
                    (dot) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        height: 4,
                        margin: EdgeInsets.only(
                          right: dot == pageCount - 1 ? 0 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: dot <= index
                              ? AppColors.brandForest
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(index + 1).toString().padLeft(2, '0')} / ${pageCount.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (index > 0)
                Container(
                  width: 58,
                  height: 58,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                    color: Colors.white,
                  ),
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.brandForest,
                    ),
                    tooltip: 'Back',
                  ),
                ),
              Expanded(
                child: SizedBox(
                  height: 58,
                  child: FilledButton(
                    onPressed: onNext,
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isLast ? 'Get started' : 'Next',
                            style: const TextStyle(
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
                          child: Icon(
                            isLast
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            color: AppColors.brandForest,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
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
