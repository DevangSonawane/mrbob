import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/data/services_data.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/models/service_item.dart';
import '../../../../core/theme/app_colors.dart';

/// Blinkit-style home:
/// - Solid gold header (Blinkit's yellow) that COLLAPSES on scroll.
/// - White search card that STAYS PINNED below the status bar with rounded
///   bottom corners, exactly like Blinkit's sticky search bar.
/// - White body tucked close under the search, clean yellow -> white curve.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onBooked});

  static const _allCategoriesRouteName = '/home/service-categories';

  final ValueChanged<Booking> onBooked;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final scale = (width / 430).clamp(0.78, 0.92);
    final popularHeight = 254.0 * scale;

    return Scaffold(
      backgroundColor: AppColors.brandGold,
      // SafeArea keeps the scroll viewport below the status bar / notch /
      // dynamic island on all Android + iPhones, so content never slides
      // into the notification area. Gold scaffold = gold status-bar gutter,
      // dark icons so they stay visible on the gold.
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: AppColors.brandGold,
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          left: false,
          right: false,
          child: Container(
            color: Colors.white,
            child: CustomScrollView(
              // Platform default: clamping on Android, bouncing on iOS,
              // so overscroll feels native on every phone.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ---- 1. Extended Blinkit header: location row scrolls
                // away and hides (like Blinkit), search below sticks ----
                SliverPersistentHeader(
                  pinned: false,
                  delegate: _LocationBarDelegate(scale: scale),
                ),

                // ---- 2. Sticky Blinkit search (pins under location bar,
                // promo + content scroll beneath it) ----
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySearchDelegate(scale: scale),
                ),

                // ---- 3. Body (scrolls under the sticky search) ----
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Blinkit-style promo banner: scrolls away like
                      // Blinkit's banners below the search bar.
                      _PromoBanner(scale: scale),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          18 * scale,
                          14 * scale,
                          18 * scale,
                          10 * scale,
                        ),
                        child: _SectionHeader(
                          title: 'Service Categories',
                          onViewAll: () => _openAllCategories(context),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18 * scale),
                        child: GridView.builder(
                          itemCount: services.take(8).length,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 10 * scale,
                                crossAxisSpacing: 10 * scale,
                                childAspectRatio: 1,
                              ),
                          itemBuilder: (context, index) {
                            final service = services[index];
                            return _CategoryTile(
                              service: service,
                              scale: scale,
                              onTap: () => _openService(context, service),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          18 * scale,
                          22 * scale,
                          18 * scale,
                          10 * scale,
                        ),
                        child: _SectionHeader(
                          title: 'Popular Services',
                          onViewAll: () =>
                              _openService(context, services.first),
                        ),
                      ),
                      SizedBox(
                        height: popularHeight,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 18 * scale),
                          itemCount: services.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(width: 12 * scale),
                          itemBuilder: (context, index) {
                            final service = services[index];
                            return _PopularServiceCard(
                              service: service,
                              scale: scale,
                              onTap: () => _openService(context, service),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          18 * scale,
                          22 * scale,
                          18 * scale,
                          108 + bottomInset,
                        ),
                        child: GridView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12 * scale,
                                crossAxisSpacing: 12 * scale,
                                childAspectRatio: 1.65,
                              ),
                          children: [
                            _TrustTile(
                              scale: scale,
                              icon: LucideIcons.shieldCheck,
                              title: 'Verified pros',
                              body: 'Trained teams for every visit.',
                            ),
                            _TrustTile(
                              scale: scale,
                              icon: LucideIcons.receiptIndianRupee,
                              title: 'Clear pricing',
                              body: 'Know the estimate upfront.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openService(BuildContext context, ServiceItem service) async {
    final openedFromAllCategories =
        ModalRoute.of(context)?.settings.name == _allCategoriesRouteName;
    final selectedSlot = await _showSlotPicker(context, service);
    if (!context.mounted || selectedSlot == null) {
      return;
    }

    final prepAction = await _showBookingPrepDialog(context, service);
    if (!context.mounted) {
      return;
    }
    if (prepAction != _BookingPrepAction.continueBooking) {
      if (prepAction == _BookingPrepAction.diy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DIY guide is coming soon.')),
        );
      }
      return;
    }

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _ServiceQuestionnairePage(
          service: service,
          slotLabel: selectedSlot.label,
        ),
      ),
    );
    if (completed == true && openedFromAllCategories && context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<_BookingPrepAction?> _showBookingPrepDialog(
    BuildContext context,
    ServiceItem service,
  ) {
    return showDialog<_BookingPrepAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BookingPrepDialog(service: service),
    );
  }

  Future<void> _openAllCategories(BuildContext context) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: _allCategoriesRouteName),
        builder: (_) =>
            _AllServiceCategoriesPage(onServiceSelected: _openService),
      ),
    );
  }

  Future<_SelectedSlot?> _showSlotPicker(
    BuildContext context,
    ServiceItem service,
  ) {
    final days = _slotDays();
    final timeSlots = List.generate(14, (index) => _formatHour(8 + index));
    var selectedDay = days.first;
    var selectedTime = timeSlots.first;

    return showModalBottomSheet<_SelectedSlot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(18, 14, 18, 16 + bottomInset),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    service.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Day',
                    style: TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: days.map((day) {
                      final selected = selectedDay == day;
                      return ChoiceChip(
                        label: Text(day.title),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: AppColors.brandForest,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: selected
                              ? AppColors.brandForest
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.brandForest,
                          fontWeight: selected
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                        onSelected: (_) =>
                            setSheetState(() => selectedDay = day),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 18),
                  const Text(
                    'Time slots',
                    style: TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: timeSlots.map((time) {
                      final selected = selectedTime == time;
                      return ChoiceChip(
                        label: Text(time),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: AppColors.brandForest,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: selected
                              ? AppColors.brandForest
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.mutedText,
                          fontWeight: FontWeight.w800,
                        ),
                        onSelected: (_) =>
                            setSheetState(() => selectedTime = time),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          _SelectedSlot(selectedDay.title, selectedTime),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandForest,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Continue - ${selectedDay.title}, $selectedTime',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<_SlotDay> _slotDays() {
    final now = DateTime.now();
    return [
      const _SlotDay('Today'),
      const _SlotDay('Tomorrow'),
      _SlotDay(_weekdayLabel(now.add(const Duration(days: 2)))),
    ];
  }

  String _weekdayLabel(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${date.day}/${date.month}';
  }

  String _formatHour(int hour) {
    if (hour == 12) {
      return '12pm';
    }
    if (hour > 12) {
      return '${hour - 12}pm';
    }
    return '${hour}am';
  }
}

class _SlotDay {
  const _SlotDay(this.title);

  final String title;
}

class _SelectedSlot {
  const _SelectedSlot(this.day, this.time);

  final String day;
  final String time;

  String get label => '$day, $time';
}

enum _BookingPrepAction { continueBooking, cancel, diy }

class _BookingPrepDialog extends StatefulWidget {
  const _BookingPrepDialog({required this.service});

  final ServiceItem service;

  @override
  State<_BookingPrepDialog> createState() => _BookingPrepDialogState();
}

class _BookingPrepDialogState extends State<_BookingPrepDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _messages = [
    'Checking nearby verified professionals...',
    'Most home fixes finish within a single visit.',
    'Comparing your slot with live availability...',
    'Tip: keep photos of the issue ready for faster diagnosis.',
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 5200),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            Navigator.pop(context, _BookingPrepAction.continueBooking);
          }
        });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final index = (_controller.value * _messages.length).floor().clamp(
              0,
              _messages.length - 1,
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: widget.service.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.service.icon,
                        color: AppColors.brandForest,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preparing your booking',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.service.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _controller.value,
                    minHeight: 7,
                    backgroundColor: AppColors.border.withValues(alpha: 0.5),
                    color: AppColors.brandForest,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    _messages[index],
                    key: ValueKey(index),
                    style: const TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We are doing a quick availability poll for your selected slot.',
                  style: TextStyle(
                    color: AppColors.mutedText.withValues(alpha: 0.88),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(context, _BookingPrepAction.cancel),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brandForest,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, _BookingPrepAction.diy),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandForest,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('DIY'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ServiceQuestionnairePage extends StatefulWidget {
  const _ServiceQuestionnairePage({
    required this.service,
    required this.slotLabel,
  });

  final ServiceItem service;
  final String slotLabel;

  @override
  State<_ServiceQuestionnairePage> createState() =>
      _ServiceQuestionnairePageState();
}

class _ServiceQuestionnairePageState extends State<_ServiceQuestionnairePage> {
  final answers = <int, String>{};

  @override
  Widget build(BuildContext context) {
    final questions = _questionsFor(widget.service);
    final systemBottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final actionBarBottomPadding = 16 + systemBottomInset;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Service details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandForest,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 92 + actionBarBottomPadding),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.service.color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.service.icon,
                    color: AppColors.brandForest,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.slotLabel,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'A few quick questions',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'This helps the professional arrive prepared.',
            style: TextStyle(color: AppColors.mutedText, height: 1.35),
          ),
          const SizedBox(height: 18),
          ...questions.indexed.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextField(
                minLines: 1,
                maxLines: 3,
                onChanged: (value) => answers[entry.$1] = value,
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.messageSquareText),
                  labelText: entry.$2,
                ),
              ),
            );
          }),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, actionBarBottomPadding),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _returnHome,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandForest,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Skip'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _returnHome,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandForest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _returnHome() {
    Navigator.pop(context, true);
  }

  List<String> _questionsFor(ServiceItem service) {
    return switch (service.title) {
      'Plumbing fixes' => const [
        'Since when has it been leaking?',
        'Where exactly is the leak located?',
        'Is the water supply currently turned off?',
        'Do you have replacement parts available?',
      ],
      'Electrical snags' => const [
        'Which switch, socket, or fixture is affected?',
        'Is there sparking, burning smell, or tripping?',
        'When did you first notice the issue?',
        'Do you need any new parts installed?',
      ],
      'Painting repairs' => const [
        'Which wall or surface needs repair?',
        'Is there seepage, stain, or peeling paint?',
        'Do you know the existing paint shade?',
        'How large is the affected area?',
      ],
      'AC servicing' => const [
        'What type of AC do you have?',
        'Is cooling weak or completely stopped?',
        'When was it last serviced?',
        'Is there water leakage or unusual noise?',
      ],
      'Appliance repair' => const [
        'Which appliance needs repair?',
        'What issue are you facing?',
        'When did the problem start?',
        'Is the appliance under warranty?',
      ],
      'Carpentry fixes' => const [
        'What furniture or fitting needs repair?',
        'Is anything loose, broken, or jammed?',
        'Will drilling or wall mounting be needed?',
        'Do you have replacement hardware?',
      ],
      'Deep inspection' => const [
        'What property type should we inspect?',
        'How many rooms need inspection?',
        'Are there specific concerns to focus on?',
        'Do you need a written snag report?',
      ],
      _ => const [
        'Where is the issue located?',
        'When did you first notice it?',
        'How severe is the damage right now?',
        'Is material or access available on site?',
      ],
    };
  }
}

