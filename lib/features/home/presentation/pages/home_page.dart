import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/data/services_data.dart';
import '../../../../shared/widgets/voice_beam.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/models/service_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../shell/presentation/pages/main_shell.dart';

const _homeHeaderColor = Color(0xFF02462E);

/// Blinkit-style home:
/// - Solid green header that COLLAPSES on scroll.
/// - White search card that STAYS PINNED below the status bar with rounded
///   bottom corners, exactly like Blinkit's sticky search bar.
/// - White body tucked close under the search, clean green -> white curve.
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
    final horizontalInset = (22.0 * scale).clamp(18.0, 22.0).toDouble();
    final popularHeight = 266.0 * scale;

    return Scaffold(
      backgroundColor: _homeHeaderColor,
      // SafeArea keeps the scroll viewport below the status bar / notch /
      // dynamic island on all Android + iPhones, so content never slides
      // into the notification area. Header scaffold = matching status-bar
      // gutter, light icons so they stay visible on the green.
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: _homeHeaderColor,
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
                // ---- One single green header (Paytm-style collapsing unit,
                // pinned:true so it sticks to the viewport). Scroll and the
                // search glides diagonally up into the header slot while
                // bell/profile fade out — collapsed = location + search only.
                // Promo banner scrolls away beneath it. ----
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CollapsingHeaderDelegate(
                    scale: scale,
                    horizontalInset: horizontalInset,
                    modeFilter: _modeFilter,
                    onModeFilterChanged: (mode) =>
                        setState(() => _modeFilter = mode),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _PromoBanner(
                    scale: scale,
                    horizontalInset: horizontalInset,
                  ),
                ),

                // ---- Body (scrolls under the sticky search) ----
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalInset,
                          36 * scale,
                          horizontalInset,
                          22 * scale,
                        ),
                        child: _SectionHeader(
                          title: 'Service Categories',
                          onViewAll: () => _openAllCategories(context),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalInset,
                        ),
                        child: GridView.builder(
                          itemCount: _visibleServices.take(6).length,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 16 * scale,
                                crossAxisSpacing: 16 * scale,
                                childAspectRatio: 0.78,
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
                          horizontalInset,
                          38 * scale,
                          horizontalInset,
                          22 * scale,
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
                          padding: EdgeInsets.fromLTRB(
                            horizontalInset,
                            2 * scale,
                            horizontalInset,
                            12 * scale,
                          ),
                          itemCount: _visibleServices.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(width: 16 * scale),
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
                      SizedBox(height: 108 + bottomInset),
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
    AppHaptics.press();
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
    // Liquid glass bottom dialog (skill §5 + vendor
    // glass_modal_sheet_demo.dart): the sheet owns the refractive surface
    // and snaps half <-> full as the dialog morphs between the compact
    // circles and the full editor. Same route-result contract as before.
    final sheetController = GlassModalSheetController();
    return GlassModalSheet.show<_BookingPrepData>(
      context: context,
      controller: sheetController,
      initialState: GlassSheetState.half,
      halfSize: 0.62,
      // Half state (circles + orb) is where the sheet washed out: clear
      // glass over the white page has nothing to refract, and edge-to-edge
      // with square corners melts into the body. Float this detent only —
      // full state below stays solid for editor legibility.
      halfSettings: LiquidGlassSettings(
        glassColor: Colors.white.withValues(alpha: 0.88),
        blur: 28,
        thickness: 40,
      ),
      // Dim the page behind this sheet only, so the frosted half reads
      // as a layer instead of melting into the white body.
      barrierColor: Colors.black.withValues(alpha: 0.32),
      // The editor detent fills solid instead of staying frosted. That is
      // the one surface in this flow where the user types the thing the
      // whole booking depends on, so legibility outranks the effect here —
      // and it matches where the platform landed: Tinted mode and the
      // complex-content diffusion layer both exist for exactly this case.
      // blur 0 is the vendor's solid stop; the sheet crossfades glass ->
      // solid colour across the half -> full snap, so the morph still
      // melts and only the translucency goes away.
      fullSettings: const LiquidGlassSettings(
        glassColor: AppColors.background,
        blur: 0,
      ),
      fillTransition: GlassFillTransition.gradual,
      // Floating card, not edge-to-edge: side + bottom margins with round
      // corners cut it from the page (Maps-style). Package defaults are
      // already floating — we keep an explicit tight float here.
      horizontalMargin: 10,
      bottomMargin: 12,
      topBorderRadius: 28,
      bottomBorderRadius: 28,
      detents: const {GlassSheetDetent.medium, GlassSheetDetent.large},
      builder: (_) => _BookingPrepDialog(
        service: service,
        sheetController: sheetController,
      ),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
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
                    shape: const LiquidRoundedSuperellipse(borderRadius: 15),
                    useOwnLayer: true,
                    // Forest-tinted glass so the CTA reads as a solid action
                    // on the white sheet (glassColor opacity = tint
                    // intensity); white label stays legible over the tint.
                    settings: const LiquidGlassSettings(
                      glassColor: AppColors.brandForest,
                    ),
                    onTap: () {
                      AppHaptics.confirm();
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
  const _BookingPrepDialog({
    required this.service,
    required this.sheetController,
  });

  final ServiceItem service;
  final GlassModalSheetController sheetController;

  @override
  State<_BookingPrepDialog> createState() => _BookingPrepDialogState();
}

class _BookingPrepDialogState extends State<_BookingPrepDialog>
    with TickerProviderStateMixin {
  _PrepMode _mode = _PrepMode.options;

  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speech = SpeechToText();

  /// Slow loop driving the lively fluid gradient behind the dialog content.
  late final AnimationController _fluidController;

  /// Whether the wash ticker is currently running, so build can react to
  /// the editor-detent flip once instead of re-arming it on every rebuild.
  bool _fluidRunning = true;

  bool _startingListen = false;
  String _liveTranscript = '';

  /// Live voice level (0..1) driving the thinking orb. A ValueNotifier so
  /// mic ticks repaint ONLY the orb — not the whole sheet (that full
  /// ListView rebuild on every level callback was the jank).
  final ValueNotifier<double> _voiceLevel = ValueNotifier(0);
  double _minLevel = double.infinity;
  double _maxLevel = double.negativeInfinity;

  /// Gentle synthetic breathing for the orb until the first real mic level
  /// arrives, so the visuals never sit dead on slower devices.
  Timer? _idleWaveTimer;

  /// Demo fallback when the recognizer is unavailable (denied/simulator):
  /// streams sample words + synthetic levels so the beam + word-by-word
  /// still play exactly as with a live mic.
  Timer? _demoTimer;

  /// Fires once if a live session hears nothing useful, so the UI can
  /// say so instead of hanging on "Listening…" forever.
  Timer? _noSpeechTimer;
  bool _showNoSpeechHint = false;

  /// Settle phase: the recogniser has finalised and we hold the beam in its
  /// `processing` sweep for one travel before opening the editor. This is the
  /// libraries.dev/voice `processing={thinking}` moment — in this flow the
  /// "work in progress" is turning speech into the final transcript, and
  /// without this the sweep would only ever run during mic init, which lasts
  /// a few milliseconds and is never actually seen.
  Timer? _settleTimer;
  bool _settling = false;

  /// One full beam travel, matched to VoiceBeam.processingDuration.
  static const _settleDelay = Duration(milliseconds: 1100);
  static const _demoWords = <String>[
    'My',
    'kitchen',
    'tap',
    'is',
    'leaking',
    'and',
    'I',
    'need',
    'a',
    'plumber',
    'tomorrow',
    'morning',
  ];

  void _stopIdleWave() {
    _idleWaveTimer?.cancel();
    _idleWaveTimer = null;
  }

  void _stopDemo() {
    _demoTimer?.cancel();
    _demoTimer = null;
  }

  void _disarmNoSpeechHint() {
    _noSpeechTimer?.cancel();
    _noSpeechTimer = null;
  }

  void _stopSettle() {
    _settleTimer?.cancel();
    _settleTimer = null;
  }

  void _armNoSpeechHint() {
    _disarmNoSpeechHint();
    _showNoSpeechHint = false;
    _noSpeechTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted || _mode != _PrepMode.listening) return;
      if (_liveTranscript.trim().isEmpty) {
        setState(() => _showNoSpeechHint = true);
      }
    });
  }

  /// Mic unavailable: play the same UI with scripted words + levels.
  void _startDemoStream() {
    _stopIdleWave();
    _stopDemo();
    var i = 0;
    _demoTimer = Timer.periodic(const Duration(milliseconds: 340), (_) {
      if (!mounted || _mode != _PrepMode.listening) return;
      final t = DateTime.now().millisecondsSinceEpoch / 1000;
      // Synthetic voice dynamics drive the beam like real mic levels.
      _voiceLevel.value =
          (0.35 + 0.3 * math.sin(t * 5.1) * math.sin(t * 2.3)).clamp(0.0, 1.0);
      if (i < _demoWords.length) {
        setState(() => _liveTranscript =
            _demoWords.sublist(0, ++i).join(' '));
      }
    });
  }

  void _startIdleWave() {
    _stopIdleWave();
    _idleWaveTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || _mode != _PrepMode.listening) {
        return;
      }
      final t = DateTime.now().millisecondsSinceEpoch / 1000;
      final idle = 0.10 + 0.06 * math.sin(t * 1.3);
      _voiceLevel.value = idle;
    });
  }

  /// Silent failure exit: back to the circles, no error text.
  void _abortListen() {
    _stopIdleWave();
    _stopDemo();
    _disarmNoSpeechHint();
    _speech.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _startingListen = false;
      _mode = _PrepMode.options;
    });
  }

  void _handleSoundLevel(double level) {
    if (!mounted || _mode != _PrepMode.listening) {
      return;
    }
    // Self-calibrating normalization: the level range is platform
    // dependent, so track this session's floor/ceiling instead.
    if (level < _minLevel) {
      _minLevel = level;
    }
    if (level > _maxLevel) {
      _maxLevel = level;
    }
    // First real mic level: the idle fallback has done its job.
    _stopIdleWave();
    final span = (_maxLevel - _minLevel).clamp(0.001, double.infinity);
    final target = ((level - _minLevel) / span).clamp(0.0, 1.0);
    // Ease toward the target so the orb glides instead of jumping.
    // No setState: ValueNotifier repaints the orb alone.
    _voiceLevel.value += (target - _voiceLevel.value) * 0.5;
  }

  /// Keyboard pops immediately only when the editor is opened via the chat
  /// circle — not when arriving from a voice transcript review.
  bool _autofocusEditor = false;

  /// Chat circle tap: morph the glass dialog into the text editor and snap
  /// the sheet to the full detent. Same flow continues from there.
  /// [autofocus] is false when arriving from a voice transcript, so the
  /// keyboard does not cover the transcript the user just reviewed.
  void _openEditor({bool autofocus = true}) {
    _stopSettle();
    setState(() {
      _settling = false;
      _autofocusEditor = autofocus;
      _mode = _PrepMode.describe;
    });
    widget.sheetController.snapToState(GlassSheetState.full);
  }

  @override
  void initState() {
    super.initState();
    _fluidController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _stopIdleWave();
    _stopDemo();
    _disarmNoSpeechHint();
    _stopSettle();
    _voiceLevel.dispose();
    _fluidController.dispose();
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
    // Optimistic UI: orb appears the instant the mic is tapped —
    // the recognizer catches up underneath.
    _voiceLevel.value = 0;
    _minLevel = double.infinity;
    _maxLevel = double.negativeInfinity;
    setState(() {
      _startingListen = true;
      _mode = _PrepMode.listening;
      _liveTranscript = '';
      _showNoSpeechHint = false;
    });
    // The sheet stays on its medium detent — tapping the mic must not resize
    // the stage. The gradient simply hands off to the opaque white fill.
    _startIdleWave();
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
          _abortListen();
        },
      );
      if (!available) {
        // No recognizer (simulator/denied): demo the identical UI so the
        // beam + word-by-word can still be reviewed.
        if (!mounted) return;
        setState(() => _startingListen = false);
        _startDemoStream();
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() => _startingListen = false);
      await _speech.listen(
        onResult: (result) {
          if (!mounted) {
            return;
          }
          // Every partial streams in word-by-word; finals just keep the
          // words on screen and keep listening until pause/Stop.
          setState(() => _liveTranscript = result.recognizedWords);
        },
        onSoundLevelChange: _handleSoundLevel,
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: true,
        ),
      );
      // If the engine hears nothing (routed mic, offline recognizer),
      // say so instead of hanging on "Listening…" forever.
      _armNoSpeechHint();
    } catch (_) {
      if (!mounted) {
        return;
      }
      await _speech.stop();
      setState(() {
        _startingListen = false;
        _mode = _PrepMode.options;
      });
    }
  }

  /// Stops the recognizer and expands the dialog to the fullest editor with
  /// the transcript loaded for review. Empty auto-stop glides back to the
  /// circles silently — no "did not catch that" dead-ends.
  Future<void> _finishListening({required bool auto}) async {
    // Auto-stop glides back on its own; only the manual "use recording" tap
    // deserves a haptic.
    if (!auto) AppHaptics.confirm();
    _stopIdleWave();
    _stopDemo();
    _disarmNoSpeechHint();
    await _speech.stop();
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
    // Auto-stop with something heard: hold one full beam sweep in its
    // `processing` state, then open the editor. The sweep is the only
    // feedback between the last word and the editor appearing, and it is
    // what the libraries.dev/voice demo shows for `processing={thinking}`.
    if (auto && heard.isNotEmpty) {
      _stopSettle();
      setState(() => _settling = true);
      _settleTimer = Timer(_settleDelay, () {
        _stopSettle();
        _openEditor(autofocus: false);
      });
      return;
    }
    // Manual confirmation skips the wait — the user already committed.
    if (heard.isNotEmpty || !auto) {
      _openEditor(autofocus: false);
      return;
    }
    // Engine stopped on its own without hearing anything.
    setState(() => _mode = _PrepMode.options);
  }

  void _close(_BookingPrepAction action, [String description = '']) {
    AppHaptics.press();
    _speech.stop();
    Navigator.pop(context, _BookingPrepData(action, description));
  }

  @override
  Widget build(BuildContext context) {
    // Glass sheet content (vendor glass_modal_sheet_demo.dart BaseScenario
    // pattern): plain text/icons plus glass controls, driven by the sheet's
    // own scroll controller so drag-to-dismiss keeps working. The sheet
    // chrome (glass surface, drag indicator) comes from GlassModalSheet.
    final scrollData = ScrollControllerProvider.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final expanded = _mode == _PrepMode.describe;
    // The two invitation circles own the gradient; every working stage (the
    // orb, the editor) sits on the opaque white fill instead. All three share
    // one sheet height — the sheet never resizes between stages, only its
    // surface crossfades.
    final washOn = _mode == _PrepMode.options;
    // Fixed-height content sized to the medium detent, unchanged.
    final compactHeight = (screenHeight * 0.62 - 96 - bottomInset)
        .clamp(280.0, double.infinity)
        .toDouble();
    // Retiring the ticker instead of just hiding the wash keeps a full-screen
    // CustomPaint from ticking under the orb or the caret — that was the third
    // animating layer stacked on the shader and the blur.
    if (_fluidRunning != washOn) {
      _fluidRunning = washOn;
      final run = washOn;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (run) {
          _fluidController.repeat();
        } else {
          _fluidController.stop();
        }
      });
    }
    // Lively fluid gradient drifting behind the content (isolated repaint,
    // pointer-transparent so sheet drags still reach the ListView). Faded out
    // on the white working surfaces so no gradient drifts under the orb, the
    // controls, or typed text.
    return Stack(
      children: [
        // Opaque working surface. Sits under the wash so the hand-off is a
        // straight crossfade: gradient out, white in, sheet height untouched.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: washOn ? 0 : 1,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              child: const ColoredBox(color: AppColors.background),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: washOn ? 1 : 0,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              child: _FluidBackdrop(animation: _fluidController),
            ),
          ),
        ),
        ListView(
          controller: scrollData?.controller,
          physics: scrollData?.physics,
          padding: EdgeInsets.fromLTRB(18, 12, 18, 16 + bottomInset),
          children: [
            expanded ? _buildDescribe() : _buildCompact(compactHeight),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader({required String title}) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                height: 1.15,
                decoration: TextDecoration.none,
              ),
            ),
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

  /// Compact dialog: one centered stage, cross-faded between the two
  /// circles and the live orb — same height, same alignment, so the sheet
  /// never jumps when the mic opens.
  Widget _buildCompact(double contentHeight) {
    final listening = _mode == _PrepMode.listening;
    return SizedBox(
      height: contentHeight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: listening
            ? _buildListening(key: const ValueKey('listening'))
            : _buildOptions(key: const ValueKey('options')),
      ),
    );
  }

  /// Compact section: just two glass circles, no text. Each owns its
  /// glass layer so the two tints stay distinct on the shared sheet.
  Widget _buildOptions({Key? key}) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassIconButton(
              icon: const Icon(
                LucideIcons.messageSquareText,
                color: AppColors.brandForest,
              ),
              onPressed: _startingListen
                  ? null
                  : () {
                      AppHaptics.press();
                      _openEditor();
                    },
              useOwnLayer: true,
              size: 68,
              iconSize: 26,
              settings: const LiquidGlassSettings(
                glassColor: Colors.transparent,
              ),
              semanticLabel: 'Describe the problem by text',
            ),
            const SizedBox(width: 28),
            GlassIconButton(
              icon: _startingListen
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.mic, color: Colors.white),
              onPressed: _startingListen ? null : _startListening,
              useOwnLayer: true,
              size: 68,
              iconSize: 26,
              settings: const LiquidGlassSettings(glassColor: Colors.black),
              semanticLabel: 'Describe the problem by voice',
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Live listening stage — exact libraries.dev/voice layout: the glow
  /// wraps the chat box itself (no orb), transcript streams word-by-word
  /// inside it. Mic ticks repaint only the beam via [_voiceLevel].
  Widget _buildListening({Key? key}) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VoiceBeam(
          levelListenable: _voiceLevel,
          // Sweeps while the mic opens AND through the settle pass after the
          // recogniser finalises — the only moment the travel is visible.
          processing: _startingListen || _settling,
          type: VoiceBeamType.standard,
          // Brand palette rather than the upstream rainbow: on a pale glass
          // panel a saturated forest/gold beam reads as ours, where the
          // multi-hue one turns to confetti.
          colorVariant: VoiceBeamColorVariant.forest,
          theme: VoiceBeamTheme.light,
          borderRadius: 22,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            // Frosted panel, not a black box: the transcript reads as app text
            // on glass, and the beam has a real surface to sit on.
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 132,
                  maxHeight: 172,
                ),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 1,
                  ),
                ),
                child: _buildLiveTranscript(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassIconButton(
              icon: const Icon(
                LucideIcons.x,
                color: AppColors.brandForest,
              ),
              onPressed: _cancelListening,
              useOwnLayer: true,
              size: 56,
              iconSize: 24,
              settings: const LiquidGlassSettings(
                glassColor: Colors.transparent,
              ),
              semanticLabel: 'Cancel recording',
            ),
            const SizedBox(width: 20),
            GlassIconButton(
              icon: const Icon(LucideIcons.check, color: Colors.white),
              onPressed: () => _finishListening(auto: false),
              useOwnLayer: true,
              size: 56,
              iconSize: 24,
              settings: const LiquidGlassSettings(glassColor: Colors.black),
              semanticLabel: 'Use recording',
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// Word-by-word live transcript on the frosted panel. Newest word fades in
  /// and takes the brand forest at full strength, settled words step back to
  /// a readable muted grey; the caret blinks gold at the end.
  Widget _buildLiveTranscript() {
    final heard = _liveTranscript.trim();
    if (heard.isEmpty) {
      return Center(
        child: Text(
          _showNoSpeechHint
              ? 'Still listening… try speaking a little louder'
              : 'Listening…',
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }
    final words = heard.split(RegExp(r'\s+'));
    // Keep the tail visible on long takes.
    final tail = words.length > 40 ? words.sublist(words.length - 40) : words;
    final offset = words.length - tail.length;
    return SingleChildScrollView(
      reverse: true,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (var i = 0; i < tail.length; i++)
            TweenAnimationBuilder<double>(
              key: ValueKey('${offset + i}:${tail[i]}'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 180),
              builder: (context, opacity, child) => Opacity(
                opacity: i == tail.length - 1 ? opacity : 1,
                child: child,
              ),
              child: Text(
                tail[i],
                style: TextStyle(
                  // Newest word is the one still being revised, so it carries
                  // the emphasis; settled words recede but stay legible.
                  color: i == tail.length - 1
                      ? AppColors.brandForest
                      : AppColors.mutedText,
                  fontSize: 16,
                  fontWeight: i == tail.length - 1
                      ? FontWeight.w700
                      : FontWeight.w500,
                  height: 1.4,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          const _BlinkingCaret(color: AppColors.brandGold),
        ],
      ),
    );
  }

  /// X tap: discard the take and glide back to the circles.
  void _cancelListening() {
    AppHaptics.press();
    _stopIdleWave();
    _stopDemo();
    _disarmNoSpeechHint();
    _speech.stop();
    _voiceLevel.value = 0;
    if (!mounted) {
      return;
    }
    setState(() {
      _startingListen = false;
      _mode = _PrepMode.options;
      _liveTranscript = '';
    });
  }

  /// Expanded state of the same glass dialog: the chat circle morphs into a
  /// glass text box plus Back / Continue actions. The sheet snaps to the
  /// full detent (opaque, like Maps/Music) and its ListView scrolls, so the
  /// keyboard can never cover Continue.
  Widget _buildDescribe() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        _buildHeader(title: 'State your problem'),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GlassTextField(
            controller: _textController,
            placeholder: 'Write here…',
            minLines: 5,
            maxLines: 8,
            autofocus: _autofocusEditor,
            textStyle: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
            placeholderStyle: TextStyle(
              color: AppColors.mutedText.withValues(alpha: 0.75),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  AppHaptics.press();
                  setState(() => _mode = _PrepMode.options);
                  widget.sheetController.snapToState(GlassSheetState.half);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandForest,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassButton.custom(
                width: double.infinity,
                height: 48,
                shape: const LiquidRoundedSuperellipse(borderRadius: 15),
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
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Slow-drifting fluid gradient behind the booking dialog content: soft
/// neutral green blobs wandering on Lissajous paths at low alpha, so the
/// frosted sheet feels alive while text stays legible.
/// Blinking caret trailing the live transcript — the focused-input feel
/// from the voice-glow demo. Cheap 1Hz opacity loop, isolated repaint.
class _BlinkingCaret extends StatefulWidget {
  const _BlinkingCaret({this.color = AppColors.brandForest});

  final Color color;

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1060),
    )..repeat();
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blink,
      builder: (_, _) => Opacity(
        opacity: _blink.value < 0.5 ? 1 : 0,
        child: Container(
          width: 2,
          height: 16,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _FluidBackdrop extends StatelessWidget {
  const _FluidBackdrop({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    // Two layers so only the cheap one animates. The base wash is a static
    // gradient that never repaints and stays in the raster cache; only the
    // blob overlay is rebuilt per frame, which keeps the drifting layer from
    // re-rasterising a full-screen gradient 60 times a second.
    return Stack(
      fit: StackFit.expand,
      children: [
        // Warm base wash so the gradient reads even between blob passes,
        // deepening toward the bottom where the circles sit.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.brandGold.withValues(alpha: 0.08),
                AppColors.brandGold.withValues(alpha: 0.20),
                AppColors.brandGold.withValues(alpha: 0.32),
              ],
            ),
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, _) => CustomPaint(
              painter: _FluidBlobsPainter(animation.value),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }
}

class _FluidBlobsPainter extends CustomPainter {
  _FluidBlobsPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * math.pi;
    _blob(
      canvas,
      Offset(
        size.width * (0.5 + 0.38 * math.sin(t)),
        size.height * (0.5 + 0.32 * math.cos(t * 0.8)),
      ),
      180,
      _homeHeaderColor.withValues(alpha: 0.38),
    );
    _blob(
      canvas,
      Offset(
        size.width * (0.5 + 0.34 * math.sin(t * 0.7 + 2.1)),
        size.height * (0.5 + 0.36 * math.cos(t * 0.9 + 1.2)),
      ),
      200,
      AppColors.brandForest.withValues(alpha: 0.22),
    );
    _blob(
      canvas,
      Offset(
        size.width * (0.5 + 0.4 * math.cos(t * 0.6 + 4.0)),
        size.height * (0.5 + 0.3 * math.sin(t + 0.6)),
      ),
      150,
      const Color(0xFFFFE3A3).withValues(alpha: 0.45),
    );
  }

  void _blob(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _FluidBlobsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Dummy payment screen: order summary, fake method picker, and a Pay now
/// action that records the booking and returns to the home (first) route.
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
    AppHaptics.confirm();
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
                    borderRadius: BorderRadius.circular(15),
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
                borderRadius: BorderRadius.circular(15),
                onTap: _paying
                    ? null
                    : () {
                        if (entry.$1 == _methodIndex) return;
                        AppHaptics.tick();
                        setState(() => _methodIndex = entry.$1);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
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
          shape: const LiquidRoundedSuperellipse(borderRadius: 15),
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
                    borderRadius: BorderRadius.circular(15),
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
                onPressed: () {
                  AppHaptics.press();
                  _returnHome();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandForest,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
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
                onPressed: () {
                  AppHaptics.press();
                  _returnHome();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandForest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
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
      borderRadius: BorderRadius.circular(15),
      elevation: 0,
      child: InkWell(
        onTap: () {
          AppHaptics.press();
          onTap();
        },
        borderRadius: BorderRadius.circular(15),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
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
                    borderRadius: BorderRadius.circular(15),
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
/// Paytm-style collapsing header: expanded = location row + big search.
/// Scroll and the search glides diagonally up into the header slot while
/// bell/profile fade out with the location row — collapsed = compact
/// location + mini search in a single pinned row. Scroll-linked via
/// shrinkOffset (no controller needed); one shared [_SearchBar] instance
/// so typing/focus state never splits.
class _CollapsingHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CollapsingHeaderDelegate({
    required this.scale,
    required this.horizontalInset,
    required this.modeFilter,
    required this.onModeFilterChanged,
  });

  final double scale;
  final double horizontalInset;
  final BookingMode? modeFilter;
  final ValueChanged<BookingMode?> onModeFilterChanged;

  static const _locationHeight = 64.0;
  // 8 top + 52 search + 8 bottom. Fixed so the search card can never
  // overflow and get covered, on any screen width.
  static const _searchHeight = 68.0;

  @override
  double get minExtent => _searchHeight;

  @override
  double get maxExtent => _locationHeight + _searchHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / _locationHeight).clamp(0.0, 1.0);
    // Smoothstep for fades/widths. Heights stay LINEAR in t so the column
    // total always equals the sliver extent exactly (eased heights drift
    // off-extent mid-transition = RenderFlex overflow + yellow stripes).
    final e = t * t * (3 - 2 * t);
    return Container(
      color: _homeHeaderColor,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Location row (pin + address + bell + profile) collapses away.
          // OverflowBox lets the fixed 64px content exceed the shrinking
          // box without asserting; ClipRect clips the paint.
          ClipRect(
            child: SizedBox(
              height: _locationHeight * (1 - t),
              child: OverflowBox(
                minHeight: 0,
                maxHeight: _locationHeight,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: _locationHeight,
                  child: Opacity(
                    opacity: (1 - e * 1.4).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -28 * e),
                      child: Container(
                        color: _homeHeaderColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalInset,
                          vertical: 10,
                        ),
                        child: _LocationBar(scale: scale),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Search row: pin icon fades in on the left while the shared
          // search box glides up beside it — the diagonal move. Icon-only
          // (no text) so the search keeps plenty of width when collapsed.
          Container(
            height: _searchHeight,
            color: _homeHeaderColor,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                ClipRect(
                  // 48 fits the left inset + 22px pin at any screen width.
                  child: SizedBox(
                    width: 48 * e,
                    child: Opacity(
                      opacity: e.clamp(0.0, 1.0),
                      child: Padding(
                        padding: EdgeInsets.only(left: horizontalInset),
                        child: const SizedBox(
                          height: 52,
                          child: Icon(
                            LucideIcons.mapPin,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6 * e),
                Expanded(
                  child: Padding(
                    // Left inset melts away as the mini location takes it.
                    padding: EdgeInsets.only(
                      left: horizontalInset * (1 - e),
                      right: horizontalInset,
                    ),
                    // The mode menu owns view filtering; the typed query is
                    // still a no-op for a future grid filter.
                    child: _SearchBar(
                      onChanged: (_) {},
                      modeFilter: modeFilter,
                      onModeFilterChanged: onModeFilterChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CollapsingHeaderDelegate oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.horizontalInset != horizontalInset ||
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
    if (mode == widget.modeFilter) return;
    AppHaptics.tick();
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
    AppHaptics.press();
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
              searchIconColor: Colors.white,
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
              placeholderStyle: const TextStyle(
                color: Colors.white70,
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
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
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

/// Blinkit-style location row: pin + address left, actions right.
class _LocationBar extends StatelessWidget {
  const _LocationBar({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _homeHeaderColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38 * scale,
            height: 38 * scale,
            decoration: BoxDecoration(
              color: _homeHeaderColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Icon(
              LucideIcons.mapPin,
              color: Colors.white,
              size: 20 * scale,
            ),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR LOCATION',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
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
                          color: Colors.white,
                          fontSize: 16.5 * scale,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronDown,
                      color: Colors.white.withValues(alpha: 0.78),
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
              color: _homeHeaderColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
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
              color: Colors.white,
              size: 24 * scale,
            ),
          ),
        ],
      ),
    );
  }
}

/// Blinkit-style promo banner: green card that scrolls away below the
/// sticky search, with dot texture, headline, CTA + illustration.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.scale, required this.horizontalInset});

  final double scale;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    // Full-bleed green banner plugged flush under the sticky search (zero
    // top gap so it moves up). The OUTER container owns the bottom curve
    // so the bottom corners actually round into the white body.
    return Container(
      decoration: BoxDecoration(
        color: _homeHeaderColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalInset,
          2 * scale,
          horizontalInset,
          18 * scale,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14 * scale, 4 * scale, 14 * scale, 0),
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
                                color: Colors.white,
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
                                color: Colors.white.withValues(alpha: 0.72),
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
                                  backgroundColor: Colors.white,
                                  foregroundColor: _homeHeaderColor,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      11 * scale,
                                    ),
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
        ),
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
        color: _homeHeaderColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
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
          Icon(icon, color: Colors.white, size: 21 * scale),
          if (hasDot)
            Positioned(
              right: 11 * scale,
              top: 11 * scale,
              child: Container(
                width: 8 * scale,
                height: 8 * scale,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _homeHeaderColor, width: 1.5),
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
        borderRadius: BorderRadius.circular(15),
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
                    borderRadius: BorderRadius.circular(15),
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
                    borderRadius: BorderRadius.circular(15),
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
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.07);
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
    final assetPath = _categoryAssetPath(service);

    return InkWell(
      onTap: () {
        AppHaptics.press();
        onTap();
      },
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: service.color,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12 * scale,
                    offset: Offset(0, 6 * scale),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: assetPath == null
                    ? Center(
                        child: Icon(
                          service.icon,
                          color: AppColors.brandForest,
                          size: 34 * scale,
                        ),
                      )
                    : Image.asset(
                        assetPath,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            _categoryTitle(service.title),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.1,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  String _categoryTitle(String title) {
    return switch (title) {
      'Civil touch-ups' => 'Ceiling',
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

  String? _categoryAssetPath(ServiceItem service) {
    return switch (service.title) {
      'Civil touch-ups' => 'assets/service_cat/ceiling.png',
      'Plumbing fixes' => 'assets/service_cat/plumbing.png',
      'Electrical snags' => 'assets/electrician.png',
      'Painting repairs' => 'assets/service_cat/painting.png',
      'Carpentry fixes' => 'assets/service_cat/carpenting.png',
      _ => null,
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
        borderRadius: BorderRadius.circular(15),
        elevation: 0,
        child: InkWell(
          onTap: () {
            AppHaptics.press();
            onTap();
          },
          borderRadius: BorderRadius.circular(15),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 14 * scale,
                  offset: Offset(0, 5 * scale),
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
                      top: Radius.circular(15),
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
                                onPressed: () {
                                  AppHaptics.press();
                                  onTap();
                                },
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
