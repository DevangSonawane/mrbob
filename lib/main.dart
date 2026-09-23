import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-warm the liquid-glass fragment shaders before the first frame so
  // glass surfaces render immediately instead of flashing (SKILL.md §2).
  await LiquidGlassWidgets.initialize();
  runApp(
    LiquidGlassWidgets.wrap(
      // Off: the experimental tier-stepping re-grades glass quality at
      // runtime (benchmark ~3s after launch, then ongoing demote/recover),
      // which made the tab-bar indicator visibly pop in and out on device.
      // Deterministic standard quality until the package's thresholds mature.
      adaptiveQuality: false,
      respectSystemAccessibility: true,
      // Bridges Material ThemeMode into the glass brightness cascade
      // without the package importing flutter/material (SKILL.md §2).
      brightnessResolver: Theme.maybeBrightnessOf,
      theme: GlassThemeData.simple(
        blur: 12,
        thickness: 25,
        quality: GlassQuality.standard,
      ),
      child: const MrBobApp(),
    ),
  );
}

class MrBobApp extends StatelessWidget {
  const MrBobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MrBob',
      theme: AppTheme.light,
      home: const OnboardingPage(),
    );
  }
}
