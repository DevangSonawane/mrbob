import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/service_item.dart';

const services = [
  ServiceItem(
    title: 'Civil touch-ups',
    subtitle: 'Cracks, plaster chips, hollow patches',
    icon: LucideIcons.construction,
    price: 599,
    duration: '90 min',
    badge: 'Most booked',
    color: Color(0xFFFFF3D0),
    questions: [
      'Where is the damage located?',
      'Approximate damaged area?',
      'Is material available on site?',
    ],
  ),
  ServiceItem(
    title: 'Plumbing fixes',
    subtitle: 'Leaks, faucets, traps, low pressure',
    icon: LucideIcons.wrench,
    price: 399,
    duration: '60 min',
    badge: 'Instant ready',
    color: Color(0xFFFFF8E8),
    questions: [
      'What needs fixing?',
      'Is water supply currently shut?',
      'Any concealed pipeline work?',
    ],
  ),
  ServiceItem(
    title: 'Electrical snags',
    subtitle: 'Switches, sockets, lights, tripping',
    icon: LucideIcons.zap,
    price: 449,
    duration: '75 min',
    badge: 'Verified pro',
    color: Color(0xFFFFE3A1),
    questions: [
      'Which fixture is affected?',
      'Is the issue recurring?',
      'Do you need new parts installed?',
    ],
  ),
  ServiceItem(
    title: 'Painting repairs',
    subtitle: 'Patch paint, seepage stains, scuffs',
    icon: LucideIcons.paintRoller,
    price: 699,
    duration: '2 hr',
    badge: 'Clean finish',
    color: Color(0xFFF7F3EA),
    questions: [
      'What is the wall finish?',
      'Do you know the paint shade?',
      'How many walls need work?',
    ],
  ),
  ServiceItem(
    title: 'Carpentry fixes',
    subtitle: 'Hinges, drawers, doors, shelves',
    icon: LucideIcons.hammer,
    price: 549,
    duration: '90 min',
    badge: 'Popular',
    color: Color(0xFFFFEDBF),
    questions: [
      'What furniture needs repair?',
      'Is drilling required?',
      'Do you have replacement hardware?',
    ],
  ),
  ServiceItem(
    title: 'Deep inspection',
    subtitle: 'Post-handover checklist and estimate',
    icon: LucideIcons.clipboardCheck,
    price: 999,
    duration: '2.5 hr',
    badge: 'Expert audit',
    color: Color(0xFFF4E7C5),
    questions: [
      'What property type is this?',
      'How many rooms need inspection?',
      'Do you need a written snag report?',
    ],
  ),
  ServiceItem(
    title: 'AC servicing',
    subtitle: 'Cooling checks, cleaning, gas diagnosis',
    icon: LucideIcons.snowflake,
    price: 799,
    duration: '90 min',
    badge: 'Seasonal',
    color: Color(0xFFE4F4F6),
    questions: [
      'What type of AC do you have?',
      'When was it last serviced?',
      'Is cooling currently weak?',
    ],
  ),
  ServiceItem(
    title: 'Appliance repair',
    subtitle: 'Washers, ovens, chimneys, small fixes',
    icon: LucideIcons.refrigerator,
    price: 499,
    duration: '75 min',
    badge: 'Home care',
    color: Color(0xFFEAF3DE),
    questions: [
      'Which appliance needs repair?',
      'What issue are you facing?',
      'Is the appliance under warranty?',
    ],
  ),
];
