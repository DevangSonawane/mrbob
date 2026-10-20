import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/geo_point.dart';
import '../../core/theme/app_colors.dart';

/// A draggable OpenStreetMap pin.
///
/// The pin stays centred and the map moves under it, the way every map
/// app behaves. The resulting coordinates are real, so they can be saved
/// on an address and matched by H3 dispatch — a decorative map would
/// silently send every booking to "open to all vendors".
///
/// Tiles come from the public OpenStreetMap tile server, the same source
/// the onboarding map already uses.
class OsmMapPicker extends StatefulWidget {
  const OsmMapPicker({
    super.key,
    required this.point,
    required this.onChanged,
    this.zoom = 16,
    this.height = 240,
    this.pinAlignment = Alignment.center,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppColors.radiusCard),
    ),
    this.accentColor = AppColors.brandForest,
    this.label,
  });

  /// Where the pin starts.
  final GeoPoint point;

  /// Called with the new position when the customer drops the pin.
  final ValueChanged<GeoPoint> onChanged;

  final int zoom;

  /// Height of the map. Null makes it fill the space it is given.
  final double? height;

  /// Where the pin sits inside the map. The geographic centre of the
  /// tiles always follows the pin, whatever the alignment is.
  final Alignment pinAlignment;

  /// Corner rounding of the map surface.
  final BorderRadius borderRadius;

  final Color accentColor;

  /// Optional caption shown in the pin callout.
  final String? label;

  @override
  State<OsmMapPicker> createState() => _OsmMapPickerState();
}

class _OsmMapPickerState extends State<OsmMapPicker> {
  static const int _tileColumns = 5;
  static const int _tileRows = 7;

  /// Metres per pixel at zoom 0, used for the pan -> degrees conversion.
  static const double _earthCircumference = 156543.03392;

  /// The centre the rendered tiles are anchored on.
  late GeoPoint _center;

  /// Live translation of the tile layer while the customer drags.
  Offset _drag = Offset.zero;

  /// Gesture bookkeeping.
  Offset? _startPosition;
  Offset _dragAtStart = Offset.zero;
  GeoPoint? _anchorPoint;

  /// The last position handed to [OsmMapPicker.onChanged], so a parent
  /// rebuild does not fight the gesture.
  GeoPoint? _emitted;

  @override
  void initState() {
    super.initState();
    _center = widget.point;
    _emitted = widget.point;
  }

  @override
  void didUpdateWidget(covariant OsmMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_anchorPoint != null) {
      // A gesture is running — the parent cannot move the pin now.
      return;
    }
    if (widget.point != _emitted) {
      setState(() {
        _center = widget.point;
        _drag = Offset.zero;
        _emitted = widget.point;
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    _startPosition = details.localPosition;
    _dragAtStart = _drag;
    _anchorPoint = _center;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final start = _startPosition;
    if (start == null) return;
    setState(() {
      _drag = _dragAtStart + (details.localPosition - start);
    });
  }

  void _onPanEnd() {
    final anchor = _anchorPoint;
    final start = _startPosition;
    _startPosition = null;
    _anchorPoint = null;
    if (anchor == null || start == null) return;

    final total = _drag - _dragAtStart;
    if (total.distance < 2) {
      setState(() => _drag = Offset.zero);
      return;
    }

    final moved = _pointAfterPan(anchor, total);
    setState(() {
      _center = moved;
      _drag = Offset.zero;
      _emitted = moved;
    });
    widget.onChanged(moved);
  }

  /// Converts a pixel drag into a new centre.
  ///
  /// Dragging the map down moves the view north, dragging it right moves
  /// the view west — the same way the content follows the finger.
  GeoPoint _pointAfterPan(GeoPoint anchor, Offset drag) {
    final metersPerPixel = _metersPerPixel(anchor.latitude);
    final latDelta = (drag.dy * metersPerPixel) / 111320;
    final cosLat = math.cos(anchor.latitude * math.pi / 180);
    final safeCos = cosLat.abs() < 0.01 ? 0.01 : cosLat;
    final lngDelta = (drag.dx * metersPerPixel) / (111320 * safeCos);
    return GeoPoint(
      latitude: (anchor.latitude + latDelta).clamp(-90.0, 90.0),
      longitude: _wrapLongitude(anchor.longitude - lngDelta),
    );
  }

  double _metersPerPixel(double latitude) {
    final cosLat = math.cos(latitude * math.pi / 180).abs();
    return _earthCircumference * cosLat / math.pow(2, widget.zoom);
  }

  static double _wrapLongitude(double value) {
    var longitude = value;
    while (longitude > 180) {
      longitude -= 360;
    }
    while (longitude < -180) {
      longitude += 360;
    }
    return longitude;
  }

  double _lonToTileX(double longitude) =>
      (longitude + 180) / 360 * math.pow(2, widget.zoom);

  double _latToTileY(double latitude) {
    final latRad = latitude * math.pi / 180;
    return (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
        2 *
        math.pow(2, widget.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final map = ClipRRect(
      borderRadius: widget.borderRadius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = _lonToTileX(_center.longitude);
          final centerY = _latToTileY(_center.latitude);
          final originX = centerX.floor() - (_tileColumns ~/ 2);
          final originY = centerY.floor() - (_tileRows ~/ 2);
          final tileSize = math.max(
            constraints.maxWidth / _tileColumns,
            constraints.maxHeight / _tileRows,
          );
          // The pin carries the geographic centre, so the tiles are
          // anchored on the pin position and not on the viewport.
          final pinOffset = widget.pinAlignment.alongSize(
            constraints.biggest,
          );
          final offsetX =
              constraints.maxWidth / 2 +
              pinOffset.dx -
              (centerX - originX) * tileSize;
          final offsetY =
              constraints.maxHeight / 2 +
              pinOffset.dy -
              (centerY - originY) * tileSize;

          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: _drag,
                child: ColoredBox(
                  color: const Color(0xFFF1F0F1),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      for (var row = 0; row < _tileRows; row++)
                        for (var col = 0; col < _tileColumns; col++)
                          Positioned(
                            left: offsetX + col * tileSize,
                            top: offsetY + row * tileSize,
                            width: tileSize,
                            height: tileSize,
                            child: Image.network(
                              'https://tile.openstreetmap.org/'
                              '${widget.zoom}/${originX + col}/${originY + row}.png',
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                              gaplessPlayback: true,
                              errorBuilder: (_, _, _) =>
                                  const ColoredBox(color: Color(0xFFF1F0F1)),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              // The pin sits on the geographic centre of the viewport.
              Align(
                alignment: widget.pinAlignment,
                child: _MapPin(
                  accentColor: widget.accentColor,
                  label: widget.label,
                ),
              ),
              // Keep the gesture on top of the tiles, but under the pin.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: (_) => _onPanEnd(),
                  onPanCancel: _onPanEnd,
                ),
              ),
              const Positioned(
                right: 6,
                bottom: 4,
                child: Text(
                  '© OpenStreetMap',
                  style: TextStyle(
                    color: Color(0xFF6B726B),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final height = widget.height;
    if (height == null) {
      return map;
    }
    return SizedBox(height: height, child: map);
  }
}

/// The drop pin, drawn on top of the map.
class _MapPin extends StatelessWidget {
  const _MapPin({required this.accentColor, this.label});

  final Color accentColor;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.trim().isNotEmpty) ...[
          Container(
            constraints: const BoxConstraints(maxWidth: 190),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              label!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 14,
                spreadRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
