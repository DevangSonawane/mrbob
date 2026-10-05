import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/api/zone_models.dart';
import '../../../../core/services/api_exception.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/catalog_service.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../shell/presentation/pages/main_shell.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key, required this.phone});

  /// Phone number captured on the login sheet, in E.164 form
  /// ('+91…'). Sent to `/auth/otp/verify` and, for first-time
  /// logins, to `/onboarding/customer`.
  final String phone;

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  static const _locationAccent = AppColors.brandForest;

  final _pageController = PageController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();

  int _step = 0;
  String _gender = 'Male';

  /// API call in flight (OTP verify / onboarding complete).
  bool _isVerifying = false;
  bool _isOnboarding = false;

  /// Cities from `GET /zones/cities` — required by
  /// `/onboarding/customer`, so the address step lets the
  /// customer pick theirs.
  List<City> _cities = const [];
  String? _selectedCityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNode.requestFocus();
    });
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await CatalogService.instance.getCities();
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _selectedCityId = cities.isNotEmpty ? cities.first.id : null;
      });
    } on ApiException catch (_) {
      // City list unavailable — the address step surfaces the
      // error when the customer confirms.
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _otpFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  String get _buttonLabel => 'Next';

  Future<void> _next() async {
    if (_step == 0) {
      await _verifyOtp();
      return;
    }
    if (_step == 1) {
      AppHaptics.confirm();
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _completeOnboarding();
  }

  /// Step 1: `POST /auth/otp/verify`. Creates the user on
  /// first login; returning customers skip straight in.
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      AppHaptics.press();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 4-digit code')),
      );
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final session = await AuthService.instance.verifyOtp(
        widget.phone,
        otp,
      );
      AppHaptics.confirm();

      final onboarded =
          session.user.isOnboarded || await _fetchOnboarded();
      if (onboarded) {
        _enterApp();
        return;
      }
      if (!mounted) return;
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<bool> _fetchOnboarded() async {
    try {
      final status = await OnboardingService.instance.getStatus();
      return status.isOnboarded;
    } on ApiException catch (_) {
      return false;
    }
  }

  /// Step 3: `POST /onboarding/customer` — completes the
  /// profile (name, phone, city, service address).
  Future<void> _completeOnboarding() async {
    final cityId = _selectedCityId;
    if (cityId == null) {
      AppHaptics.press();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select your city to continue')),
      );
      return;
    }

    setState(() => _isOnboarding = true);
    try {
      await OnboardingService.instance.completeCustomerOnboarding(
        cityId: cityId,
        name: _nameController.text.trim(),
        phone: widget.phone,
        address: 'Selected location',
      );
      AppHaptics.success();
      _enterApp();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isOnboarding = false);
    }
  }

  void _enterApp() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: MainShell.routeName),
        builder: (_) => const MainShell(),
      ),
    );
  }

  void _selectGender(String value) {
    AppHaptics.tick();
    setState(() => _gender = value);
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
                  if (_step != 2)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                      child: Row(
                        children: [
                          _BackButton(onTap: _back),
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
                            _otpFocusNode.requestFocus();
                          } else if (value == 1) {
                            _nameFocusNode.requestFocus();
                          } else {
                            FocusScope.of(context).unfocus();
                          }
                        });
                      },
                      children: [
                        _FlowStep(
                          title: 'Verify your phone number',
                          subtitle:
                              'Enter the verification code sent to your phone number.',
                          child: _OtpBoxes(
                            focusNode: _otpFocusNode,
                            controller: _otpController,
                            onCompleted: _next,
                          ),
                        ),
                        _FlowStep(
                          title: 'What is your name?',
                          subtitle:
                              'Pros and support will use this for your bookings.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LargeTextField(
                                focusNode: _nameFocusNode,
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _next(),
                              ),
                              const SizedBox(height: 26),
                              _GenderPills(
                                selected: _gender,
                                onSelected: _selectGender,
                              ),
                            ],
                          ),
                        ),
                        _AddressStep(
                          accentColor: _locationAccent,
                          cities: _cities,
                          selectedCityId: _selectedCityId,
                          onCitySelected: (id) =>
                              setState(() => _selectedCityId = id),
                          onBack: _back,
                          onConfirm: _next,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_step != 2)
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
                      child: _NextButton(
                        label: _buttonLabel,
                        isLoading: _isVerifying || _isOnboarding,
                        onTap: _next,
                      ),
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

