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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.card_giftcard_rounded, size: 44),
              const SizedBox(height: 14),
              Text(
                'Give Rs 100, get Rs 150',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your friend gets wallet credit after their first booking. You earn when the job is completed.',
              ),
              const SizedBox(height: 16),
              const SelectableText(
                'POSTFIX150',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
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