class _AllServiceCategoriesPage extends StatelessWidget {
  const _AllServiceCategoriesPage({required this.onServiceSelected});

  final Future<void> Function(BuildContext context, ServiceItem service)
  onServiceSelected;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = (width / 430).clamp(0.78, 0.92);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Service Categories'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandForest,
        surfaceTintColor: Colors.transparent,
      ),
      body: GridView.builder(
        padding: EdgeInsets.fromLTRB(
          18 * scale,
          18 * scale,
          18 * scale,
          28 * scale,
        ),
        itemCount: services.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: width > 560 ? 3 : 2,
          mainAxisSpacing: 14 * scale,
          crossAxisSpacing: 14 * scale,
          childAspectRatio: 0.86,
        ),
        itemBuilder: (context, index) {
          final service = services[index];
          return _AllCategoryCard(
            service: service,
            scale: scale,
            onTap: () => onServiceSelected(context, service),
          );
        },
      ),
    );
  }
}

class _AllCategoryCard extends StatelessWidget {
  const _AllCategoryCard({
    required this.service,
    required this.scale,
    required this.onTap,
  });

  final ServiceItem service;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brandGold,
      borderRadius: BorderRadius.circular(16 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16 * scale),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16 * scale,
                offset: Offset(0, 8 * scale),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(12 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 76 * scale,
                  decoration: BoxDecoration(
                    color: service.color,
                    borderRadius: BorderRadius.circular(14 * scale),
                  ),
                  child: Icon(
                    service.icon,
                    color: AppColors.brandForest,
                    size: 38 * scale,
                  ),
                ),
                SizedBox(height: 12 * scale),
                Text(
                  service.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6 * scale),
                Expanded(
                  child: Text(
                    service.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11.5 * scale,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Rs ${service.price}',
                      style: TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      LucideIcons.chevronRight,
                      color: AppColors.brandForest,
                      size: 20 * scale,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pinned Blinkit search bar delegate.
/// Full-bleed EXTENDED gold bar (edge to edge, exactly like Blinkit's
/// yellow header) so scrolling content slides under a solid bar instead
/// of a floating slab. The white search CARD inside stays rounded.
/// Fixed height (always fits the 52px search card + padding, so the yellow
/// can never clip/cover the search). SafeArea above handles the status
/// bar, so no notch overlap on any phone.
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  _StickySearchDelegate({required this.scale});

  final double scale;

  // 8 top + 52 search + 12 bottom = 72. Fixed (not scaled) so the search
  // card can never overflow and get covered, on any screen width.
  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.brandGold,
      padding: EdgeInsets.fromLTRB(16 * scale, 8, 16 * scale, 12),
      child: const _SearchBar(),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchDelegate oldDelegate) =>
      oldDelegate.scale != scale;
}

/// Rounded glassmorphic search bar: a frosted-glass pill floating over the
/// gold header, speaking the same liquid-glass language as the bottom nav.
/// Real backdrop blur + white gradient + hairline border + soft shadow,
/// with a light band endlessly flowing left to right across the glass.
class _SearchBar extends StatefulWidget {
  const _SearchBar();

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow;

