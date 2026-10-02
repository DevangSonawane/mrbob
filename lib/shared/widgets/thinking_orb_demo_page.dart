import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/thinking_orb.dart';

/// Standalone preview for the thinking-orbs port.
///
/// Run temporarily as home to eyeball it:
/// `home: const ThinkingOrbDemoPage(),`
/// then swap back to OnboardingPage when done.
class ThinkingOrbDemoPage extends StatefulWidget {
  const ThinkingOrbDemoPage({super.key});

  @override
  State<ThinkingOrbDemoPage> createState() => _ThinkingOrbDemoPageState();
}

class _ThinkingOrbDemoPageState extends State<ThinkingOrbDemoPage> {
  double _amp = 0.35;
  ThinkingOrbState _state = ThinkingOrbState.listening;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thinking Orb — demo'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandForest,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Center(
              child: ThinkingOrb(
                size: 160,
                state: _state,
                amplitude: _amp,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'State',
            style: TextStyle(
              color: AppColors.brandForest,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThinkingOrbState>(
            segments: const [
              ButtonSegment(
                value: ThinkingOrbState.listening,
                label: Text('Listening'),
              ),
              ButtonSegment(
                value: ThinkingOrbState.breathing,
                label: Text('Breathing'),
              ),
              ButtonSegment(
                value: ThinkingOrbState.working,
                label: Text('Working'),
              ),
            ],
            selected: {_state},
            onSelectionChanged: (s) => setState(() => _state = s.first),
          ),
          const SizedBox(height: 18),
          Text(
            'Mic amplitude — ${_amp.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.brandForest,
              fontWeight: FontWeight.w800,
            ),
          ),
          Slider(
            value: _amp,
            min: 0,
            max: 1,
            onChanged: (v) => setState(() => _amp = v),
          ),
          const Text(
            'Slide this while watching — in the real sheet this is wired '
            'to live _voiceLevel from the mic. 0 = idle breathe, 1 = loud.',
            style: TextStyle(color: AppColors.mutedText, height: 1.4),
          ),
          const SizedBox(height: 18),
          const Text(
            'Sizes (64 chat-avatar vs 160 hero)',
            style: TextStyle(
              color: AppColors.brandForest,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ThinkingOrb(
                size: 64,
                state: _state,
                amplitude: _amp,
              ),
              ThinkingOrb(
                size: 96,
                state: _state,
                amplitude: _amp,
              ),
              ThinkingOrb(
                size: 160,
                state: _state,
                amplitude: _amp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
