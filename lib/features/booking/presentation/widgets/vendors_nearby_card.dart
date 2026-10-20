import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/api/nearby_vendors.dart';
import '../../../../core/models/geo_point.dart';
import '../../../../core/services/address_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/nearby_vendors_service.dart';
import '../../../../core/theme/app_colors.dart';

/// "6 vendors nearby — about 12 min", shown before the booking is placed.
///
/// The estimate comes from `GET /customer/nearby-vendors`, which counts
/// approved vendors that are online within ~5 km of the address and that
/// offer the requested service. It is informational only: when nobody is
/// around the booking still goes through and is opened to all vendors.
///
/// The card hides itself when no position is available, because a nearby
/// count without a position would be a guess.
class VendorsNearbyCard extends StatefulWidget {
  const VendorsNearbyCard({
    super.key,
    this.categoryId,
    this.point,
    this.margin = const EdgeInsets.only(top: 22, bottom: 22),
    this.nearbyService,
    this.addressService,
  });

  /// The service the customer is booking — only vendors offering it are
  /// counted.
  final String? categoryId;

  /// A pre-resolved position. When null the card resolves the saved
  /// address, then falls back to the device position.
  final GeoPoint? point;

  /// Spacing around the card. It collapses with the card when there is
  /// nothing to show.
  final EdgeInsetsGeometry margin;

  /// Overridable for tests.
  final NearbyVendorsService? nearbyService;

  /// Overridable for tests.
  final AddressService? addressService;

  @override
  State<VendorsNearbyCard> createState() => _VendorsNearbyCardState();
}

class _VendorsNearbyCardState extends State<VendorsNearbyCard> {
  NearbyVendors? _nearby;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant VendorsNearbyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId ||
        oldWidget.point != widget.point) {
      _load();
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }

    final point = widget.point ?? await _resolvePoint();
    if (point == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

    try {
      final nearby = await (widget.nearbyService ?? NearbyVendorsService.instance)
          .nearby(
            latitude: point.latitude,
            longitude: point.longitude,
            categoryId: widget.categoryId,
          );
      if (!mounted) return;
      setState(() {
        _nearby = nearby;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  /// The position to search around: the saved address, then the device.
  Future<GeoPoint?> _resolvePoint() async {
    try {
      final address = await (widget.addressService ?? AddressService.instance)
          .defaultAddress();
      if (address != null && address.hasLocation) {
        return GeoPoint(
          latitude: address.latitude!,
          longitude: address.longitude!,
        );
      }
    } catch (_) {
      // Fall through to the device position.
    }

    try {
      return await LocationService.instance.currentPosition().timeout(
        const Duration(seconds: 8),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (content == null) {
      return const SizedBox.shrink();
    }
    return Padding(padding: widget.margin, child: content);
  }

  /// The card content, or null when there is nothing worth showing.
  Widget? _buildContent() {
    if (_loading) {
      return _card(
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Checking professionals near you…',
                style: _subtitleStyle,
              ),
            ),
          ],
        ),
      );
    }

    if (_failed || _nearby == null) {
      return null;
    }

    final nearby = _nearby!;
    if (!nearby.hasVendors) {
      return _card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _leading(
              icon: LucideIcons.clock,
              background: AppColors.surfaceTint,
              foreground: const Color(0xFF8A5A00),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vendors are busy right now', style: _titleStyle),
                  const SizedBox(height: 3),
                  Text(
                    "We'll find one for you — place the booking anyway.",
                    style: _subtitleStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final eta = nearby.etaLabel;
    final distance = nearby.distanceLabel;

    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _leading(
            icon: LucideIcons.users,
            background: AppColors.brandForest.withValues(alpha: 0.06),
            foreground: AppColors.brandForest,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${nearby.vendorsNearby} '
                  '${nearby.vendorsNearby == 1 ? 'vendor' : 'vendors'} nearby',
                  style: _titleStyle,
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (eta != null) 'About $eta',
                    ?distance,
                  ].join(' · '),
                  style: _subtitleStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: child,
    );
  }

  Widget _leading({
    required IconData icon,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: foreground, size: 18),
    );
  }

  static const _titleStyle = TextStyle(
    color: AppColors.brandForest,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const _subtitleStyle = TextStyle(
    color: AppColors.mutedText,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );
}
