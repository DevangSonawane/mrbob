import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

class PaymentOption extends StatelessWidget {
  const PaymentOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? AppColors.surfaceTint : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(
          color: selected ? AppColors.brandGold : AppColors.borderSubtle,
          width: selected ? 1.2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandForest.withValues(alpha: 0.06)
                : AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.brandForest, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.brandForest,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        trailing: Icon(
          selected ? LucideIcons.circleCheck : LucideIcons.circle,
          color: selected ? AppColors.brandForest : AppColors.mutedText,
          size: 20,
        ),
      ),
    );
  }
}
