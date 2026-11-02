import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/data/booking_mapper.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/services/api_exception.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../bookings/presentation/pages/bookings_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Named-route tag so flows (e.g. post-payment) can pop back to the
  /// existing home shell instead of the auth pages beneath it.
  static const routeName = '/home';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;
  late List<Booking> bookings;
  bool _isLoadingBookings = true;
  Offset? _navPointerDown;
  bool _isNavDragging = false;

  @override
  void initState() {
    super.initState();
    bookings = const [];
    _loadBookings();
  }

  /// `GET /customer/bookings` — the customer's own bookings.
  Future<void> _loadBookings() async {
    if (mounted) {
      setState(() {
        _isLoadingBookings = true;
      });
    }
    try {
      final apiBookings = await BookingService.instance.list();
      if (!mounted) return;
      setState(() {
        bookings = apiBookings.map(mapApiBooking).toList();
        _isLoadingBookings = false;
      });
    } on ApiException catch (_) {
      _clearBookingsLoadingState();
    } catch (_) {
      _clearBookingsLoadingState();
    }
  }

  void _clearBookingsLoadingState() {
    if (!mounted) return;
    setState(() {
      bookings = const [];
      _isLoadingBookings = false;
    });
  }

  /// Icon-only tabs ([GlassTab.label] left null so the icon centers —
  /// text labels overflowed their cells at large system font sizes).
  /// [GlassTab.semanticLabel] keeps screen-reader names.
  static const _tabs = [
    GlassTab(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      semanticLabel: 'Home',
    ),
    GlassTab(
      icon: Icon(Icons.confirmation_number_outlined),
      activeIcon: Icon(Icons.confirmation_number_rounded),
      semanticLabel: 'Bookings',
    ),
    GlassTab(
      icon: Icon(Icons.account_balance_wallet_outlined),
      activeIcon: Icon(Icons.account_balance_wallet_rounded),
      semanticLabel: 'Wallet',
    ),
    GlassTab(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
      semanticLabel: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomePage(onBooked: _addBooking),
      BookingsPage(
        bookings: bookings,
        isLoading: _isLoadingBookings,
        onBrowse: () => _selectTab(0),
        onChanged: _loadBookings,
      ),
      const WalletPage(),
      const ProfilePage(),
    ];

    // GlassScaffold (SKILL.md §3, scaffold_nav_demo.dart) owns z-ordering so
    // the floating tab pill always paints above tab bodies, and extends the
    // body behind the bar — tab pages already reserve bottom padding for it.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Let the page continue through Android's gesture area. This avoids the
      // opaque, platform-coloured strip that otherwise appears below the
      // floating navigation pill.
      value: SystemUiOverlayStyle.dark.copyWith(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
      child: GlassScaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        // No bottom fade: it erased the page before it reached the pill, so
        // the glass only ever sat on flat white and read as a plain card.
        // iOS 26/27 tab bars let content scroll visibly through the glass.
        bottomEdgeFade: false,
        body: screens[tab],
        bottomBar: GlassAdaptiveScope(
          // This is the app's one persistent navigation surface. Give it the
          // full shader renderer so its highlight, edge light and press state
          // behave as a single liquid layer, while the rest of the app stays
          // on the lighter adaptive standard tier.
          minQuality: GlassQuality.premium,
          maxQuality: GlassQuality.premium,
          initialQuality: GlassQuality.premium,
          allowStepUp: false,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) => _navPointerDown = event.position,
            onPointerMove: _updateNavDrag,
            onPointerUp: _endNavDrag,
            onPointerCancel: _endNavDrag,
            child: GlassTabBar.bottom(
              selectedIndex: tab,
              onTabSelected: _selectTab,
              tabs: _tabs,
              // Keep this as one detached, rounded glass "dialog" at the bottom
              // rather than a conventional full-width navigation strip.
              barHeight: 62,
              barBorderRadius: 32,
              iconSize: 22,
              spacing: 6,
              horizontalPadding: 18,
              verticalPadding: 18,
              quality: GlassQuality.premium,
              backgroundQuality: GlassQuality.premium,
              // iOS 26/27 "regular" tab-bar glass on a light page: a faint
              // milky body, light frost, a thick bevel that bends what
              // scrolls beneath, a bright lit rim and a lifted shadow so the
              // pill floats. chromaticAberration drives the prism: an RGB split
              // of what shows through plus a cyan/violet/amber thin-film
              // reflection on the rim. Below ~0.25 it vanishes on a white
              // page, so it sits visibly at rest and blooms on drag.
              settings: LiquidGlassSettings(
                glassColor: Colors.white.withValues(alpha: 0.14),
                blur: 6,
                thickness: 32,
                refractiveIndex: 1.35,
                saturation: 1.8,
                lightIntensity: 0.9,
                ambientRim: 0.25,
                whitenStrength: 0.12,
                shadowElevation: 2.2,
                chromaticAberration: _isNavDragging ? 0.85 : 0.5,
              ),
              // The selection pill is its own lens, and the package zeroes
              // its prism by default; give it the same rainbow rim.
              indicatorSettings: AnimatedGlassIndicator.baseIndicatorSettings
                  .copyWith(chromaticAberration: _isNavDragging ? 0.9 : 0.45),
              selectedIconColor: AppColors.brandForest,
              unselectedIconColor: AppColors.mutedText,
              showIndicator: true,
              // Use the package's calibrated regular material instead of a
              // custom white-card recipe. This preserves adaptive light, blur
              // and fluid morphing as one navigation layer.
              indicatorColor: AppColors.brandForest.withValues(alpha: 0.10),
            ),
          ),
        ),
      ),
    );
  }

  void _selectTab(int value) {
    // Re-tapping the current tab is a no-op, so it stays silent.
    if (value == tab) return;
    // Light impact rather than a selection tick: a page swap is the loudest
    // interaction in the app, and selectionClick is too subtle to feel over
    // the tab bar's own spring animation.
    AppHaptics.press();
    setState(() => tab = value);
  }

  void _updateNavDrag(PointerMoveEvent event) {
    final start = _navPointerDown;
    if (start == null || _isNavDragging) return;
    if ((event.position - start).distance < 6) return;
    setState(() => _isNavDragging = true);
  }

  void _endNavDrag(PointerEvent _) {
    _navPointerDown = null;
    if (!_isNavDragging) return;
    setState(() => _isNavDragging = false);
  }

  void _addBooking(Booking _) {
    AppHaptics.confirm();
    setState(() {
      tab = 1;
    });
    _loadBookings();
  }
}
