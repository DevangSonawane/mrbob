import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
          children: [
            const _Header(),
            const SizedBox(height: 30),
            const _BalanceSummary(),
            const SizedBox(height: 28),
            const Row(
              children: [
                Expanded(
                  child: _WalletAmountCard(title: 'Cash', amount: '1,240'),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _WalletAmountCard(title: 'Bonus', amount: '250'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _AddMoneyCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _AddMoneyPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'My wallet',
      style: TextStyle(
        color: AppColors.brandForest,
        fontSize: 23,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(LucideIcons.wallet, color: AppColors.mutedText, size: 18),
            SizedBox(width: 8),
            Text(
              'Available balance',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                '₹',
                style: TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 23,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ),
            SizedBox(width: 4),
            Text(
              '1,490',
              style: TextStyle(
                color: AppColors.brandForest,
                fontSize: 42,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.2,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WalletAmountCard extends StatelessWidget {
  const _WalletAmountCard({required this.title, required this.amount});

  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Text(
                  '₹',
                  style: TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                amount,
                style: const TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddMoneyCard extends StatelessWidget {
  const _AddMoneyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF02462E),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF02462E).withValues(alpha: 0.16),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Add money',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddMoneyPage extends StatefulWidget {
  const _AddMoneyPage();

  @override
  State<_AddMoneyPage> createState() => _AddMoneyPageState();
}

class _AddMoneyPageState extends State<_AddMoneyPage> {
  int _selectedAmount = 200;
  final _amounts = const [200, 500, 1000, 2000];

  void _selectAmount(int amount) {
    setState(() => _selectedAmount = amount);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.arrowLeft),
                    color: AppColors.mutedText,
                    tooltip: 'Back',
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Add money',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Available balance ₹1,490',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 42, 20, 24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          '₹',
                          style: TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_selectedAmount',
                        style: const TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Row(
                    children: [
                      for (final amount in _amounts)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: amount == _amounts.last ? 0 : 8,
                            ),
                            child: _AmountChip(
                              amount: amount,
                              selected: amount == _selectedAmount,
                              onTap: () => _selectAmount(amount),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Coupon code',
                      prefixIcon: Icon(LucideIcons.ticketPercent),
                      filled: false,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF02462E),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF02462E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Add money',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final int amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        height: 58,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF02462E) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF02462E)
                        : AppColors.borderSubtle,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF02462E,
                            ).withValues(alpha: 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '₹$amount',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.brandForest,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: AppColors.borderSubtle),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
