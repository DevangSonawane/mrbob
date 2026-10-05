import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/api/zone_models.dart';
import '../../../../core/services/api_exception.dart';
import '../../../../core/services/catalog_service.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../shell/presentation/pages/main_shell.dart';

/// Completes customer onboarding (`POST /onboarding/customer`)
/// after email signup. Only the city is required by the
/// backend; name, phone and address are optional profile
/// details.
class CustomerOnboardingPage extends StatefulWidget {
  const CustomerOnboardingPage({
    super.key,
    this.name = '',
    this.phone,
  });

  /// Pre-filled from the signup form when available.
  final String name;
  final String? phone;

  @override
  State<CustomerOnboardingPage> createState() =>
      _CustomerOnboardingPageState();
}

class _CustomerOnboardingPageState extends State<CustomerOnboardingPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  List<City> _cities = const [];
  String? _selectedCityId;
  bool _isLoadingCities = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    if (widget.phone != null) {
      _phoneController.text = widget.phone!;
    }
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await CatalogService.instance.getCities();
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _selectedCityId = cities.isNotEmpty ? cities.first.id : null;
        _isLoadingCities = false;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCities = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cityId = _selectedCityId;
    if (cityId == null) {
      AppHaptics.press();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select your city to continue')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await OnboardingService.instance.completeCustomerOnboarding(
        cityId: cityId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      AppHaptics.success();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: MainShell.routeName),
          builder: (_) => const MainShell(),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 4),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IconButton(
                        onPressed: () {
                          AppHaptics.press();
                          Navigator.pop(context);
                        },
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.brandForest,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Set up your account',
                      style: TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Where do you need service?',
                        style: TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'We match you with verified pros in your city.',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _LabeledField(
                        label: 'Full name',
                        child: TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Aarav Mehta',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Phone number',
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          style: const TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: '98123 45678',
                            prefixIcon: Icon(
                              Icons.phone_iphone_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'City',
                        child: _isLoadingCities
                            ? const SizedBox(
                                height: 52,
                                child: Center(
                                  child: SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.brandForest,
                                    ),
                                  ),
                                ),
                              )
                            : _cities.isEmpty
                                ? const SizedBox(
                                    height: 52,
                                    child: Center(
                                      child: Text(
                                        'No service cities available yet',
                                        style: TextStyle(
                                          color: AppColors.mutedText,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final city in _cities)
                                        ChoiceChip(
                                          label: Text(
                                            city.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          selected:
                                              city.id == _selectedCityId,
                                          onSelected: (_) => setState(
                                            () =>
                                                _selectedCityId = city.id,
                                          ),
                                          showCheckmark: false,
                                        ),
                                    ],
                                  ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Service address (optional)',
                        child: TextField(
                          controller: _addressController,
                          textCapitalization: TextCapitalization.words,
                          maxLines: 2,
                          style: const TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Flat, street, landmark',
                            prefixIcon: Icon(
                              Icons.home_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  12 + bottomInset,
                ),
                child: SizedBox(
                  height: 58,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandForest,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.brandForest,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
