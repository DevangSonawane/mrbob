import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SupportTile extends StatelessWidget {
  const SupportTile({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.brandForest.withValues(alpha: 0.06),
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
            letterSpacing: -0.1,
          ),
        ),
        subtitle: Text(
          body,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
