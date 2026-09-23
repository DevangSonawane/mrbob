import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/simple_page.dart';
import '../../../../shared/widgets/support_tile.dart';
import '../../../refer/presentation/pages/refer_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';
import '../widgets/coupon_card.dart';
import '../widgets/profile_tile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.borderSubtle),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: const CircleAvatar(
                backgroundColor: AppColors.surfaceTint,
                foregroundColor: AppColors.brandForest,
                child: Icon(Icons.person_rounded),
              ),
              title: const Text(
                'Aarav Mehta',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.brandForest,
                  letterSpacing: -0.2,
                ),
              ),
              subtitle: const Text(
                '+91 98765 43210 · aarav@mrbob.app',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ProfileTile(
            icon: Icons.receipt_long_rounded,
            title: 'My bookings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StaticInfoPage(
                  title: 'My bookings',
                  icon: Icons.receipt_long_rounded,
                ),
              ),
            ),
          ),
          ProfileTile(
            icon: Icons.account_balance_wallet_rounded,
            title: 'My wallet',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletPage()),
            ),
          ),
          ProfileTile(
            icon: Icons.local_offer_rounded,
            title: 'Offers and coupons',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OffersPage()),
            ),
          ),
          ProfileTile(
            icon: Icons.support_agent_rounded,
            title: 'Help and support',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpSupportPage()),
            ),
          ),
          ProfileTile(
            icon: Icons.bookmark_rounded,
            title: 'Saved address',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedAddressPage()),
            ),
          ),
          ProfileTile(
            icon: Icons.manage_accounts_rounded,
            title: 'Manage account',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageAccountPage()),
            ),
          ),
          ProfileTile(
            icon: Icons.card_giftcard_rounded,
            title: 'Refer and earn',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReferPage()),
            ),
          ),
        ],
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
