import 'package:flutter/material.dart';

class ServiceItem {
  const ServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.price,
    required this.duration,
    required this.questions,
    required this.badge,
    required this.color,
    this.supportsInstant = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int price;
  final String duration;
  final List<String> questions;
  final String badge;
  final Color color;

  /// Whether the service can be fulfilled instantly ("now").
  ///
  /// Small, self-contained jobs default to scheduled-only; each
  /// instant-capable service opts in explicitly in [services].
  final bool supportsInstant;
}
