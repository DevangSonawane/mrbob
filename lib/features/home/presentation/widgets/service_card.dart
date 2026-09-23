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
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: service.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(service.icon, color: AppColors.brandForest),
              ),
              const SizedBox(height: 10),
              Text(
                service.badge,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandForest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                service.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  service.subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.mutedText),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Rs ${service.price}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Text(
                    service.duration,
                    style: const TextStyle(color: AppColors.mutedText),
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
