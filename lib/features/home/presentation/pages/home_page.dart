import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/data/services_data.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/models/service_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shell/presentation/pages/main_shell.dart';

/// Blinkit-style home:
/// - Solid gold header (Blinkit's yellow) that COLLAPSES on scroll.
/// - White search card that STAYS PINNED below the status bar with rounded
///   bottom corners, exactly like Blinkit's sticky search bar.
/// - White body tucked close under the search, clean yellow -> white curve.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onBooked});

  final ValueChanged<Booking> onBooked;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _allCategoriesRouteName = '/home/service-categories';

  /// View filter for the service collections below. Null shows everything;
  /// the booking-mode [GlassMenu] in [_SearchBar] sets and clears it.
  BookingMode? _modeFilter;

  /// Services visible under the current [_modeFilter].
  List<ServiceItem> get _visibleServices => switch (_modeFilter) {
    BookingMode.instant => services.where((s) => s.supportsInstant).toList(),
    BookingMode.scheduled => services.where((s) => !s.supportsInstant).toList(),
    null => services,
  };

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
                  delegate: _StickySearchDelegate(
                    scale: scale,
                    modeFilter: _modeFilter,
                    onModeFilterChanged: (mode) =>
                        setState(() => _modeFilter = mode),
                  ),
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
                          itemCount: _visibleServices.take(8).length,
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
                            final service = _visibleServices[index];
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
                              _openService(context, _visibleServices.first),
                        ),
                      ),
                      SizedBox(
                        height: popularHeight,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 18 * scale),
                          itemCount: _visibleServices.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(width: 12 * scale),
                          itemBuilder: (context, index) {
                            final service = _visibleServices[index];
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
    final selectedSlot = await _showSlotPicker(context, service);
    if (!context.mounted || selectedSlot == null) {
      return;
    }

    final prep = await _showBookingPrepDialog(context, service);
    if (!context.mounted) {
      return;
    }
    if (prep == null || prep.action != _BookingPrepAction.continueBooking) {
      return;
    }

    // Dummy payment step: Pay now records the booking and drops the user
    // back on the home (first) route.
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _PaymentPage(
          service: service,
          slotLabel: selectedSlot.label,
          description: prep.description,
          onPaid: widget.onBooked,
        ),
      ),
    );
  }

  Future<_BookingPrepData?> _showBookingPrepDialog(
    BuildContext context,
    ServiceItem service,
  ) {
    // Same bottom dialog for the whole describe flow — not a new centered
    // dialog. The sheet itself expands in place when the editor opens.
    return showModalBottomSheet<_BookingPrepData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                      color: AppColors.brandForest,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Day',
                    style: TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Fluid glass day selector (indicator_parity_demo.dart pattern:
                  // GlassSegmentedControl's refractive indicator morphs between
                  // segments with jelly physics — the liquid selection pill.
                  // Standalone on the opaque sheet, so it owns its glass layer
                  // (SKILL.md Rule 2: glass is never nested in glass).
                  GlassSegmentedControl(
                    segments: days
                        .map((day) => GlassSegment(label: day.title))
                        .toList(),
                    selectedIndex: days.indexWhere(
                      (day) => day.title == selectedDay.title,
                    ),
                    onSegmentSelected: (index) =>
                        setSheetState(() => selectedDay = days[index]),
                    useOwnLayer: true,
                    // Opaque-sheet readability: a tinted track plus a solid
                    // forest indicator pill, so the selection reads even
                    // though clear glass has nothing to refract on white.
                    // The refractive lens still morphs over the pill.
                    backgroundColor: AppColors.brandForest.withValues(
                      alpha: 0.08,
                    ),
                    indicatorColor: AppColors.brandForest,
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    unselectedTextStyle: TextStyle(
                      color: AppColors.brandForest.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Divider(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: 18),
                  const Text(
                    'Time slots',
                    style: TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Scrollable fluid glass time selector
                  // (glass_tab_bar_scrollable_demo.dart
                  // GlassSegmentedControl.scrollable pattern): 14 slots never
                  // fit a fixed track, so natural-width segments scroll and
                  // the refractive indicator glides to the tapped slot.
                  GlassSegmentedControl.scrollable(
                    segments: timeSlots
                        .map((time) => GlassSegment(label: time))
                        .toList(),
                    selectedIndex: timeSlots.indexOf(selectedTime),
                    onSegmentSelected: (index) =>
                        setSheetState(() => selectedTime = timeSlots[index]),
                    useOwnLayer: true,
                    // Same opaque-sheet treatment as the day selector: tinted
                    // track + solid forest indicator pill with white text.
                    backgroundColor: AppColors.brandForest.withValues(
                      alpha: 0.08,
                    ),
                    indicatorColor: AppColors.brandForest,
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    unselectedTextStyle: TextStyle(
                      color: AppColors.mutedText.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Liquid glass continue action
                  // (quality_comparison_demo.dart GlassButton pattern):
                  // refractive pill with squeeze & stretch physics instead of
                  // the flat FilledButton. GlassButton uses onTap (not
                  // onPressed); the .custom constructor allows a full-width
                  // text child. Own layer — sibling of the selectors above,
                  // never nested inside another glass surface.
                  GlassButton.custom(
                    width: double.infinity,
                    height: 52,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 14),
                    useOwnLayer: true,
                    // Forest-tinted glass so the CTA reads as a solid action
                    // on the white sheet (glassColor opacity = tint
                    // intensity); white label stays legible over the tint.
                    settings: const LiquidGlassSettings(
                      glassColor: AppColors.brandForest,
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        _SelectedSlot(selectedDay.title, selectedTime),
                      );
                    },
                    child: Center(
                      child: Text(
                        'Continue - ${selectedDay.title}, $selectedTime',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.1,
                        ),
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

enum _BookingPrepAction { continueBooking, cancel }

/// Result of the problem-description step: what to do next, plus the typed
/// or dictated description (empty when the user continues without typing).
class _BookingPrepData {
  const _BookingPrepData(this.action, this.description);

  final _BookingPrepAction action;
  final String description;
}

enum _PrepMode { options, listening, describe }

class _BookingPrepDialog extends StatefulWidget {
  const _BookingPrepDialog({required this.service});

  final ServiceItem service;

  @override
  State<_BookingPrepDialog> createState() => _BookingPrepDialogState();
}

class _BookingPrepDialogState extends State<_BookingPrepDialog>
    with SingleTickerProviderStateMixin {
  _PrepMode _mode = _PrepMode.options;

  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speech = SpeechToText();

  late final AnimationController _pulseController;

  bool _startingListen = false;
  String _liveTranscript = '';
  String? _micError;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  /// Turns the mic on and streams speech recognition. Partial results show
  /// live; the final transcript expands the dialog into the full editor.
  Future<void> _startListening() async {
    if (_startingListen) {
      return;
    }
    setState(() {
      _startingListen = true;
      _micError = null;
    });
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          // Engine idled on its own (e.g. pause timeout): fold whatever was
          // heard into the editor instead of hanging on the listening view.
          if ((status == 'done' || status == 'notListening') &&
              mounted &&
              _mode == _PrepMode.listening) {
            _finishListening(auto: true);
          }
        },
        onError: (error) {
          if (!mounted) {
            return;
          }
          _speech.stop();
          _pulseController.stop();
          setState(() {
            _startingListen = false;
            _mode = _PrepMode.options;
            _micError =
                'Microphone unavailable (${error.errorMsg}). '
                'Please type your problem instead.';
          });
        },
      );
      if (!available) {
        if (!mounted) {
          return;
        }
        setState(() {
          _startingListen = false;
          _mode = _PrepMode.options;
          _micError =
              'Speech recognition is not available on this device. '
              'Please type your problem instead.';
        });
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _mode = _PrepMode.listening;
        _liveTranscript = '';
        _startingListen = false;
      });
      _pulseController.repeat(reverse: true);
      await _speech.listen(
        onResult: (result) {
          if (!mounted) {
            return;
          }
          setState(() => _liveTranscript = result.recognizedWords);
          if (result.finalResult) {
            _finishListening(auto: true);
          }
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      await _speech.stop();
      _pulseController.stop();
      setState(() {
        _startingListen = false;
        _mode = _PrepMode.options;
        _micError =
            'Could not start the microphone. Please type your problem instead.';
      });
    }
  }

  /// Stops the recognizer and expands the dialog to the fullest editor with
  /// the transcript loaded for review.
  Future<void> _finishListening({required bool auto}) async {
    await _speech.stop();
    _pulseController.stop();
    if (!mounted) {
      return;
    }
    final heard = _liveTranscript.trim();
    if (heard.isNotEmpty) {
      _textController.text = heard;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
    setState(() {
      if (heard.isNotEmpty || !auto) {
        _mode = _PrepMode.describe;
        _micError = null;
      } else {
        // Engine stopped on its own without hearing anything.
        _mode = _PrepMode.options;
        _micError = 'Did not catch that — please try again or type it.';
      }
    });
  }

  void _close(_BookingPrepAction action, [String description = '']) {
    _speech.stop();
    _pulseController.stop();
    Navigator.pop(context, _BookingPrepData(action, description));
  }

  @override
  Widget build(BuildContext context) {
    // One bottom dialog for the whole flow: it morphs from the compact
    // options row into the near-full-height editor (AnimatedSize) instead
    // of opening anything new.
    final expanded = _mode == _PrepMode.describe;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: expanded ? _buildDescribe() : _buildCompact(),
      ),
    );
  }

  Widget _buildGrabber() {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildHeader({required String title, required String subtitle}) {
    return Row(
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
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _close(_BookingPrepAction.cancel),
          icon: const Icon(LucideIcons.x, color: AppColors.mutedText, size: 20),
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildCompact() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 14, 18, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGrabber(),
          const SizedBox(height: 14),
          _buildHeader(
            title: _mode == _PrepMode.listening
                ? 'Listening…'
                : 'State your problem',
            subtitle: widget.service.title,
          ),
          const SizedBox(height: 16),
          if (_mode == _PrepMode.listening)
            _buildListening()
          else
            _buildOptions(),
          if (_micError != null && _mode == _PrepMode.options) ...[
            const SizedBox(height: 12),
            Text(
              _micError!,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Compact section: "Write here" option on the left, a divider
  /// in the middle, and the speaker (mic) option on the right.
  Widget _buildOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _mode = _PrepMode.describe),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.messageSquareText,
                      color: AppColors.brandForest,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Write here',
                        style: TextStyle(
                          color: AppColors.brandForest,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      color: AppColors.mutedText,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 48, color: AppColors.borderSubtle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildMicButton(),
          ),
        ],
      ),
    );
  }

  /// Circular mic affordance: solid forest so it reads on the white dialog,
  /// red + pulsing while the mic is on.
  Widget _buildMicButton() {
    final listening = _mode == _PrepMode.listening;
    final button = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: listening ? Colors.red.shade600 : AppColors.brandForest,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (listening ? Colors.red.shade600 : AppColors.brandForest)
                .withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _startingListen
          ? const Padding(
              padding: EdgeInsets.all(13),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : const Icon(LucideIcons.mic, color: Colors.white, size: 22),
    );
    final tappable = GestureDetector(
      onTap: listening || _startingListen ? null : _startListening,
      child: button,
    );
    if (!listening) {
      return tappable;
    }
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, child) => Transform.scale(
        scale: 1 + _pulseController.value * 0.1,
        child: child,
      ),
      child: tappable,
    );
  }

  Widget _buildListening() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        _buildMicButton(),
        const SizedBox(height: 12),
        const Text(
          'Speak now — transcribing as you talk…',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Text(
            _liveTranscript.isEmpty ? '…' : _liveTranscript,
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _finishListening(auto: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandForest,
              side: const BorderSide(color: AppColors.borderSubtle),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Stop & review',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  /// Expanded fullest state of the same bottom sheet: big text box plus
  /// Back / Continue actions. Shrinks above the keyboard so Continue never
  /// hides behind it. Scroll-based (fixed-height text box, no flex) so no
  /// transient height — sheet growth or keyboard animation — can overflow.
  Widget _buildDescribe() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = (screenHeight * 0.88).clamp(420.0, screenHeight * 0.92);
    // Fixed chrome around the text box: grabber + gaps + header + gaps +
    // buttons + outer padding. Whatever is left goes to the text box
    // (floored so it stays usable on short screens — the scroll view absorbs
    // the rest instead of overflowing). Do not subtract keyboard height here:
    // the modal route already lifts above the keyboard, and double-counting
    // the inset is what made the dialog collapse when typing.
    const chromeHeight = 14.0 + 4.0 + 14.0 + 48.0 + 14.0 + 14.0 + 48.0;
    final boxHeight = (sheetHeight - chromeHeight - 14.0 - 16.0 - bottomInset)
        .clamp(140.0, double.infinity)
        .toDouble();
    return SizedBox(
      height: sheetHeight,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, 14, 18, 16 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGrabber(),
            const SizedBox(height: 14),
            _buildHeader(
              title: 'State your problem',
              subtitle: widget.service.title,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: boxHeight,
              child: TextField(
                controller: _textController,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Write here…',
                  hintStyle: TextStyle(
                    color: AppColors.mutedText.withValues(alpha: 0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.brandForest,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _mode = _PrepMode.options),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandForest,
                      side: const BorderSide(color: AppColors.borderSubtle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassButton.custom(
                    width: double.infinity,
                    height: 48,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 12),
                    useOwnLayer: true,
                    settings: const LiquidGlassSettings(
                      glassColor: AppColors.brandForest,
                    ),
                    onTap: () => _close(
                      _BookingPrepAction.continueBooking,
                      _textController.text.trim(),
                    ),
                    child: const Center(
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dummy payment screen: order summary, fake method picker, and a Pay now
/// action that records the booking and returns to the home (first) route.
class _PaymentPage extends StatefulWidget {
  const _PaymentPage({
    required this.service,
    required this.slotLabel,
    required this.description,
    required this.onPaid,
  });

  final ServiceItem service;
  final String slotLabel;
  final String description;
  final ValueChanged<Booking> onPaid;

  @override
  State<_PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<_PaymentPage> {
  static const _methods = [
    (label: 'UPI', icon: LucideIcons.smartphone),
    (label: 'Card', icon: LucideIcons.creditCard),
    (label: 'Cash after service', icon: LucideIcons.banknote),
  ];

  int _methodIndex = 0;
  bool _paying = false;

  static const _platformFee = 29;

  int get _total => widget.service.price + _platformFee;

  Future<void> _payNow() async {
    if (_paying) {
      return;
    }
    setState(() => _paying = true);
    // Fake gateway delay.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) {
      return;
    }
    widget.onPaid(
      Booking(
        service: widget.service,
        mode: BookingMode.scheduled.label,
        slot: widget.slotLabel,
        payment: _methods[_methodIndex].label,
        total: _total,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Payment successful — your professional will be assigned shortly.',
        ),
      ),
    );
    // Back to the existing home shell. If the shell route name is not present
    // in an older stack, reset to a fresh shell instead of falling through to
    // Login/onboarding.
    var foundHome = false;
    Navigator.of(context).popUntil((route) {
      foundHome = route.settings.name == MainShell.routeName;
      return foundHome;
    });
    if (!foundHome && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          settings: const RouteSettings(name: MainShell.routeName),
          builder: (_) => const MainShell(),
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandForest,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 110 + bottomInset),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
              border: Border.all(color: AppColors.borderSubtle),
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
                          color: AppColors.brandForest,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.slotLabel,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      if (widget.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Bill details',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                _billRow('Service charge', 'Rs ${widget.service.price}'),
                const SizedBox(height: 10),
                _billRow('Platform fee', 'Rs $_platformFee'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.borderSubtle),
                ),
                _billRow('Total', 'Rs $_total', isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Pay with',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          ..._methods.indexed.map((entry) {
            final selected = entry.$1 == _methodIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _paying
                    ? null
                    : () => setState(() => _methodIndex = entry.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppColors.brandForest
                          : AppColors.borderSubtle,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        entry.$2.icon,
                        color: AppColors.brandForest,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.$2.label,
                          style: const TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        selected ? LucideIcons.circleCheck : LucideIcons.circle,
                        color: selected
                            ? AppColors.brandForest
                            : AppColors.mutedText,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          const Text(
            'Demo checkout — no real money moves.',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: GlassButton.custom(
          width: double.infinity,
          height: 52,
          shape: const LiquidRoundedSuperellipse(borderRadius: 14),
          useOwnLayer: true,
          settings: const LiquidGlassSettings(
            glassColor: AppColors.brandForest,
          ),
          enabled: !_paying,
          onTap: _payNow,
          child: Center(
            child: _paying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Pay now · Rs $_total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _billRow(String label, String value, {bool isTotal = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.brandForest : AppColors.mutedText,
              fontSize: isTotal ? 15 : 13.5,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.brandForest,
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
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
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
              border: Border.all(color: AppColors.borderSubtle),
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
                          color: AppColors.brandForest,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.slotLabel,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
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
              color: AppColors.brandForest,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'This helps the professional arrive prepared.',
            style: TextStyle(
              color: AppColors.mutedText,
              height: 1.4,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
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
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _returnHome,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandForest,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(18 * scale),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18 * scale),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18 * scale),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18 * scale,
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
                    size: 36 * scale,
                  ),
                ),
                SizedBox(height: 12 * scale),
                Text(
                  service.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 14.5 * scale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 5 * scale),
                Expanded(
                  child: Text(
                    service.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11.5 * scale,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 8 * scale),
                Row(
                  children: [
                    Text(
                      'Rs ${service.price}',
                      style: TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      LucideIcons.chevronRight,
                      color: AppColors.mutedText,
                      size: 18 * scale,
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
  _StickySearchDelegate({
    required this.scale,
    required this.modeFilter,
    required this.onModeFilterChanged,
  });

  final double scale;
  final BookingMode? modeFilter;
  final ValueChanged<BookingMode?> onModeFilterChanged;

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
      // The mode menu owns view filtering; the typed query is still a
      // no-op for a future grid filter.
      child: _SearchBar(
        onChanged: (_) {},
        modeFilter: modeFilter,
        onModeFilterChanged: onModeFilterChanged,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchDelegate oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.modeFilter != modeFilter ||
      oldDelegate.onModeFilterChanged != onModeFilterChanged;
}

/// Sticky search row: a real [GlassSearchBar] pill plus the booking-mode
/// filter trigger. Typed input surfaces via [onChanged] for a future grid
/// filter; the mode menu drives [_HomePageState._modeFilter].
class _SearchBar extends StatefulWidget {
  const _SearchBar({this.onChanged, this.modeFilter, this.onModeFilterChanged});

  final ValueChanged<String>? onChanged;
  final BookingMode? modeFilter;
  final ValueChanged<BookingMode?>? onModeFilterChanged;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _controller;

  /// Imperative handle for the mode menu: item taps update the filter and
  /// then close the menu explicitly — tapping an item does not dismiss it
  /// on its own (only the outside-tap barrier does).
  final GlassMenuController _menuController = GlassMenuController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectMode(BookingMode? mode) {
    widget.onModeFilterChanged?.call(mode);
    _menuController.close();
  }

  /// Opens the mode menu deterministically on every tap.
  ///
  /// The trigger deliberately ignores the [GlassMenu] toggle callback: a tap
  /// that lands while a close spring is still settling would re-toggle the
  /// menu closed again (a swallowed tap — the "have to tap twice" bug),
  /// while [GlassMenuController.open] reverses a mid-close spring toward open
  /// for any timing. The trigger is only tappable while the menu is closed
  /// (the menu blocks its own trigger while open), so an unconditional open
  /// is safe. The search field is unfocused first so an open keyboard can't
  /// cover the freshly opened menu.
  void _openFilterMenu() {
    FocusScope.of(context).unfocus();
    _menuController.open();
  }

  @override
  Widget build(BuildContext context) {
    // Real GlassSearchBar (standalone pattern from nav_bar_patterns_demo.dart:
    // placeholder + useOwnLayer + onChanged). It owns its glass layer, so the
    // filter action stays a plain sibling — glass is never nested in glass
    // (SKILL.md Rule 2). Fixed 52px height preserves the sticky delegate's
    // 72px extent; the typed query still surfaces via [onChanged].
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: GlassSearchBar(
              controller: _controller,
              placeholder: 'Search for a service...',
              useOwnLayer: true,
              height: 52,
              onChanged: (value) => widget.onChanged?.call(value),
              searchIconColor: AppColors.brandForest.withValues(alpha: 0.88),
              textStyle: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
              placeholderStyle: TextStyle(
                color: AppColors.brandForest.withValues(alpha: 0.58),
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Booking-mode filter (glass_menu_demo.dart raw-GlassMenu pattern:
          // the trigger opens the menu via the controller (not the toggle
          // callback) so a tap morphs the button into the menu via the
          // Liquid Morph Engine on the first tap — no wrapper animation.
          // Top-right placement: the trigger sits at the header's trailing
          // edge and the menu drops below it.
          GlassMenu(
            controller: _menuController,
            menuAlignment: GlassMenuAlignment.topRight,
            autoAdjustToScreen: true,
            items: [
              // Header caption in the same ink as the item titles (instead
              // of the muted secondary caption) so the menu reads as one
              // list. Resolved exactly like GlassMenuItem does.
              Builder(
                builder: (context) {
                  final foreground =
                      CupertinoTheme.of(context).textTheme.textStyle.color ??
                      CupertinoColors.label;
                  return GlassMenuLabel(
                    title: 'Booking mode',
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  );
                },
              ),
              GlassMenuItem(
                title: BookingMode.instant.label,
                icon: const Icon(Icons.bolt),
                isSelected: widget.modeFilter == BookingMode.instant,
                trailing: widget.modeFilter == BookingMode.instant
                    ? const Icon(Icons.check, size: 18)
                    : null,
                onTap: () => _selectMode(BookingMode.instant),
              ),
              GlassMenuItem(
                title: BookingMode.scheduled.label,
                icon: const Icon(Icons.schedule),
                isSelected: widget.modeFilter == BookingMode.scheduled,
                trailing: widget.modeFilter == BookingMode.scheduled
                    ? const Icon(Icons.check, size: 18)
                    : null,
                onTap: () => _selectMode(BookingMode.scheduled),
              ),
              const GlassMenuDivider(),
              GlassMenuItem(
                title: 'Show all',
                icon: const Icon(Icons.clear_all),
                isSelected: widget.modeFilter == null,
                trailing: widget.modeFilter == null
                    ? const Icon(Icons.check, size: 18)
                    : null,
                onTap: () => _selectMode(null),
              ),
            ],
            triggerBuilder: (context, _) => GlassIconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: AppColors.brandForest,
              ),
              onPressed: _openFilterMenu,
              useOwnLayer: true,
              size: 40,
              iconSize: 19,
              semanticLabel: 'Filter by booking mode',
            ),
          ),
        ],
      ),
    );
  }
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
                    color: AppColors.brandForest.withValues(alpha: 0.58),
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
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
                          fontSize: 16.5 * scale,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.1,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 18.5 * scale,
                            height: 1.06,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Text(
                          'Seamless, Fast & Reliable\nServices at Your Fingertips',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.brandForest.withValues(
                              alpha: 0.68,
                            ),
                            fontSize: 10.5 * scale,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.05,
                          ),
                        ),
                        const Spacer(),
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
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
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
          Padding(
            padding: EdgeInsets.all(9 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46 * scale,
                  height: 46 * scale,
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
                      Flexible(
                        child: Text(
                          '4.9 Verified',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 9.5 * scale,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  '60-min doorstep fix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 10.5 * scale,
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
              color: AppColors.brandForest,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.15,
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          icon: const Icon(LucideIcons.chevronRight, size: 16),
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
    // Plain opaque tile (SKILL.md Rule 1): grid list items scroll with
    // content and sit on a white background, so refractive glass would be
    // invisible here while costing GPU fill-rate. Same card language as
    // _AllCategoryCard: white, subtle border, soft shadow.
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18 * scale),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18 * scale),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18 * scale),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12 * scale,
                offset: Offset(0, 6 * scale),
              ),
            ],
          ),
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
                    fontSize: 11.5 * scale,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    height: 1.1,
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
        borderRadius: BorderRadius.circular(18 * scale),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18 * scale),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18 * scale),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20 * scale,
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
                      top: Radius.circular(18 * scale),
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
                                  fontSize: 9.5 * scale,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
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
                            color: AppColors.brandForest,
                            fontSize: 14.5 * scale,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            height: 1.1,
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
                            const SizedBox(width: 6),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.clock,
                                    color: AppColors.mutedText,
                                    size: 14 * scale,
                                  ),
                                  SizedBox(width: 3 * scale),
                                  Flexible(
                                    child: Text(
                                      service.duration,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.mutedText,
                                        fontSize: 10.5 * scale,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 9 * scale),
                        Container(
                          width: double.infinity,
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
                              Expanded(
                                child: Text(
                                  'Verified Professional',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.brandForest,
                                    fontSize: 9.5 * scale,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
                                  ),
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
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(width: 4 * scale),
                            Flexible(
                              child: Text(
                                'Rs$originalPrice',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 10 * scale,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                            SizedBox(width: 6 * scale),
                            SizedBox(
                              height: 31 * scale,
                              child: FilledButton(
                                onPressed: onTap,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.brandForest,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 7 * scale,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      10 * scale,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Book Now',
                                  style: TextStyle(
                                    fontSize: 9.5 * scale,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
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
      padding: EdgeInsets.all(13 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34 * scale,
            height: 34 * scale,
            decoration: BoxDecoration(
              color: AppColors.brandForest.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            child: Icon(icon, color: AppColors.brandForest, size: 19 * scale),
          ),
          SizedBox(height: 5 * scale),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              height: 1.2,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2 * scale),
              child: Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 10 * scale,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
