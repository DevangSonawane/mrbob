import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/data/services_data.dart';
import '../../../../core/models/booking.dart';
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
  final bookings = <Booking>[
    Booking(
      service: services.first,
      mode: 'Scheduled',
      slot: 'Today, 4:30 PM',
      payment: 'Pay on delivery',
      total: 648,
      status: BookingStatus.confirmed,
    ),
    Booking(
      service: services[1],
      mode: 'Instant',
      slot: 'ASAP, 20 min',
      payment: 'Pay now',
      total: 498,
      status: BookingStatus.inService,
    ),
    Booking(
      service: services[3],
      mode: 'Scheduled',
      slot: 'Yesterday, 2:00 PM',
      payment: 'Pay on delivery',
      total: 748,
      status: BookingStatus.completed,
    ),
  ];

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
      BookingsPage(bookings: bookings, onBrowse: () => _selectTab(0)),
      const WalletPage(),
      const ProfilePage(),
    ];

    // GlassScaffold (SKILL.md §3, scaffold_nav_demo.dart) owns z-ordering so
    // the floating tab pill always paints above tab bodies, and extends the
    // body behind the bar — tab pages already reserve bottom padding for it.
    return GlassScaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: screens[tab],
      bottomBar: GlassTabBar.bottom(
        selectedIndex: tab,
        onTabSelected: _selectTab,
        tabs: _tabs,
        // Slim metrics: slightly smaller pill, tighter icon rhythm.
        // Safe with icon-only tabs (no label text left to overflow).
        barHeight: 58,
        iconSize: 22,
        spacing: 4,
        horizontalPadding: 16,
        verticalPadding: 16,
        // Apple-style: light tint, real blur + saturation + edge light.
        // Definition comes from refraction and the specular edge — not
        // opacity — so the pill stays liquid over any page.
        settings: LiquidGlassSettings(
          glassColor: Colors.white.withValues(alpha: 0.32),
          blur: 20,
          thickness: 28,
          saturation: 1.7,
          lightIntensity: 0.7,
          ambientStrength: 0.1,
        ),
        selectedIconColor: AppColors.brandForest,
        unselectedIconColor: AppColors.mutedText,
        showIndicator: true,
        // Forest-tinted pill: the default indicator washes out over our
        // white pages, which is why the selection circle kept disappearing.
        indicatorColor: AppColors.brandForest.withValues(alpha: 0.18),
        interactionGlowColor: Colors.transparent,
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

  void _addBooking(Booking booking) {
    AppHaptics.confirm();
    setState(() {
      bookings.insert(0, booking);
      tab = 1;
    });
  }
}
