import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/api/customer_address.dart';
import '../../../../core/models/api/zone_models.dart';
import '../../../../core/models/geo_point.dart';
import '../../../../core/services/address_service.dart';
import '../../../../core/services/api_exception.dart';
import '../../../../core/services/catalog_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/osm_map_picker.dart';

/// The customer's saved addresses.
///
/// Every address carries a map pin: H3 dispatch drops a booking into the
/// hexagon that contains the address, so an address without a position is
/// opened to all vendors instead of the ones nearby.
class SavedAddressPage extends StatefulWidget {
  const SavedAddressPage({super.key});

  @override
  State<SavedAddressPage> createState() => _SavedAddressPageState();
}

class _SavedAddressPageState extends State<SavedAddressPage> {
  List<CustomerAddress> _addresses = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final addresses = await AddressService.instance.list();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openForm([CustomerAddress? address]) async {
    final saved = await Navigator.push<CustomerAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressFormPage(address: address),
      ),
    );
    if (saved != null) {
      await _load();
    }
  }

  Future<void> _setDefault(CustomerAddress address) async {
    try {
      await AddressService.instance.setDefault(address.id);
      AppHaptics.confirm();
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    }
  }

  Future<void> _delete(CustomerAddress address) async {
    try {
      await AddressService.instance.delete(address.id);
      AppHaptics.press();
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Saved address'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandForest,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: FilledButton(
            onPressed: () => _openForm(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandForest,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Add address',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brandForest),
      );
    }

    if (_addresses.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No saved address yet',
                  style: TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Add the address where the professional should come. '
                  'Pinning it on the map means we can send the nearest '
                  'professional.',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      itemCount: _addresses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final address = _addresses[index];
        return _AddressCard(
          address: address,
          onTap: () => _openForm(address),
          onSetDefault: address.isDefault
              ? null
              : () => _setDefault(address),
          onDelete: () => _delete(address),
        );
      },
    );
  }
}

