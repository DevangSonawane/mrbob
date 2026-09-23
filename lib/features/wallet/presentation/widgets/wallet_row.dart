import 'package:flutter/material.dart';

class WalletRow extends StatelessWidget {
  const WalletRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet_rounded),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
