import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/simple_page.dart';
import '../../../../shared/widgets/support_tile.dart';
import '../../../refer/presentation/pages/refer_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';
import '../widgets/coupon_card.dart';

/// Account page in the Trumarkz org-profile-settings language:
/// title header, centered avatar + name, 2-column action cards and a
/// grouped "Manage Account" card — with MrBob content and brand accents.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const double _referenceWidth = 402;

  void _openManageAccount(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageAccountPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxWidth / _referenceWidth).clamp(
              0.0,
              1.0,
            );
            double s(double v) => v * scale;

            return _ProfileScaleScope(
              scale: scale,
              child: Column(
                children: [
                  // ---- Title header (tab page: no back chevron) ----
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.fromLTRB(s(20), s(18), s(20), s(6)),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Account',
                      style: TextStyle(
                        color: AppColors.brandForest,
                        fontSize: s(23),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  SizedBox(height: s(8)),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(s(20)),
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          s(16),
                          s(8),
                          s(16),
                          112 + bottomInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProfileHeader(
                              displayName: 'Aarav Mehta',
                              onEdit: () => _openManageAccount(context),
                              onStatusTap: () =>
                                  _showAccountStatusPopup(context),
                            ),
                            SizedBox(height: s(24)),
                            _AccountActionGrid(
                              onBookings: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StaticInfoPage(
                                    title: 'My bookings',
                                    icon: Icons.receipt_long_rounded,
                                  ),
                                ),
                              ),
                              onWallet: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WalletPage(),
                                ),
                              ),
                              onOffers: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OffersPage(),
                                ),
                              ),
                              onRefer: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReferPage(),
                                ),
                              ),
                            ),
                            SizedBox(height: s(24)),
                            _ManageAccountSection(
                              onHelp: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HelpSupportPage(),
                                ),
                              ),
                              onAddress: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SavedAddressPage(),
                                ),
                              ),
                              onSettings: () => _openManageAccount(context),
                            ),
                            SizedBox(height: s(36)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void _showAccountStatusPopup(BuildContext context) {
  Widget statusRow(String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF16A34A),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withAlpha(60),
    builder: (dialogContext) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 260,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2F3336).withAlpha(200),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(60), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  statusRow('Phone number'),
                  const SizedBox(height: 14),
                  statusRow('Email'),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ProfileScaleScope extends InheritedWidget {
  const _ProfileScaleScope({required this.scale, required super.child});

  final double scale;

  static double of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_ProfileScaleScope>();
    return scope?.scale ?? 1.0;
  }

  @override
  bool updateShouldNotify(_ProfileScaleScope oldWidget) =>
      oldWidget.scale != scale;
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.onEdit,
    required this.onStatusTap,
  });

  final String displayName;
  final VoidCallback onEdit;
  final VoidCallback onStatusTap;

  @override
  Widget build(BuildContext context) {
    final scale = _ProfileScaleScope.of(context);
    double s(double v) => v * scale;
    final avatarSize = s(72);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: const BoxDecoration(
                color: Color(0xFF02462E),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.person_rounded,
                size: s(34),
                color: Colors.white,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: onStatusTap,
                child: Container(
                  width: s(24),
                  height: s(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.verified_rounded,
                    size: s(15),
                    color: AppColors.brandForest,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: s(16)),
        GestureDetector(
          onTap: onEdit,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: 0,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: s(24),
                  color: AppColors.mutedText,
                ),
              ),
              Flexible(
                child: Text(
                  displayName,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: s(20),
                    fontWeight: FontWeight.w700,
                    height: 28 / 20,
                    color: AppColors.brandForest,
                  ),
                ),
              ),
              SizedBox(width: s(2)),
              Icon(
                Icons.chevron_right_rounded,
                size: s(24),
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountActionGrid extends StatelessWidget {
  const _AccountActionGrid({
    required this.onBookings,
    required this.onWallet,
    required this.onOffers,
    required this.onRefer,
  });

  final VoidCallback onBookings;
  final VoidCallback onWallet;
  final VoidCallback onOffers;
  final VoidCallback onRefer;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _AccountActionCard(
          icon: Icons.receipt_long_rounded,
          title: 'My bookings',
          subtitle: 'View all bookings',
          onTap: onBookings,
        ),
        _AccountActionCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'My wallet',
          subtitle: 'Check balance',
          onTap: onWallet,
        ),
        _AccountActionCard(
          icon: Icons.local_offer_rounded,
          title: 'Offers & coupons',
          subtitle: 'Grab the deals',
          onTap: onOffers,
        ),
        _AccountActionCard(
          icon: Icons.card_giftcard_rounded,
          title: 'Refer & earn',
          subtitle: 'Earn rewards',
          onTap: onRefer,
        ),
      ],
    );
  }
}

