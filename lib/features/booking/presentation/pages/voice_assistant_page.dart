import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/models/api/booking_draft.dart';
import '../../../../core/services/booking_assistant_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/pulse_rings.dart';

enum VoiceAssistantAction { continueBooking, chooseService }

class VoiceAssistantResult {
  const VoiceAssistantResult(this.action, this.text, this.source);

  final VoiceAssistantAction action;
  final String text;
  final DraftSource source;
}

/// Opens the voice assistant full screen with a soft fade-up.
Future<VoiceAssistantResult?> showVoiceAssistant(
  BuildContext context, {
  bool startListening = true,
}) {
  return Navigator.of(context).push<VoiceAssistantResult>(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) =>
          VoiceAssistantPage(startListening: startListening),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

enum _Stage { idle, starting, listening, review }

/// Booking assistant, step 1 — "tell us what's wrong".
///
/// Full-screen, Zomato/Swiggy-style voice search: a big conversational
/// headline that becomes the live transcript, "Try saying" prompts, and one
/// large mic that glows with the customer's voice. When they stop, the
/// words become an editable review with a single "Find my pro" action.
/// Audio never leaves the phone — only the recognised text is used.
class VoiceAssistantPage extends StatefulWidget {
  const VoiceAssistantPage({super.key, this.startListening = true});

  final bool startListening;

  @override
  State<VoiceAssistantPage> createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends State<VoiceAssistantPage> {
  static const _examples = [
    'Kitchen sink is leaking since morning',
    'AC is not cooling, can someone come tomorrow?',
    'Sparks from the switch board',
  ];

  /// en-IN when installed, else the device default. Resolved once.
  static String? _localeId;

  final SpeechToText _speech = SpeechToText();
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _level = ValueNotifier<double>(0);
  double _minLevel = double.infinity;
  double _maxLevel = double.negativeInfinity;

  _Stage _stage = _Stage.idle;
  String _live = '';
  String? _hint;
  bool _micUnavailable = false;
  bool _finishing = false;
  String? _voiceText;
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    if (widget.startListening) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
    } else {
      _stage = _Stage.review;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focus.requestFocus(),
      );
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _speech.cancel();
    // The plugin is a singleton; don't leave it calling a dead State.
    _speech.statusListener = null;
    _speech.errorListener = null;
    _text.dispose();
    _focus.dispose();
    _level.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ speech

  Future<void> _listen() async {
    if (_stage == _Stage.starting || _stage == _Stage.listening) return;
    AppHaptics.press();
    _focus.unfocus();
    _level.value = 0;
    _minLevel = double.infinity;
    _maxLevel = double.negativeInfinity;
    setState(() {
      _stage = _Stage.starting;
      _live = '';
      _hint = null;
      _finishing = false;
    });
    try {
      // SpeechToText is a process-wide singleton: initialize() wires the
      // callbacks only once, so re-point them at this page every time.
      _speech.statusListener = _onStatus;
      _speech.errorListener = _onError;
      final ok =
          _speech.isAvailable ||
          await _speech.initialize(onStatus: _onStatus, onError: _onError);
      if (!ok) {
        _voiceUnavailable();
        return;
      }
      if (_speech.isListening) await _speech.cancel();
      final locale = await _resolveLocale();
      if (!mounted || _stage != _Stage.starting) return;
      setState(() => _stage = _Stage.listening);
      await _speech.listen(
        onResult: (r) {
          if (!mounted || _stage != _Stage.listening) return;
          final words = r.recognizedWords;
          if (words.trim().isEmpty) return;
          setState(() => _live = words);
        },
        onSoundLevelChange: _onLevel,
        listenOptions: SpeechListenOptions(
          localeId: locale,
          listenMode: ListenMode.dictation,
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: false,
        ),
      );
      _silenceTimer?.cancel();
      _silenceTimer = Timer(const Duration(seconds: 7), () {
        if (mounted && _stage == _Stage.listening && _live.trim().isEmpty) {
          setState(() => _hint = 'Still listening… try speaking a bit louder');
        }
      });
    } catch (_) {
      _stopWith("Couldn't start the microphone. Tap to try again.");
    }
  }

  Future<String?> _resolveLocale() async {
    if (_localeId != null) return _localeId;
    try {
      final locales = await _speech.locales();
      for (final l in locales) {
        if (l.localeId.replaceAll('-', '_').toLowerCase() == 'en_in') {
          return _localeId = l.localeId;
        }
      }
      _localeId = (await _speech.systemLocale())?.localeId;
    } catch (_) {}
    return _localeId;
  }

  void _onLevel(double level) {
    if (_stage != _Stage.listening) return;
    if (level < _minLevel) _minLevel = level;
    if (level > _maxLevel) _maxLevel = level;
    final span = (_maxLevel - _minLevel).clamp(0.001, double.infinity);
    final target = ((level - _minLevel) / span).clamp(0.0, 1.0);
    _level.value += (target - _level.value) * 0.5;
  }

  void _onStatus(String status) {
    // Only `done` ends a take — on Android `notListening` comes before the
    // final result, and stopping there dropped the last words.
    if (status == 'done' && mounted && _stage == _Stage.listening) _finish();
  }

  void _onError(SpeechRecognitionError error) {
    if (!mounted || _stage == _Stage.review) return;
    if (error.errorMsg.contains('permission')) {
      _voiceUnavailable();
      return;
    }
    // Keep whatever was heard — "no match" after words is a normal end.
    if (_live.trim().isNotEmpty) {
      _finish();
      return;
    }
    _stopWith(
      error.errorMsg.contains('network')
          ? 'Voice needs internet. Tap to try again, or type it.'
          : "Didn't catch that. Tap the mic to try again.",
    );
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _silenceTimer?.cancel();
    if (_speech.isListening) {
      await _speech.stop();
      // The final words arrive as one more result right after stop().
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    if (!mounted) return;
    final heard = _live.trim();
    if (heard.isEmpty) {
      _stopWith("Didn't catch that. Tap the mic to try again.");
      return;
    }
    AppHaptics.confirm();
    _voiceText = heard;
    _text.text = heard;
    _text.selection = TextSelection.collapsed(offset: heard.length);
    setState(() {
      _stage = _Stage.review;
      _hint = null;
    });
  }

  void _stopWith(String hint) {
    _silenceTimer?.cancel();
    _speech.cancel();
    _level.value = 0;
    if (!mounted) return;
    setState(() {
      _stage = _text.text.trim().isEmpty ? _Stage.idle : _Stage.review;
      _hint = hint;
    });
  }

  void _voiceUnavailable() {
    _silenceTimer?.cancel();
    _speech.cancel();
    if (!mounted) return;
    setState(() {
      _micUnavailable = true;
      _stage = _Stage.review;
      _hint =
          "Voice isn't available — allow the microphone in Settings, or just "
          'type it.';
    });
    _focus.requestFocus();
  }

  void _onMicTap() {
    if (_stage == _Stage.listening) {
      _finish();
    } else {
      _listen();
    }
  }

  void _typeInstead() {
    AppHaptics.press();
    _silenceTimer?.cancel();
    _speech.cancel();
    if (_text.text.trim().isEmpty && _live.trim().isNotEmpty) {
      _text.text = _live.trim();
      _voiceText = _live.trim();
    }
    setState(() {
      _stage = _Stage.review;
      _hint = null;
    });
    _focus.requestFocus();
  }

  void _useExample(String example) {
    AppHaptics.tick();
    _speech.cancel();
    _voiceText = null;
    _text.text = example;
    _text.selection = TextSelection.collapsed(offset: example.length);
    setState(() {
      _stage = _Stage.review;
      _hint = null;
    });
  }

  DraftSource get _source {
    final heard = _voiceText;
    if (heard == null || heard.isEmpty) return DraftSource.text;
    final now = _text.text;
    final words = heard.split(RegExp(r'\s+'));
    final kept = words.where(now.contains).length;
    return kept / words.length >= 0.5 ? DraftSource.voice : DraftSource.text;
  }

  bool get _canContinue =>
      _text.text.trim().length >= BookingAssistantService.minMessageLength;

  void _close(VoiceAssistantAction action) {
    AppHaptics.confirm();
    _speech.cancel();
    Navigator.pop(
      context,
      VoiceAssistantResult(action, _text.text.trim(), _source),
    );
  }

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final review = _stage == _Stage.review;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surfaceTint, Colors.white],
            stops: [0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _topBar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  child: review ? _reviewBody() : _listenBody(),
                ),
              ),
              review ? _reviewFooter() : _listenFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.brandForest.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.sparkles,
                  size: 13,
                  color: AppColors.brandTeal,
                ),
                const SizedBox(width: 6),
                Text(
                  'ZingIT Assistant',
                  style: GoogleFonts.poppins(
                    color: AppColors.brandForest,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              AppHaptics.press();
              Navigator.pop(context);
            },
            tooltip: 'Close',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(LucideIcons.x, color: AppColors.brandForest),
          ),
        ],
      ),
    );
  }

  // Listening -------------------------------------------------------

  Widget _listenBody() {
    final heard = _live.trim();
    return ListView(
      key: const ValueKey('listen'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      children: [
        Text(
          _stage == _Stage.listening ? 'LISTENING' : 'TAP THE MIC & SPEAK',
          style: GoogleFonts.poppins(
            color: AppColors.brandTeal,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        if (heard.isEmpty)
          Text(
            "Hi! Tell us what's\nwrong at home",
            style: GoogleFonts.poppins(
              color: AppColors.brandForest,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.22,
              letterSpacing: -0.6,
            ),
          )
        else
          _liveTranscript(heard),
        if (heard.isEmpty) ...[
          const SizedBox(height: 34),
          Text(
            'Try saying',
            style: GoogleFonts.poppins(
              color: AppColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          for (final e in _examples) _exampleRow(e),
        ],
      ],
    );
  }

  /// Big transcript: settled words forest, the word still being heard teal.
  Widget _liveTranscript(String heard) {
    final words = heard.split(RegExp(r'\s+'));
    final settled = words.length > 1
        ? '${words.sublist(0, words.length - 1).join(' ')} '
        : '';
    final style = GoogleFonts.poppins(
      fontSize: 27,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.5,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: settled,
            style: style.copyWith(color: AppColors.brandForest),
          ),
          TextSpan(
            text: words.last,
            style: style.copyWith(color: AppColors.brandTeal),
          ),
        ],
      ),
    );
  }

  Widget _exampleRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _useExample(text),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.quote,
                  size: 16,
                  color: AppColors.brandGold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      color: AppColors.brandForest,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.arrowUpRight,
                  size: 16,
                  color: AppColors.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _listenFooter() {
    final listening = _stage == _Stage.listening;
    final starting = _stage == _Stage.starting;
    final status =
        _hint ??
        (starting
            ? 'Opening the mic…'
            : listening
            ? (_live.trim().isEmpty
                  ? 'Go ahead, I’m listening…'
                  : 'Tap when you’re done')
            : 'Tap the mic to speak');
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              status,
              key: ValueKey(status),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: _hint != null
                    ? const Color(0xFFB4541A)
                    : AppColors.mutedText,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _BigMic(
            listening: listening || starting,
            level: _level,
            onTap: _onMicTap,
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _typeInstead,
            style: TextButton.styleFrom(foregroundColor: AppColors.brandForest),
            icon: const Icon(LucideIcons.keyboard, size: 18),
            label: Text(
              'Type instead',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Review ----------------------------------------------------------

  Widget _reviewBody() {
    return ListView(
      key: const ValueKey('review'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      children: [
        Text(
          _voiceText != null ? 'HERE’S WHAT WE HEARD' : 'YOUR PROBLEM',
          style: GoogleFonts.poppins(
            color: AppColors.brandTeal,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _text,
          focusNode: _focus,
          minLines: 2,
          maxLines: 8,
          maxLength: BookingAssistantService.maxMessageLength,
          textCapitalization: TextCapitalization.sentences,
          cursorColor: AppColors.brandTeal,
          style: GoogleFonts.poppins(
            color: AppColors.brandForest,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.32,
            letterSpacing: -0.4,
          ),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            counterText: '',
            hintText:
                'e.g. Water is leaking under my kitchen sink. '
                'Can someone come tomorrow evening?',
            hintStyle: GoogleFonts.poppins(
              color: AppColors.mutedText.withValues(alpha: 0.55),
              fontSize: 22,
              fontWeight: FontWeight.w500,
              height: 1.32,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(
              LucideIcons.pencil,
              size: 14,
              color: AppColors.mutedText,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _hint ??
                    "Tap the text to fix anything. Add where in the house and "
                        "when you'd like someone to come.",
                style: GoogleFonts.poppins(
                  color: _hint != null
                      ? const Color(0xFFB4541A)
                      : AppColors.mutedText,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reviewFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (!_micUnavailable) ...[
                _SmallMic(onTap: _listen),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _CtaButton(
                  label: 'Find my pro',
                  enabled: _canContinue,
                  onTap: () => _close(VoiceAssistantAction.continueBooking),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => _close(VoiceAssistantAction.chooseService),
            style: TextButton.styleFrom(foregroundColor: AppColors.mutedText),
            child: Text(
              'Choose a service yourself',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The hero mic: forest disc, gold glyph; gold rings breathe out of it and
/// swell with the live voice level while listening.
class _BigMic extends StatelessWidget {
  const _BigMic({
    required this.listening,
    required this.level,
    required this.onTap,
  });

  final bool listening;
  final ValueListenable<double> level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: listening ? 'Stop listening' : 'Start speaking',
      child: GestureDetector(
        onTap: onTap,
        child: PulseRings(
          coreSize: 84,
          spread: 2.1,
          color: AppColors.brandGold,
          levelListenable: listening ? level : null,
          period: Duration(milliseconds: listening ? 1600 : 2600),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C3A1C), AppColors.brandForest],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandForest.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                listening ? LucideIcons.square : LucideIcons.mic,
                key: ValueKey(listening),
                color: AppColors.brandGold,
                size: listening ? 26 : 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallMic extends StatelessWidget {
  const _SmallMic({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceTint,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox.square(
          dimension: 56,
          child: Icon(LucideIcons.mic, color: AppColors.brandForest),
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: AppColors.brandForest,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.arrowRight,
                  color: AppColors.brandGold,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