/// One saved address.
class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onTap,
    required this.onSetDefault,
    required this.onDelete,
  });

  final CustomerAddress address;
  final VoidCallback onTap;
  final VoidCallback? onSetDefault;
  final VoidCallback onDelete;

  IconData get _icon => switch (address.label) {
    'WORK' => LucideIcons.briefcase,
    'OTHER' => LucideIcons.mapPinned,
    _ => LucideIcons.house,
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.brandForest.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _icon,
                  color: AppColors.brandForest,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.label == 'OTHER'
                              ? 'Other'
                              : address.label == 'WORK'
                              ? 'Work'
                              : 'Home',
                          style: const TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceTint,
                              borderRadius: BorderRadius.circular(
                                AppColors.radiusPill,
                              ),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: Color(0xFF8A5A00),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.shortLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          address.hasLocation
                              ? LucideIcons.mapPin
                              : LucideIcons.mapPinOff,
                          color: address.hasLocation
                              ? AppColors.brandForest
                              : AppColors.mutedText,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            address.hasLocation
                                ? 'Location pinned'
                                : 'No location — add a pin to match nearby professionals',
                            style: TextStyle(
                              color: address.hasLocation
                                  ? AppColors.brandForest
                                  : AppColors.mutedText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (onSetDefault != null) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: onSetDefault,
                        child: const Text(
                          'Set as default',
                          style: TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  LucideIcons.trash2,
                  color: AppColors.mutedText,
                  size: 17,
                ),
                tooltip: 'Delete address',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add or edit an address, including the map pin that H3 dispatch
/// matches on.
class AddressFormPage extends StatefulWidget {
  const AddressFormPage({super.key, this.address});

  /// The address being edited. Null creates a new one.
  final CustomerAddress? address;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  /// Where the pin starts when the address has no position yet.
  static const _fallbackPoint = GeoPoint(latitude: 19.0636, longitude: 72.83);

  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();

  List<City> _cities = const [];
  String? _cityId;
  String _label = 'HOME';
  GeoPoint? _point;
  bool _saving = false;
  bool _locating = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    if (address != null) {
      _line1Controller.text = address.line1;
      _line2Controller.text = address.line2 ?? '';
      _landmarkController.text = address.landmark ?? '';
      _stateController.text = address.state;
      _pincodeController.text = address.pincode;
      _phoneController.text = address.contactPhone ?? '';
      _label = address.label;
      _cityId = address.city?.id;
      if (address.hasLocation) {
        _point = GeoPoint(
          latitude: address.latitude!,
          longitude: address.longitude!,
        );
      }
    } else {
      _stateController.text = AddressService.defaultState;
      _pincodeController.text = AddressService.defaultPincode;
    }
    _loadCities();
  }

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _landmarkController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await CatalogService.instance.getCities();
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _cityId ??= cities.isNotEmpty ? cities.first.id : null;
      });
    } on ApiException {
      // The city list is unavailable — the customer can still save, the
      // API will reject the address.
    }
  }

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
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() => _locating = false);
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locating = false);
      _showMessage('Could not read your location.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final line1 = _line1Controller.text.trim();
    final state = _stateController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (line1.length < 5) {
      _showMessage('Enter the house or flat number and the street.');
      return;
    }
    if (_cityId == null) {
      _showMessage('Select your city.');
      return;
    }
    if (state.isEmpty) {
      _showMessage('Enter your state.');
      return;
    }
    if (!RegExp(r'^[1-9]\d{5}$').hasMatch(pincode)) {
      _showMessage('Enter a valid 6-digit pincode.');
      return;
    }

    setState(() => _saving = true);
    try {
      final address = widget.address;
      final phone = _phoneController.text.replaceAll(
        RegExp(r'[^0-9+]'),
        '',
      );
      final saved = address == null
          ? await AddressService.instance.create(
              line1: line1,
              line2: _line2Controller.text,
              landmark: _landmarkController.text,
              cityId: _cityId!,
              state: state,
              pincode: pincode,
              label: _label,
              latitude: _point?.latitude,
              longitude: _point?.longitude,
              contactPhone: phone,
            )
          : await AddressService.instance.update(
              address.id,
              line1: line1,
              line2: _line2Controller.text,
              landmark: _landmarkController.text,
              label: _label,
              cityId: _cityId,
              state: state,
              pincode: pincode,
              latitude: _point?.latitude,
              longitude: _point?.longitude,
              contactPhone: phone,
            );
      if (!mounted) return;
      AppHaptics.success();
      Navigator.pop(context, saved);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save the address.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit address' : 'Add address'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandForest,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          const _FormLabel('Label'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final label in const ['HOME', 'WORK', 'OTHER'])
                ChoiceChip(
                  label: Text(
                    label == 'OTHER' ? 'Other' : _titleCase(label),
                  ),
                  selected: _label == label,
                  showCheckmark: false,
                  onSelected: (_) {
                    AppHaptics.tick();
                    setState(() => _label = label);
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          _TextField(
            controller: _line1Controller,
            label: 'House / flat and street',
            hint: 'A-1204, 4th Cross',
          ),
          const SizedBox(height: 14),
          _TextField(
            controller: _line2Controller,
            label: 'Area or locality',
            hint: 'Andheri West',
          ),
          const SizedBox(height: 14),
          _TextField(
            controller: _landmarkController,
            label: 'Landmark (optional)',
            hint: 'Near the metro station',
          ),
          const SizedBox(height: 18),
          const _FormLabel('City'),
          const SizedBox(height: 8),
          if (_cities.isEmpty)
            const Text(
              'Loading cities…',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final city in _cities)
                  ChoiceChip(
                    label: Text(city.name),
                    selected: city.id == _cityId,
                    showCheckmark: false,
                    onSelected: (_) {
                      AppHaptics.tick();
                      setState(() => _cityId = city.id);
                    },
                  ),
              ],
            ),
          const SizedBox(height: 14),
          _TextField(
            controller: _stateController,
            label: 'State',
            hint: 'Maharashtra',
          ),
          const SizedBox(height: 14),
          _TextField(
            controller: _pincodeController,
            label: 'Pincode',
            hint: '400053',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          const SizedBox(height: 14),
          _TextField(
            controller: _phoneController,
            label: 'Contact phone (optional)',
            hint: '+919812345678',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          const _FormLabel('Pin your location'),
          const SizedBox(height: 6),
          const Text(
            'Drag the map to drop the pin on your service address. We use it '
            'to send the nearest professional.',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OsmMapPicker(
            point: _point ?? _fallbackPoint,
            label: _pointLabel,
            onChanged: (point) => setState(() => _point = point),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _point == null
                      ? 'No location set'
                      : '${_point!.roundedLatitude}, '
                            '${_point!.roundedLongitude}',
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.locateFixed, size: 16),
                label: const Text('Use my location'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandForest,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandForest,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditing ? 'Save changes' : 'Save address',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String? get _pointLabel {
    final line1 = _line1Controller.text.trim();
    if (line1.isEmpty) return null;
    return line1;
  }

  static String _titleCase(String value) =>
      '${value[0]}${value.substring(1).toLowerCase()}';
}

/// Section label above a group of fields.
class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.brandForest,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// A text field on the app's input decoration theme.
class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}
