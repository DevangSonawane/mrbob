import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/api/zone_models.dart';
import '../../../../core/models/geo_point.dart';
import '../../../../core/services/api_exception.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/catalog_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/osm_map_picker.dart';
import '../../../shell/presentation/pages/main_shell.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key, required this.phone});

  /// Phone number captured on the login sheet, in E.164 form
  /// ('+91…'). Sent to OTP verify and, for first-time logins,
  /// to customer onboarding.
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
  /// `/customer-onboarding/address`, so the address step lets the
  /// customer pick theirs.
  List<City> _cities = const [];
  String? _selectedCityId;

  /// Where the customer dropped the address pin. H3 dispatch matches the
  /// booking inside the hexagon that contains it, so the onboarding
  /// address is saved with these coordinates.
  GeoPoint? _pinPoint;

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

  /// Step 1: verifies the customer OTP. Creates the user on
  /// first login; returning customers skip straight in.
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      AppHaptics.press();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter the 4-digit code')));
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final session = await AuthService.instance.verifyOtp(widget.phone, otp);
      AppHaptics.confirm();

      final onboarded = session.user.isOnboarded || await _fetchOnboarded();
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
      final message = _customerOtpErrorMessage(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  String _customerOtpErrorMessage(ApiException e) {
    final lower = e.message.toLowerCase();
    final isProviderNumber =
        e.statusCode == 403 &&
        (lower.contains('provider') ||
            lower.contains('professional') ||
            lower.contains('vendor'));
    if (isProviderNumber) {
      return 'This number is registered as a service provider. Use a customer phone number.';
    }
    return e.message;
  }

  Future<bool> _fetchOnboarded() async {
    try {
      final status = await OnboardingService.instance.getStatus();
      return status.isOnboarded;
    } on ApiException catch (_) {
      return false;
    }
  }

  /// Final onboarding step: saves the profile and default
  /// service address.
  Future<void> _completeOnboarding({bool includeSelectedAddress = true}) async {
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
        gender: _gender,
        address: includeSelectedAddress
            ? OnboardingService.defaultClientAddress
            : null,
        latitude: _pinPoint?.latitude,
        longitude: _pinPoint?.longitude,
      );
      AppHaptics.success();
      _enterApp();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
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

  Future<void> _skipLocation() async {
    AppHaptics.press();
    await _completeOnboarding(includeSelectedAddress: false);
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
                          onPinChanged: (point) =>
                              setState(() => _pinPoint = point),
                          onBack: _back,
                          onSkip: _skipLocation,
                          onConfirm: _next,
                          isSubmitting: _isOnboarding,
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
    required this.onPinChanged,
    required this.onBack,
    required this.onSkip,
    required this.onConfirm,
    required this.isSubmitting,
  });

  final Color accentColor;
  final List<City> cities;
  final String? selectedCityId;
  final ValueChanged<String> onCitySelected;

  /// Called with the position the customer dropped the pin on.
  final ValueChanged<GeoPoint> onPinChanged;

  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onConfirm;
  final bool isSubmitting;

  @override
  State<_AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<_AddressStep> {
  /// Where the pin starts — the customer's city centre.
  static const _initialPoint = GeoPoint(latitude: 19.0636, longitude: 72.83);

  late GeoPoint _point = _initialPoint;
  bool _locating = false;

  /// Drops the pin on the device position.
  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final position = await LocationService.instance.currentPosition();
      if (!mounted) return;
      AppHaptics.confirm();
      setState(() {
        _point = position;
        _locating = false;
      });
      widget.onPinChanged(position);
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(content: Text('Could not read your location.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        OsmMapPicker(
          point: _point,
          onChanged: (point) {
            setState(() => _point = point);
            widget.onPinChanged(point);
          },
          height: null,
          borderRadius: BorderRadius.zero,
          // The confirm sheet covers the bottom of the screen, so the pin
          // sits above it.
          pinAlignment: const Alignment(0, -0.34),
          accentColor: widget.accentColor,
          label: OnboardingService.defaultClientAddress,
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
            isLoading: _locating,
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
            point: _point,
            onCitySelected: widget.onCitySelected,
            onSkip: widget.onSkip,
            onConfirm: widget.onConfirm,
            isSubmitting: widget.isSubmitting,
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
    this.isLoading = false,
  });

  final Color accentColor;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
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
    required this.point,
    required this.onCitySelected,
    required this.onSkip,
    required this.onConfirm,
    required this.isSubmitting,
  });

  final Color accentColor;
  final double bottomInset;
  final List<City> cities;
  final String? selectedCityId;

  /// Where the pin sits — saved with the address so the booking can be
  /// matched against the professionals nearby.
  final GeoPoint point;

  final ValueChanged<String> onCitySelected;
  final VoidCallback onSkip;
  final VoidCallback onConfirm;
  final bool isSubmitting;

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
                  OnboardingService.defaultClientAddress,
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
                const SizedBox(height: 4),
                Text(
                  '${point.roundedLatitude}, ${point.roundedLongitude}',
                  style: const TextStyle(
                    color: Color(0xFF8B8B8B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
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
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: isSubmitting ? null : onSkip,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentColor,
                            side: BorderSide(
                              color: accentColor.withValues(alpha: 0.34),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: isSubmitting ? null : onConfirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Confirm Location',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
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
        ],
      ),
    );
  }
}


class _NextButton extends StatefulWidget {
  const _NextButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

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
