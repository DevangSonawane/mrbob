import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class WalletRow extends StatelessWidget {
  const WalletRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppColors.brandForest,
            size: 18,
          ),
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
          ),
        ),
        trailing: Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: AppColors.brandForest,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
