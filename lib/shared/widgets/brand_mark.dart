import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.brandForest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.build_circle_rounded,
        color: AppColors.brandGold,
        size: size * 0.64,
      ),
    );
  }
}
