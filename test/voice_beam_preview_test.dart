import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrbob/shared/widgets/voice_beam.dart';

void main() {
  testWidgets('voice beam preview', (t) async {
    final level = ValueNotifier<double>(0.8);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: Center(
            child: VoiceBeam(
              levelListenable: level,
              borderRadius: 20,
              child: Container(
                width: 350,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'My kitchen tap is leaking',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Real delays via runAsync: the driver integrates wall-clock dt.
    for (var i = 0; i < 60; i++) {
      level.value = 1.0;
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 32)));
      await t.pump();
    }
    await expectLater(
      find.byType(VoiceBeam),
      matchesGoldenFile('goldens/voice_beam_preview.png'),
    );
  });
}