class _AccountActionCard extends StatelessWidget {
  const _AccountActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = _ProfileScaleScope.of(context);
    double s(double v) => v * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s(24)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(s(24)),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(s(24)),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(s(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: s(40),
                    height: s(40),
                    decoration: const BoxDecoration(
                      color: Color(0xFF02462E),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: s(22), color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: s(16),
                      fontWeight: FontWeight.w700,
                      height: 22 / 16,
                      color: AppColors.brandForest,
                    ),
                  ),
                  SizedBox(height: s(4)),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: s(13),
                            fontWeight: FontWeight.w500,
                            height: 18 / 13,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: s(20),
                        color: AppColors.mutedText,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManageAccountSection extends StatelessWidget {
  const _ManageAccountSection({
    required this.onHelp,
    required this.onAddress,
    required this.onSettings,
  });

  final VoidCallback onHelp;
  final VoidCallback onAddress;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final scale = _ProfileScaleScope.of(context);
    double s(double v) => v * scale;

    final rows = [
      _ManageRowData(
        title: 'Help & support',
        icon: Icons.support_agent_rounded,
        onTap: onHelp,
      ),
      _ManageRowData(
        title: 'Saved addresses',
        icon: Icons.bookmark_rounded,
        onTap: onAddress,
      ),
      _ManageRowData(
        title: 'Account settings',
        icon: Icons.manage_accounts_rounded,
        onTap: onSettings,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage Account',
          style: TextStyle(
            fontSize: s(16),
            fontWeight: FontWeight.w500,
            height: 22 / 16,
            color: AppColors.mutedText,
          ),
        ),
        SizedBox(height: s(14)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(s(16)),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int index = 0; index < rows.length; index++) ...[
                _ManageAccountRow(data: rows[index]),
                if (index != rows.length - 1)
                  const Divider(height: 1, color: AppColors.borderSubtle),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ManageRowData {
  const _ManageRowData({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class _ManageAccountRow extends StatelessWidget {
  const _ManageAccountRow({required this.data});

  final _ManageRowData data;

  @override
  Widget build(BuildContext context) {
    final scale = _ProfileScaleScope.of(context);
    double s(double v) => v * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(s(16), s(15), s(14), s(15)),
          child: Row(
            children: [
              Container(
                width: s(34),
                height: s(34),
                decoration: const BoxDecoration(
                  color: Color(0xFF02462E),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(data.icon, size: s(19), color: Colors.white),
              ),
              SizedBox(width: s(14)),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: s(15),
                    fontWeight: FontWeight.w700,
                    height: 20 / 15,
                    color: AppColors.brandForest,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: s(24),
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimplePage(
      title: 'Offers and coupons',
      children: const [
        CouponCard(
          code: 'MOVEIN20',
          title: '20% off first repair',
          body: 'Valid on bookings above Rs 699.',
        ),
        CouponCard(
          code: 'FIXFAST',
          title: 'Free instant fee',
          body: 'Use on urgent plumbing and electrical fixes.',
        ),
        CouponCard(
          code: 'PAINT100',
          title: 'Rs 100 wallet cashback',
          body: 'For painting repair bookings this week.',
        ),
      ],
    );
  }
}

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimplePage(
      title: 'Help and support',
      children: const [
        SupportTile(
          icon: Icons.chat_rounded,
          title: 'Chat with support',
          body: 'Average response under 2 minutes',
        ),
        SupportTile(
          icon: Icons.warning_rounded,
          title: 'Report safety issue',
          body: 'Priority escalation for damage, theft or misconduct',
        ),
        SupportTile(
          icon: Icons.receipt_rounded,
          title: 'Invoice request',
          body: 'Get GST invoice for completed bookings',
        ),
        SupportTile(
          icon: Icons.undo_rounded,
          title: 'Refunds and cancellations',
          body: 'Track wallet refunds and cancellation fees',
        ),
      ],
    );
  }
}

class SavedAddressPage extends StatelessWidget {
  const SavedAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimplePage(
      title: 'Saved address',
      children: const [
        SupportTile(
          icon: Icons.home_rounded,
          title: 'Green Heights',
          body: 'A-1204, Tower A, Andheri East, Mumbai',
        ),
        SupportTile(
          icon: Icons.apartment_rounded,
          title: 'Site office',
          body: 'Plot 18, Sector 62, Noida',
        ),
      ],
    );
  }
}

class ManageAccountPage extends StatelessWidget {
  const ManageAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimplePage(
      title: 'Manage account',
      children: const [
        SupportTile(
          icon: Icons.person_rounded,
          title: 'Personal details',
          body: 'Name, email and phone number',
        ),
        SupportTile(
          icon: Icons.lock_rounded,
          title: 'Login and security',
          body: 'OTP, Google login and device sessions',
        ),
        SupportTile(
          icon: Icons.notifications_rounded,
          title: 'Notification preferences',
          body: 'Booking alerts, offers and reminders',
        ),
        SupportTile(
          icon: Icons.delete_outline_rounded,
          title: 'Delete account',
          body: 'Request permanent account deletion',
        ),
      ],
    );
  }
}

class StaticInfoPage extends StatelessWidget {
  const StaticInfoPage({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SimplePage(
      title: title,
      children: [
        SupportTile(
          icon: icon,
          title: title,
          body: 'Open this from the bottom navigation for live booking data.',
        ),
      ],
    );
  }
}
