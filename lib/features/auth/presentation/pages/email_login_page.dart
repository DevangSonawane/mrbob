import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../shell/presentation/pages/main_shell.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _pageController = PageController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();

  int _step = 0;
  DateTime _birthDate = DateTime(2025, 9, 16);

  static const _stepCount = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _phoneFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  String get _buttonLabel => switch (_step) {
    4 => 'Get started',
    _ => 'Next',
  };

  Future<void> _next() async {
    AppHaptics.confirm();

    if (_step < _stepCount - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    AppHaptics.success();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: MainShell.routeName),
        builder: (_) => const MainShell(),
      ),
    );
  }

  void _setBirthDate(DateTime value) {
    AppHaptics.tick();
    setState(() => _birthDate = value);
  }

  void _back() {
    if (_step == 0) {
      AppHaptics.press();
      Navigator.pop(context);
      return;
    }
    AppHaptics.tick();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                    child: Row(
                      children: [
                        _BackButton(onTap: _back),
                        const Spacer(),
                        SizedBox(
                          width: 136,
                          child: _ProgressBars(
                            currentStep: _step,
                            totalSteps: _stepCount,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (value) {
                        setState(() => _step = value);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          if (value == 0) {
                            _phoneFocusNode.requestFocus();
                          } else if (value == 1) {
                            _otpFocusNode.requestFocus();
                          } else {
                            FocusScope.of(context).unfocus();
                          }
                        });
                      },
                      children: [
                        _FlowStep(
                          title: 'Enter your phone number',
                          subtitle:
                              'We will send a verification code to your phone.',
                          child: _LargeTextField(
                            autofocus: true,
                            focusNode: _phoneFocusNode,
                            controller: _phoneController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(13),
                            ],
                            onSubmitted: (_) => _next(),
                          ),
                        ),
                        _FlowStep(
                          title: 'Verify your phone number',
                          subtitle:
                              'Enter the verification code sent to your phone number.',
                          child: _LargeTextField(
                            autofocus: true,
                            focusNode: _otpFocusNode,
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            onSubmitted: (_) => _next(),
                          ),
                        ),
                        _FlowStep(
                          title: 'What is your name?',
                          subtitle:
                              'Pros and support will use this for your bookings.',
                          child: _LargeTextField(
                            focusNode: _nameFocusNode,
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _next(),
                          ),
                        ),
                        _FlowStep(
                          title: 'Enter your age',
                          subtitle:
                              "We'll use this to personalize your experience",
                          child: _BirthDateWheel(
                            date: _birthDate,
                            onChanged: _setBirthDate,
                          ),
                        ),
                        const _FlowStep(
                          title: 'You are ready to book.',
                          subtitle:
                              'Your MrBob account is set up. Jump in and find trusted help for your next home task.',
                          child: _ReadyPanel(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 22,
                right: 22,
                bottom: 0,
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(
                    bottom: keyboardInset + 14 + bottomInset * 0.3,
                  ),
                  child: _NextButton(label: _buttonLabel, onTap: _next),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.brandForest,
          shape: const CircleBorder(),
        ),
        icon: const Icon(LucideIcons.chevronLeft, size: 25),
      ),
    );
  }
}

class _ProgressBars extends StatelessWidget {
  const _ProgressBars({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            height: 4,
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 5),
            decoration: BoxDecoration(
              color: active ? AppColors.brandForest : const Color(0xFFD8D8D8),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(26, 32, 26, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFB8B8B8),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 26),
          child,
        ],
      ),
    );
  }
}

class _LargeTextField extends StatelessWidget {
  const _LargeTextField({
    required this.focusNode,
    required this.controller,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onSubmitted,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: focusNode,
      autofocus: autofocus,
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onSubmitted: onSubmitted,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: AppColors.brandForest,
      cursorWidth: 1.5,
      style: const TextStyle(
        color: AppColors.brandForest,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      decoration: const InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}

class _BirthDateWheel extends StatefulWidget {
  const _BirthDateWheel({required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_BirthDateWheel> createState() => _BirthDateWheelState();
}

class _BirthDateWheelState extends State<_BirthDateWheel> {
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  late int _day;
  late int _month;
  late int _year;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;

  List<int> get _years => List.generate(101, (index) => 1930 + index);

  @override
  void initState() {
    super.initState();
    _day = widget.date.day;
    _month = widget.date.month;
    _year = widget.date.year;
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_year).clamp(0, _years.length - 1),
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _emit() {
    final maxDay = DateUtils.getDaysInMonth(_year, _month);
    if (_day > maxDay) {
      _day = maxDay;
      _dayController.jumpToItem(_day - 1);
    }
    widget.onChanged(DateTime(_year, _month, _day));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Expanded(
                flex: 7,
                child: _WheelColumn(
                  controller: _dayController,
                  itemCount: 31,
                  selectedIndex: _day - 1,
                  labelForIndex: (index) => '${index + 1}',
                  onSelectedItemChanged: (index) {
                    setState(() => _day = index + 1);
                    _emit();
                  },
                ),
              ),
              Expanded(
                flex: 11,
                child: _WheelColumn(
                  controller: _monthController,
                  itemCount: _months.length,
                  selectedIndex: _month - 1,
                  labelForIndex: (index) => _months[index],
                  onSelectedItemChanged: (index) {
                    setState(() => _month = index + 1);
                    _emit();
                  },
                ),
              ),
              Expanded(
                flex: 8,
                child: _WheelColumn(
                  controller: _yearController,
                  itemCount: _years.length,
                  selectedIndex: _years.indexOf(_year),
                  labelForIndex: (index) => '${_years[index]}',
                  onSelectedItemChanged: (index) {
                    setState(() => _year = _years[index]);
                    _emit();
                  },
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0),
                      Colors.white,
                    ],
                    stops: const [0, 0.35, 0.65, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    required this.controller,
    required this.itemCount,
    required this.selectedIndex,
    required this.labelForIndex,
    required this.onSelectedItemChanged,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedIndex;
  final String Function(int index) labelForIndex;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 34,
      diameterRatio: 1.65,
      perspective: 0.001,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final selected = index == selectedIndex;
          return Align(
            alignment: Alignment.center,
            child: Text(
              labelForIndex(index),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? AppColors.brandForest
                    : AppColors.brandForest.withValues(alpha: 0.14),
                fontSize: selected ? 20 : 17,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                height: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReadyPanel extends StatelessWidget {
  const _ReadyPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brandForest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandForest.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.brandGold,
            child: Icon(
              LucideIcons.badgeCheck,
              color: AppColors.brandForest,
              size: 25,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Fast bookings, live updates and trusted pros are waiting.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatefulWidget {
  const _NextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF221F22),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              widget.label,
              key: ValueKey(widget.label),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
