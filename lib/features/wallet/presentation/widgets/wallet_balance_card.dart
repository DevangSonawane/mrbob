import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandForest,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandForest.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rs 1,240',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add money'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.brandGold),
                ),
                icon: const Icon(Icons.history_rounded),
                label: const Text('History'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
