import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final controller = PageController();
  int index = 0;

  final pages = const [
    _OnboardingStep(
      imagePath: 'assets/postfix_onboarding/1.png',
      title: 'Expert fixes at your doorstep',
      body:
          'Book verified electricians for safe switch, wiring and panel repairs.',
    ),
    _OnboardingStep(
      imagePath: 'assets/postfix_onboarding/2.png',
      title: 'Plumbing help, right on time',
      body: 'Get trained pros for leaks, fittings and bathroom repair work.',
    ),
    _OnboardingStep(
      imagePath: 'assets/postfix_onboarding/3.png',
      title: 'Fresh finishes after move-in',
      body:
          'Handle paint touch-ups and post-construction snags without contractor chaos.',
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller,
            onPageChanged: (value) => setState(() => index = value),
            children: pages,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 6, right: 14),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandForest,
                    backgroundColor: Colors.white.withValues(alpha: 0.7),
                    minimumSize: const Size(56, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                child: _OnboardingControls(
                  title: pages[index].title,
                  body: pages[index].body,
                  index: index,
                  pageCount: pages.length,
                  onNext: index == pages.length - 1
                      ? _finish
                      : () => controller.nextPage(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOut,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}

class _OnboardingControls extends StatelessWidget {
  const _OnboardingControls({
    required this.title,
    required this.body,
    required this.index,
    required this.pageCount,
    required this.onNext,
  });

  final String title;
  final String body;
  final int index;
  final int pageCount;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final isTight = height < 700;
    final titleSize = isTight ? 27.0 : 31.0;
    final bodySize = isTight ? 14.0 : 15.5;
    final textSpacing = isTight ? 10.0 : 12.0;
    final progressSpacing = isTight ? 20.0 : 26.0;
    final buttonSpacing = isTight ? 20.0 : 26.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Column(
              key: ValueKey(title),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.brandForest,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                SizedBox(height: textSpacing),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.mutedText,
                    fontSize: bodySize,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: progressSpacing),
        _ProgressPill(index: index, pageCount: pageCount, isTight: isTight),
        SizedBox(height: buttonSpacing),
        _BottomActionButton(
          isLast: index == pageCount - 1,
          isTight: isTight,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({
    required this.index,
    required this.pageCount,
    required this.isTight,
  });

  final int index;
  final int pageCount;
  final bool isTight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isTight ? 70 : 78,
      height: isTight ? 12 : 13,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: const Color(0xFF121C1A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(
          pageCount,
          (dot) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.only(right: dot == pageCount - 1 ? 0 : 3),
              decoration: BoxDecoration(
                color: dot <= index ? AppColors.brandGold : Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.isLast,
    required this.isTight,
    required this.onPressed,
  });

  final bool isLast;
  final bool isTight;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = isTight ? 58.0 : 64.0;
    final circleSize = isTight ? 42.0 : 48.0;
    final iconSize = isTight ? 22.0 : 25.0;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF121C1A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const StadiumBorder(),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home_repair_service_rounded,
                  color: AppColors.brandForest,
                  size: iconSize,
                ),
              ),
            ),
            Text(
              isLast ? 'Start' : 'Next',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  color: AppColors.brandForest,
                  size: iconSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingFade extends StatelessWidget {
  const _OnboardingFade();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.38, 0.58, 0.82, 1],
          colors: [
            Color(0x00FFFFFF),
            Color(0x08FFFFFF),
            Color(0xDFFFFFFF),
            Color(0xF2FFFFFF),
            Color(0xCFFFFFFF),
          ],
        ),
      ),
    );
  }
}

class _OnboardingImage extends StatelessWidget {
  const _OnboardingImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxHeight < 700;
        final imageWidth = constraints.maxWidth * (isTight ? 0.82 : 0.88);

        return Align(
          alignment: Alignment.topCenter,
          child: Image.asset(
            imagePath,
            width: imageWidth,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
          ),
        );
      },
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.imagePath,
    required this.title,
    required this.body,
  });

  final String imagePath;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _OnboardingImage(imagePath: imagePath),
        const _OnboardingFade(),
      ],
    );
  }
}
