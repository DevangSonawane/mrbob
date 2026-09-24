import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/simple_page.dart';
import '../../../../shared/widgets/support_tile.dart';

class ReferPage extends StatelessWidget {
  const ReferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimplePage(
      title: 'Refer and earn',
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandForest.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 24,
                  color: AppColors.brandForest,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Give Rs 100, get Rs 150',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.brandForest,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your friend gets wallet credit after their first booking. You earn when the job is completed.',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              const SelectableText(
                'MRBOB150',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.brandForest,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: null,
                icon: Icon(Icons.share_rounded),
                label: Text('Share invite'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SupportTile(
          icon: Icons.group_rounded,
          title: '3 friends joined',
          body: 'Rs 450 earned so far',
        ),
      ],
    );
  }
}