  @override
  void initState() {
    super.initState();
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Real liquid-glass lens (liquid_glass_easy): refracts the gold
    // header live with an optical rim. Shimmer + content ride inside
    // as the lens child, clipped to the pill.
    return SizedBox(
      height: 52,
      child: LiquidGlassLens(
        style: LiquidGlassStyle(
          shape: const LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: 26,
          ),
          appearance: LiquidGlassAppearance(
            color: Colors.white.withValues(alpha: 0.6),
            blur: const LiquidGlassBlur(sigmaX: 10, sigmaY: 10),
          ),
          refraction: const LiquidGlassRefraction(
            distortion: 0.12,
            distortionWidth: 30,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Flowing shine band, behind the content.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _flow,
                builder: (_, _) => CustomPaint(
                  painter: _SearchShimmerPainter(progress: _flow.value),
                ),
              ),
            ),
            // Content on top of the shine.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 6, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.brandForest,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Search for a service...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 22,
                    color: AppColors.brandForest.withValues(alpha: 0.14),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.brandForest,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandForest.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diagonal light band travelling left to right across the search pill.
/// Peak glows mid-band and fades to clear at both edges.
class _SearchShimmerPainter extends CustomPainter {
  const _SearchShimmerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final band = size.width * 0.32;
    const slant = 22.0;
    final x = -band - slant + progress * (size.width + (band + slant) * 2);
    final path = Path()
      ..moveTo(x, 0)
      ..lineTo(x + band, 0)
      ..lineTo(x + band - slant, size.height)
      ..lineTo(x - slant, size.height)
      ..close();
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(x - slant, 0, band + slant, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SearchShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Pinned location bar delegate: fixed 64px gold strip, always on top.
class _LocationBarDelegate extends SliverPersistentHeaderDelegate {
  _LocationBarDelegate({required this.scale});

  final double scale;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.brandGold,
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 10),
      child: _LocationBar(scale: scale),
    );
  }

  @override
  bool shouldRebuild(covariant _LocationBarDelegate oldDelegate) =>
      oldDelegate.scale != scale;
}

/// Blinkit-style location row: pin + address left, actions right.
class _LocationBar extends StatelessWidget {
  const _LocationBar({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.brandGold,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38 * scale,
            height: 38 * scale,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.mapPin,
              color: AppColors.brandForest,
              size: 20 * scale,
            ),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR LOCATION',
                  style: TextStyle(
                    color: AppColors.brandForest.withValues(alpha: 0.62),
                    fontSize: 10.5 * scale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'San Antinoe, Tx',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 17 * scale,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronDown,
                      color: AppColors.brandForest.withValues(alpha: 0.7),
                      size: 22 * scale,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _CircleAction(scale: scale, icon: LucideIcons.bell, hasDot: true),
          SizedBox(width: 10 * scale),
          Container(
            width: 44 * scale,
            height: 44 * scale,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              LucideIcons.user,
              color: AppColors.brandForest,
              size: 24 * scale,
            ),
          ),
        ],
      ),
    );
  }
}

