import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/api/amc_subscription.dart';
import '../../../../core/services/api_exception.dart';
import '../../../../core/services/amc_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';

/// Customer's AMC (annual maintenance contract)
/// subscriptions: list, filter by status, subscribe
/// and cancel — all against `/amc`.
class AmcPage extends StatefulWidget {
  const AmcPage({super.key});

  @override
  State<AmcPage> createState() => _AmcPageState();
}

class _AmcPageState extends State<AmcPage> {
  List<AmcSubscription> _subscriptions = const [];
  bool _isLoading = true;
  bool _isSubscribing = false;
  String? _error;

  int _filterIndex = 0;

  static const _filters = ['All', 'Active', 'Expired', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final subscriptions = await AmcService.instance.list();
      if (!mounted) return;
      setState(() {
        _subscriptions = subscriptions;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  List<AmcSubscription> get _filtered {
    return switch (_filterIndex) {
      1 => _subscriptions.where((s) => s.isActive).toList(),
      2 =>
        _subscriptions.where((s) => s.status.toUpperCase() == 'EXPIRED')
            .toList(),
      3 =>
        _subscriptions.where((s) => s.status.toUpperCase() == 'CANCELLED')
            .toList(),
      _ => _subscriptions,
    };
  }

  /// `POST /amc` — create a subscription.
  Future<void> _subscribe() async {
    setState(() => _isSubscribing = true);
    try {
      await AmcService.instance.create();
      AppHaptics.success();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AMC subscription activated.')),
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }

  /// `POST /amc/{id}/cancel` — cancel a subscription.
  Future<void> _cancel(AmcSubscription subscription) async {
    AppHaptics.confirm();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel AMC?'),
        content: const Text(
          'This cancels the subscription at the end of the current term.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel AMC'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await AmcService.instance.cancel(subscription.id);
      AppHaptics.success();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AMC subscription cancelled.')),
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('AMC plans'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandForest,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
          children: [
            const _Header(),
            const SizedBox(height: 16),
            _SubscribeCard(
              isSubscribing: _isSubscribing,
              onSubscribe: _subscribe,
            ),
            const SizedBox(height: 20),
            _FilterBar(
              filters: _filters,
              selectedIndex: _filterIndex,
              onSelected: (index) {
                AppHaptics.tick();
                setState(() => _filterIndex = index);
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 44),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.brandForest,
                  ),
                ),
              )
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _load)
            else if (filtered.isEmpty)
              const _EmptyState()
            else
              Column(
                children: [
                  for (final subscription in filtered) ...[
                    _SubscriptionCard(
                      subscription: subscription,
                      onCancel: subscription.isActive
                          ? () => _cancel(subscription)
                          : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
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
      'Maintenance plans',
      style: TextStyle(
        color: AppColors.brandForest,
        fontSize: 23,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _SubscribeCard extends StatelessWidget {
  const _SubscribeCard({required this.isSubscribing, required this.onSubscribe});

  final bool isSubscribing;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brandForest,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandForest.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.brandGold,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.shieldCheck,
              color: AppColors.brandForest,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Annual care plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Priority booking, free inspections and discounts on every service.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 40,
            child: FilledButton(
              onPressed: isSubscribing ? null : onSubscribe,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGold,
                foregroundColor: AppColors.brandForest,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: isSubscribing
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brandForest,
                      ),
                    )
                  : const Text(
                      'Subscribe',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return ChoiceChip(
            label: Text(filters[index]),
            selected: selected,
            onSelected: (_) => onSelected(index),
            showCheckmark: false,
            selectedColor: AppColors.brandForest,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.brandForest,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          );
        },
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription, required this.onCancel});

  final AmcSubscription subscription;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: subscription.isActive
                      ? AppColors.surfaceTint
                      : const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.shieldCheck,
                  color: subscription.isActive
                      ? AppColors.brandForest
                      : AppColors.mutedText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.planName ?? 'AMC plan',
                      style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Status: ${subscription.status}',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: subscription.status),
            ],
          ),
          if (subscription.amount != null ||
              subscription.endDate != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 10),
            Row(
              children: [
                if (subscription.amount != null)
                  Expanded(
                    child: _meta(
                      'Value',
                      'Rs ${subscription.amount}',
                    ),
                  ),
                if (subscription.endDate != null)
                  Expanded(
                    child: _meta(
                      'Valid till',
                      '${subscription.endDate!.day}/${subscription.endDate!.month}/${subscription.endDate!.year}',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.brandForest,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final (color, label) = switch (normalized) {
      'ACTIVE' => (const Color(0xFF16A34A), 'Active'),
      'EXPIRED' => (const Color(0xFFB45309), 'Expired'),
      'CANCELLED' => (const Color(0xFFDC2626), 'Cancelled'),
      _ => (AppColors.mutedText, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFF0EDE4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: Color(0xFF9BA09A),
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No AMC plans yet',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Subscribe to a maintenance plan for priority service and savings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
      height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const Icon(
            LucideIcons.wifiOff,
            color: AppColors.mutedText,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandForest,
              side: const BorderSide(color: AppColors.borderSubtle),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
