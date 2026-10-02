// Original artwork for MrBob — created in-code, 2026.
// No third-party images, no stock, no fonts. 100% owned by the project,
// free for commercial use. Soft beige + editorial numeral + thin icon.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Calm visual direction: warm paper, two soft radial washes,
/// one giant ghost numeral, one thin icon in a frosted circle.
class CalmVisual extends StatelessWidget {
  const CalmVisual({
    super.key,
    required this.icon,
    required this.numeral,
    required this.base,
    required this.washA,
    required this.washB,
  });

  final IconData icon;
  final String numeral;
  final Color base;
  final Color washA;
  final Color washB;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft wash A — top left, original gradient composition.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.7, -0.6),
                  radius: 0.9,
                  colors: [washA, washA.withValues(alpha: 0)],
                ),
              ),
            ),
            // Soft wash B — bottom right.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.75, 0.8),
                  radius: 1.0,
                  colors: [washB, washB.withValues(alpha: 0)],
                ),
              ),
            ),
            // Giant ghost numeral — editorial, premium-minimal cue.
            Positioned(
              right: 8,
              bottom: -18,
              child: IgnorePointer(
                child: Text(
                  numeral,
                  style: TextStyle(
                    color: AppColors.brandForest.withValues(alpha: 0.07),
                    fontSize: 168,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -8,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            // Center icon — thin, quiet, frosted.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.62),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.brandForest.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 34,
                      weight: 1.2,
                      color: AppColors.brandForest,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 36,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.brandForest.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
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