/// Blinkit-style promo banner: gold card that scrolls away below the
/// sticky search, with dot texture, headline, CTA + illustration.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14 * scale,
        6 * scale,
        14 * scale,
        16 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandGold,
        // Square top corners plug flush into the gold search header above;
        // only the bottom stays rounded. No shadow/border so the gold
        // flows seamless with zero gap.
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20 * scale),
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _DotTexture()),
          // ---- Headline + premium illustration card ----
          SizedBox(
            height: 158 * scale,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR SOLUTION,\nONE TAP AWAY!',
                          style: TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 21 * scale,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Text(
                          'Seamless, Fast & Reliable\nServices at Your Fingertips',
                          style: TextStyle(
                            color: AppColors.brandForest.withValues(
                              alpha: 0.72,
                            ),
                            fontSize: 11.5 * scale,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 13 * scale),
                        SizedBox(
                          height: 38 * scale,
                          child: FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandForest,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11 * scale),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20 * scale,
                              ),
                            ),
                            child: Text(
                              'Explore',
                              style: TextStyle(
                                fontSize: 13.5 * scale,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10 * scale),
                _HeroCard(scale: scale),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.scale,
    required this.icon,
    this.hasDot = false,
  });

  final double scale;
  final IconData icon;
  final bool hasDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44 * scale,
      height: 44 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: AppColors.brandForest, size: 21 * scale),
          if (hasDot)
            Positioned(
              right: 11 * scale,
              top: 11 * scale,
              child: Container(
                width: 8 * scale,
                height: 8 * scale,
                decoration: BoxDecoration(
                  color: AppColors.brandForest,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Premium white illustration card replacing the cheap painter workers.
/// Clean, Blinkit-like promo tile with icon + rating + verified chips.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148 * scale,
      height: 150 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _CardDotsPainter())),
          Padding(
            padding: EdgeInsets.all(12 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52 * scale,
                  height: 52 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.brandForest,
                    borderRadius: BorderRadius.circular(15 * scale),
                  ),
                  child: Icon(
                    LucideIcons.hammer,
                    color: AppColors.brandGold,
                    size: 26 * scale,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * scale,
                    vertical: 5 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.star,
                        color: AppColors.brandForest,
                        size: 13 * scale,
                      ),
                      SizedBox(width: 3 * scale),
                      Text(
                        '4.9 · Verified',
                        style: TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 10.5 * scale,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6 * scale),
                Text(
                  '60-min doorstep fix',
                  style: TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 11.5 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotTexture extends StatelessWidget {
  const _DotTexture();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotTexturePainter());
  }
}

class _DotTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brandForest.withValues(alpha: 0.06);
    const gap = 18.0;
    const r = 1.4;
    for (var y = gap / 2; y < size.height; y += gap) {
      for (var x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brandForest.withValues(alpha: 0.07);
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.12),
      size.width * 0.30,
      paint,
    );
    final ring = Paint()
      ..color = AppColors.brandGold.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.12),
      size.width * 0.22,
      ring,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandForest,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: Size.zero,
          ),
          iconAlignment: IconAlignment.end,
          label: const Text(
            'View all',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          icon: const Icon(LucideIcons.chevronRight, size: 17),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.service,
    required this.scale,
    required this.onTap,
  });

  final ServiceItem service;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Package lite glass (no shader): docs-faithful for list items that
    // scroll with content — frost, tint and lit rim, cheap and safe.
    return LiquidGlassLens(
      style: LiquidGlassStyle(
        shape: LiquidGlassShape.roundedRectangle(
          cornerRadius: 18 * scale,
        ),
        appearance: LiquidGlassAppearance(
          color: Colors.white.withValues(alpha: 0.55),
          shadow: LiquidGlassShadow(
            blur: 8 * scale,
            opacity: 0.14,
          ),
        ),
        liteGlass: LiquidGlassLitePickup.backdrop,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18 * scale),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 6 * scale,
              vertical: 9 * scale,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  service.icon,
                  color: AppColors.brandForest,
                  size: 30 * scale,
                ),
                SizedBox(height: 8 * scale),
                Text(
                  _categoryTitle(service.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 11.8 * scale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _categoryTitle(String title) {
    return switch (title) {
      'Civil touch-ups' => 'Repairs',
      'Plumbing fixes' => 'Plumbing',
      'Electrical snags' => 'Electrical',
      'Painting repairs' => 'Painting',
      'Carpentry fixes' => 'Carpentry',
      'Deep inspection' => 'Inspection',
      'AC servicing' => 'AC Service',
      'Appliance repair' => 'Appliance',
      _ => title,
    };
  }
}

class _PopularServiceCard extends StatelessWidget {
  const _PopularServiceCard({
    required this.service,
    required this.scale,
    required this.onTap,
  });

  final ServiceItem service;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final originalPrice = service.price + 200;

    return SizedBox(
      width: 202 * scale,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16 * scale),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18 * scale,
                  offset: Offset(0, 8 * scale),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 96 * scale,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16 * scale),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: service.color),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ServicePatternPainter(
                                color: AppColors.brandForest,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10 * scale,
                            bottom: 8 * scale,
                            child: Icon(
                              service.icon,
                              color: AppColors.brandForest,
                              size: 72 * scale,
                            ),
                          ),
                          Positioned(
                            left: 10 * scale,
                            top: 10 * scale,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8 * scale,
                                vertical: 4 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.90),
                                borderRadius: BorderRadius.circular(8 * scale),
                              ),
                              child: Text(
                                service.badge,
                                style: TextStyle(
                                  color: AppColors.brandForest,
                                  fontSize: 9.8 * scale,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      12 * scale,
                      10 * scale,
                      12 * scale,
                      12 * scale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15.5 * scale,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 7 * scale),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.star,
                              color: AppColors.brandGold,
                              size: 15 * scale,
                            ),
                            SizedBox(width: 3 * scale),
                            Text(
                              '4.8',
                              style: TextStyle(
                                color: AppColors.brandForest,
                                fontSize: 11.5 * scale,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 4 * scale),
                            Text(
                              '(2.3K)',
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              LucideIcons.clock,
                              color: AppColors.mutedText,
                              size: 14 * scale,
                            ),
                            SizedBox(width: 3 * scale),
                            Text(
                              service.duration,
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 9 * scale),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8 * scale,
                            vertical: 5 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandForest.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(10 * scale),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.shieldCheck,
                                color: AppColors.brandForest,
                                size: 13 * scale,
                              ),
                              SizedBox(width: 4 * scale),
                              Text(
                                'Verified Professional',
                                style: TextStyle(
                                  color: AppColors.brandForest,
                                  fontSize: 10.5 * scale,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Rs${service.price}',
                              style: TextStyle(
                                color: AppColors.brandForest,
                                fontSize: 15 * scale,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 6 * scale),
                            Text(
                              'Rs$originalPrice',
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 11.5 * scale,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 34 * scale,
                              child: FilledButton(
                                onPressed: onTap,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.brandForest,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 11 * scale,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      9 * scale,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Book Now',
                                  style: TextStyle(
                                    fontSize: 11.5 * scale,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServicePatternPainter extends CustomPainter {
  const _ServicePatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.16 + i * size.width * 0.24, size.height * 0.28),
        size.width * 0.22,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrustTile extends StatelessWidget {
  const _TrustTile({
    required this.scale,
    required this.icon,
    required this.title,
    required this.body,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brandForest, size: 24 * scale),
          SizedBox(height: 10 * scale),
          Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 12 * scale,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
