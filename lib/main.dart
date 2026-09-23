import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Compile liquid-glass shaders before the first frame so the search
  // pill is glass immediately instead of frosted for a moment.
  await LiquidGlassShaders.ensureLoaded();
  runApp(const PostFixApp());
}

class PostFixApp extends StatelessWidget {
  const PostFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PostFix',
      theme: AppTheme.light,
      home: const OnboardingPage(),
    );
  }
}
