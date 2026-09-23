import 'package:flutter/material.dart';

import '../../../../core/models/service_item.dart';
import '../../../../core/theme/app_colors.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, required this.onTap});

  final ServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: service.color,
                  borderRadius: BorderRadius.circular(
                    AppColors.radiusCardInner,
                  ),
                ),
                child: Icon(
                  service.icon,
                  color: AppColors.brandForest,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                service.badge,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.brandForest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                service.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.15,
                  color: AppColors.brandForest,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  service.subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Rs ${service.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: AppColors.brandForest,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    service.duration,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