class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes({
    required this.focusNode,
    required this.controller,
    required this.onCompleted,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final VoidCallback onCompleted;

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChanged);
    super.dispose();
  }

  void _handleChanged() {
    setState(() {});
    if (widget.controller.text.length == 4) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;

    return GestureDetector(
      onTap: widget.focusNode.requestFocus,
      child: Stack(
        children: [
          Row(
            children: [
              for (var index = 0; index < 4; index++) ...[
                Expanded(
                  child: _OtpBox(
                    value: index < value.length ? value[index] : '',
                    active: widget.focusNode.hasFocus && index == value.length,
                  ),
                ),
                if (index != 3) const SizedBox(width: 12),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.01,
              child: TextField(
                focusNode: widget.focusNode,
                controller: widget.controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onSubmitted: (_) => widget.onCompleted(),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.value, required this.active});

  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.brandForest : AppColors.borderSubtle,
          width: active ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.brandForest,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GenderPills extends StatelessWidget {
  const _GenderPills({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static const _options = ['Male', 'Female', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in _options) ...[
          Expanded(
            child: _GenderPill(
              label: option,
              selected: selected == option,
              onTap: () => onSelected(option),
            ),
          ),
          if (option != _options.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _GenderPill extends StatelessWidget {
  const _GenderPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandForest : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.brandForest : AppColors.borderSubtle,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.brandForest,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LargeTextField extends StatelessWidget {
  const _LargeTextField({
    required this.focusNode,
    required this.controller,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7E9EF), width: 1.1),
      ),
      alignment: Alignment.center,
      child: TextField(
        focusNode: focusNode,
        controller: controller,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        onSubmitted: onSubmitted,
        autocorrect: false,
        enableSuggestions: false,
        cursorColor: AppColors.brandForest,
        cursorWidth: 1.5,
        style: const TextStyle(
          color: AppColors.brandForest,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        decoration: const InputDecoration(
          hintText: 'Enter your name',
          hintStyle: TextStyle(
            color: Color(0xFF9EA2AE),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          isCollapsed: true,
          filled: false,
          contentPadding: EdgeInsets.symmetric(horizontal: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _AddressStep extends StatefulWidget {
  const _AddressStep({
    required this.accentColor,
    required this.cities,
    required this.selectedCityId,
    required this.onCitySelected,
    required this.onBack,
    required this.onConfirm,
  });

  final Color accentColor;
  final List<City> cities;
  final String? selectedCityId;
  final ValueChanged<String> onCitySelected;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  State<_AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<_AddressStep>
    with SingleTickerProviderStateMixin {
  Offset _mapOffset = Offset.zero;
  late final AnimationController _recenterController;
  Animation<Offset>? _recenterAnimation;

  @override
  void initState() {
    super.initState();
    _recenterController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 420),
        )..addListener(() {
          final animation = _recenterAnimation;
          if (animation == null) return;
          setState(() => _mapOffset = animation.value);
        });
  }

  @override
  void dispose() {
    _recenterController.dispose();
    super.dispose();
  }

  void _dragMap(DragUpdateDetails details) {
    _recenterController.stop();
    setState(() {
      _mapOffset += details.delta;
      _mapOffset = Offset(
        _mapOffset.dx.clamp(-180.0, 180.0),
        _mapOffset.dy.clamp(-220.0, 220.0),
      );
    });
  }

  void _useCurrentLocation() {
    AppHaptics.confirm();
    _recenterAnimation = Tween<Offset>(begin: _mapOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _recenterController,
            curve: Curves.easeOutCubic,
          ),
        );
    _recenterController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: _dragMap,
          child: _LocationMap(
            accentColor: widget.accentColor,
            offset: _mapOffset,
          ),
        ),
        Positioned(
          top: 18,
          left: 14,
          right: 14,
          child: Row(
            children: [
              _FloatingMapButton(onTap: widget.onBack),
              const SizedBox(width: 10),
              const Expanded(child: _SearchAddressBox()),
            ],
          ),
        ),
        Positioned(
          right: 18,
          bottom: 220 + bottomInset,
          child: _CurrentLocationButton(
            accentColor: widget.accentColor,
            onTap: _useCurrentLocation,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _ConfirmLocationSheet(
            accentColor: widget.accentColor,
            bottomInset: bottomInset,
            cities: widget.cities,
            selectedCityId: widget.selectedCityId,
            onCitySelected: widget.onCitySelected,
            onConfirm: widget.onConfirm,
          ),
        ),
      ],
    );
  }
}

class _FloatingMapButton extends StatelessWidget {
  const _FloatingMapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onTap,
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: Color(0xFF9C9C9C),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _SearchAddressBox extends StatelessWidget {
  const _SearchAddressBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(LucideIcons.search, color: Color(0xFFA8A8A8), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search an area or address',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFFA8A8A8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationButton extends StatelessWidget {
  const _CurrentLocationButton({
    required this.accentColor,
    required this.onTap,
  });

  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: const Text(
            'Current Location',
            style: TextStyle(
              color: Color(0xFF303030),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmLocationSheet extends StatelessWidget {
  const _ConfirmLocationSheet({
    required this.accentColor,
    required this.bottomInset,
    required this.cities,
    required this.selectedCityId,
    required this.onCitySelected,
    required this.onConfirm,
  });

  final Color accentColor;
  final double bottomInset;
  final List<City> cities;
  final String? selectedCityId;
  final ValueChanged<String> onCitySelected;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: double.infinity,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Your current location is selected',
              style: TextStyle(
                color: accentColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, color: accentColor, size: 17),
                    const SizedBox(width: 9),
                    Text(
                      'Confirm Location',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Selected location',
                  style: TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Drag the map to place the pin on your service address.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF8B8B8B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                if (cities.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'City',
                    style: TextStyle(
                      color: Color(0xFF262626),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final city in cities)
                        ChoiceChip(
                          label: Text(
                            city.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: city.id == selectedCityId,
                          onSelected: (_) => onCitySelected(city.id),
                          showCheckmark: false,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 17),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
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
}

class _LocationMap extends StatelessWidget {
  const _LocationMap({required this.accentColor, required this.offset});

  final Color accentColor;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _OsmTileBackground(offset: offset),
        Positioned(
          left: 0,
          right: 0,
          top: 338,
          child: _SelectedLocationPin(accentColor: accentColor),
        ),
      ],
    );
  }
}

class _SelectedLocationPin extends StatelessWidget {
  const _SelectedLocationPin({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 17, vertical: 10),
              child: Text(
                'Selected location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          ClipPath(
            clipper: _CalloutPointerClipper(),
            child: Container(width: 18, height: 16, color: accentColor),
          ),
          Container(width: 3, height: 16, color: accentColor),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.24),
                  blurRadius: 14,
                  spreadRadius: 7,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OsmTileBackground extends StatelessWidget {
  const _OsmTileBackground({required this.offset});

  final Offset offset;

  static const _latitude = 19.2836;
  static const _longitude = 72.8727;
  static const _zoom = 16;

  double _longToTileX(double longitude, int zoom) {
    return (longitude + 180) / 360 * math.pow(2, zoom);
  }

  double _latToTileY(double latitude, int zoom) {
    final latRad = latitude * math.pi / 180;
    return (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
        2 *
        math.pow(2, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final centerX = _longToTileX(_longitude, _zoom);
    final centerY = _latToTileY(_latitude, _zoom);
    final originX = centerX.floor() - 2;
    final originY = centerY.floor() - 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSize = math.max(
          constraints.maxWidth / 3.2,
          constraints.maxHeight / 5.4,
        );
        final offsetX =
            constraints.maxWidth / 2 -
            (centerX - originX) * tileSize +
            offset.dx;
        final offsetY =
            constraints.maxHeight * 0.46 -
            (centerY - originY) * tileSize +
            offset.dy;

        return ColoredBox(
          color: const Color(0xFFF1F0F1),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (var row = 0; row < 7; row++)
                for (var col = 0; col < 5; col++)
                  Positioned(
                    left: offsetX + col * tileSize,
                    top: offsetY + row * tileSize,
                    width: tileSize,
                    height: tileSize,
                    child: Image.network(
                      'https://tile.openstreetmap.org/$_zoom/${originX + col}/${originY + row}.png',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) {
                        return const CustomPaint(painter: _MapPreviewPainter());
                      },
                    ),
                  ),
              Positioned.fill(
                child: ColoredBox(color: Colors.white.withValues(alpha: 0.18)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  const _MapPreviewPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFF1F0F1);
    canvas.drawRect(Offset.zero & size, paint);

    final blocks = [
      Rect.fromLTWH(size.width * 0.02, size.height * 0.08, 120, 180),
      Rect.fromLTWH(size.width * 0.28, size.height * 0.03, 160, 150),
      Rect.fromLTWH(size.width * 0.64, size.height * 0.08, 132, 162),
      Rect.fromLTWH(size.width * 0.1, size.height * 0.36, 154, 108),
      Rect.fromLTWH(size.width * 0.58, size.height * 0.36, 156, 116),
      Rect.fromLTWH(size.width * 0.04, size.height * 0.68, 140, 136),
      Rect.fromLTWH(size.width * 0.62, size.height * 0.72, 126, 120),
      Rect.fromLTWH(size.width * 0.28, size.height * 0.58, 126, 150),
    ];

    for (final rect in blocks) {
      paint.color = const Color(0xFFE3E1E3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFD2CDD1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(10), const Radius.circular(4)),
        paint,
      );
      paint.style = PaintingStyle.fill;
    }

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final road = Path()
      ..moveTo(-20, size.height * 0.2)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.28,
        size.width * 0.34,
        size.height * 0.34,
        size.width * 0.52,
        size.height * 0.28,
      )
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.22,
        size.width * 0.78,
        size.height * 0.52,
        size.width + 20,
        size.height * 0.5,
      );
    canvas.drawPath(road, roadPaint);

    roadPaint
      ..color = const Color(0xFFC9C1C7)
      ..strokeWidth = 4;
    canvas.drawPath(road, roadPaint);

    final crossRoad = Path()
      ..moveTo(size.width * 0.24, size.height + 20)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.72,
        size.width * 0.54,
        size.height * 0.62,
        size.width * 0.58,
        -20,
      );
    roadPaint
      ..color = Colors.white
      ..strokeWidth = 26;
    canvas.drawPath(crossRoad, roadPaint);

    roadPaint
      ..color = const Color(0xFFC9C1C7)
      ..strokeWidth = 4;
    canvas.drawPath(crossRoad, roadPaint);

    final sideRoads = [
      Path()
        ..moveTo(-20, size.height * 0.42)
        ..lineTo(size.width + 20, size.height * 0.28),
      Path()
        ..moveTo(-20, size.height * 0.68)
        ..lineTo(size.width + 20, size.height * 0.62),
      Path()
        ..moveTo(size.width * 0.14, -20)
        ..lineTo(size.width * 0.38, size.height + 20),
      Path()
        ..moveTo(size.width * 0.84, -20)
        ..lineTo(size.width * 0.72, size.height + 20),
    ];

    for (final path in sideRoads) {
      roadPaint
        ..color = Colors.white
        ..strokeWidth = 15;
      canvas.drawPath(path, roadPaint);
      roadPaint
        ..color = const Color(0xFFD1CCD0)
        ..strokeWidth = 3;
      canvas.drawPath(path, roadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CalloutPointerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.5, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _NextButton extends StatefulWidget {
  const _NextButton({required this.label, required this.onTap, this.isLoading = false});

  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onTap,
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
            color: AppColors.brandForest,
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
            child: widget.isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
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
