import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../../../core/data/services_data.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../bookings/presentation/pages/bookings_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;
  final bookings = <Booking>[
    Booking(
      service: services.first,
      mode: 'Scheduled',
      slot: 'Today, 4:30 PM',
      payment: 'Pay on delivery',
      total: 648,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomePage(onBooked: _addBooking),
      BookingsPage(bookings: bookings),
      const WalletPage(),
      const ProfilePage(),
    ];

    // Plain scaffold + custom nav: the drop-in LiquidGlassTabBar's
    // internal pill math misplaces the pill on our compact layout,
    // so the proven custom geometry is back. Bar + pill stay package
    // lenses (refract live backdrop on Impeller, no scaffold needed).
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: screens[tab]),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 10),
              child: _LiquidGlassFallbackNavBar(
                currentIndex: tab,
                onTap: (value) => setState(() => tab = value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addBooking(Booking booking) {
    setState(() {
      bookings.insert(0, booking);
      tab = 1;
    });
  }
}

class _LiquidGlassFallbackNavBar extends StatefulWidget {
  const _LiquidGlassFallbackNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<_LiquidGlassFallbackNavBar> createState() =>
      _LiquidGlassFallbackNavBarState();
}

class _LiquidGlassFallbackNavBarState
    extends State<_LiquidGlassFallbackNavBar>
    with SingleTickerProviderStateMixin {
  double? dragCenterX;

  /// Stretch-and-squash pulse played on the pill while it travels to a
  /// newly tapped tab. Transform-only: the pill's position math below
  /// is untouched.
  late final AnimationController _pillPulse;

  @override
  void initState() {
    super.initState();
    _pillPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void didUpdateWidget(covariant _LiquidGlassFallbackNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex &&
        dragCenterX == null) {
      _pillPulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pillPulse.dispose();
    super.dispose();
  }

  static const _items = [
    _LiquidNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _LiquidNavItem(
      label: 'Bookings',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    _LiquidNavItem(
      label: 'Wallet',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
    ),
    _LiquidNavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final barWidth = (width * 0.68).clamp(236.0, 284.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: barWidth,
        height: 56,
        // Bar capsule + sliding pill are real liquid-glass lenses
        // (package). Drag math, icons and caustic shine unchanged.
        child: Stack(
          children: [
            Positioned.fill(
              child: LiquidGlassLens(
                // Soft-body press response on the bar glass itself:
                // swells under a press, springs back on release.
                // Visual-only: layout and position math unchanged.
                touch: const LiquidGlassTouch(
                  flex: LiquidGlassFlex.pronounced(),
                ),
                style: LiquidGlassStyle(
                  shape: const LiquidGlassShape.continuousRoundedRectangle(
                    cornerRadius: 28,
                  ),
                  appearance: LiquidGlassAppearance(
                    color: Colors.white.withValues(alpha: 0.25),
                    blur: const LiquidGlassBlur(sigmaX: 16, sigmaY: 16),
                    shadow: const LiquidGlassShadow(
                      blur: 14,
                      opacity: 0.22,
                      offset: Offset(0, 14),
                    ),
                  ),
                  refraction: const LiquidGlassRefraction(
                    distortion: 0.1,
                    distortionWidth: 30,
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: _GlassCausticOverlay()),
            LayoutBuilder(
              builder: (context, constraints) {
                const blobSize = 46.0;
                const horizontalPadding = 5.0;
                final iconLaneWidth =
                    (constraints.maxWidth - horizontalPadding * 2) /
                    _items.length;
                final minCenter = horizontalPadding + blobSize / 2;
                final maxCenter =
                    constraints.maxWidth - horizontalPadding - blobSize / 2;
                final selectedCenter =
                    horizontalPadding +
                    iconLaneWidth * widget.currentIndex +
                    iconLaneWidth / 2;
                final centerX = (dragCenterX ?? selectedCenter).clamp(
                  minCenter,
                  maxCenter,
                );
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: dragCenterX == null
                          ? const Duration(milliseconds: 360)
                          : const Duration(milliseconds: 90),
                      curve: dragCenterX == null
                          ? Curves.easeOutCubic
                          : Curves.linearToEaseOut,
                      left: centerX - blobSize / 2,
                      top: 5,
                      width: blobSize,
                      height: blobSize,
                      // Hovering pill: the old blob's recipe through the lens —
                      // milky white core, heavy frost, deep soft shadow —
                      // plus refraction + optical rim.
                      child: AnimatedBuilder(
                        animation: _pillPulse,
                        builder: (_, child) {
                          final t = _pillPulse.value;
                          final kick = 4 * t * (1 - t);
                          return Transform.scale(
                            scaleX: 1 + 0.16 * kick,
                            scaleY: 1 - 0.10 * kick,
                            child: child,
                          );
                        },
                        child: LiquidGlassLens(
                          style: LiquidGlassStyle(
                            shape:
                                const LiquidGlassShape.continuousRoundedRectangle(
                                  cornerRadius: 23,
                                ),
                            appearance: LiquidGlassAppearance(
                              color: Colors.white.withValues(alpha: 0.5),
                              blur: const LiquidGlassBlur(
                                sigmaX: 12,
                                sigmaY: 12,
                              ),
                              shadow: const LiquidGlassShadow(
                                color: Colors.black,
                                blur: 18,
                                opacity: 0.2,
                                offset: Offset(0, 9),
                              ),
                            ),
                            refraction: const LiquidGlassRefraction(
                              distortion: 0.15,
                              distortionWidth: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: (details) => _handleDrag(
                  details.localPosition.dx,
                  constraintsWidth: barWidth,
                ),
                onHorizontalDragUpdate: (details) => _handleDrag(
                  details.localPosition.dx,
                  constraintsWidth: barWidth,
                ),
                onHorizontalDragEnd: (_) =>
                    setState(() => dragCenterX = null),
                onHorizontalDragCancel: () =>
                    setState(() => dragCenterX = null),
                child: Row(
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final selected = widget.currentIndex == index;

                    return Expanded(
                      child: _LiquidGlassTab(
                        item: item,
                        selected: selected,
                        onTap: () => widget.onTap(index),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDrag(double localX, {required double constraintsWidth}) {
    const horizontalPadding = 5.0;
    final laneWidth =
        (constraintsWidth - horizontalPadding * 2) / _items.length;
    final adjustedX = localX + horizontalPadding;
    final clampedX = adjustedX.clamp(
      horizontalPadding + 23,
      constraintsWidth - horizontalPadding - 23,
    );
    final index = ((clampedX - horizontalPadding) / laneWidth).floor().clamp(
      0,
      _items.length - 1,
    );

    setState(() => dragCenterX = clampedX);
    if (index != widget.currentIndex) {
      widget.onTap(index);
    }
  }
}

class _LiquidGlassTab extends StatelessWidget {
  const _LiquidGlassTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _LiquidNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 52,
          child: Icon(
            selected ? item.selectedIcon : item.icon,
            color: selected ? AppColors.brandForest : AppColors.mutedText,
            size: selected ? 24 : 22,
          ),
        ),
      ),
    );
  }
}

class _GlassCausticOverlay extends StatelessWidget {
  const _GlassCausticOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _GlassCausticPainter()));
  }
}

class _GlassCausticPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final highlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.48),
          Colors.white.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.28)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.02,
        size.width * 0.62,
        size.height * 0.10,
        size.width * 0.92,
        size.height * 0.22,
      );
    canvas.drawPath(path, highlight);

    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.66,
        -size.height * 0.28,
        size.width * 0.28,
        size.height * 0.72,
      ),
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LiquidNavItem {
  const _LiquidNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
