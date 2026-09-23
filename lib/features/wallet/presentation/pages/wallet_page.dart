import 'package:flutter/material.dart';

import '../../../../shared/widgets/section_title.dart';
import '../widgets/wallet_balance_card.dart';
import '../widgets/wallet_row.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My wallet')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
        children: const [
          WalletBalanceCard(),
          SizedBox(height: 16),
          SectionTitle('Recent wallet activity'),
          WalletRow(
            title: 'Referral reward',
            subtitle: 'Credited after first booking',
            amount: '+ Rs 150',
          ),
          WalletRow(
            title: 'Painting repair',
            subtitle: 'Used for booking PF-1024',
            amount: '- Rs 80',
          ),
          WalletRow(
            title: 'Signup bonus',
            subtitle: 'Welcome credit',
            amount: '+ Rs 100',
          ),
        ],
      ),
    );
  }
}
