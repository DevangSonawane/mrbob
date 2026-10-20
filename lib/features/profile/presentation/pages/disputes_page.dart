import 'package:flutter/material.dart';

import '../../../../core/models/api/customer_dispute.dart';
import '../../../../core/services/api_exception.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_colors.dart';

class DisputesPage extends StatefulWidget {
  const DisputesPage({super.key});
  @override
  State<DisputesPage> createState() => _DisputesPageState();
}

class _DisputesPageState extends State<DisputesPage> {
  late Future<List<CustomerDispute>> _items = DisputeService.instance.list();
  Future<void> _reload() {
    final request = DisputeService.instance.list();
    setState(() => _items = request);
    return request.then<void>((_) {});
  }

  Future<void> _raise() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => const _RaiseDisputeSheet(),
    );
    if (created == true) await _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: const Text('Help & support'),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.brandForest,
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _raise,
      backgroundColor: AppColors.brandForest,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Raise an issue'),
    ),
    body: FutureBuilder<List<CustomerDispute>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return _Error(message: _message(snapshot.error), onRetry: _reload);
        final items = snapshot.requireData;
        if (items.isEmpty)
          return const Center(child: Text('No help requests or disputes yet.'));
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final item = items[i];
              return Card(
                child: ListTile(
                  title: Text(
                    item.subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${item.reference} • ${item.categoryLabel}\n${item.status} • ${item.messageCount} messages',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DisputeDetailPage(id: item.id),
                      ),
                    );
                    _reload();
                  },
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class _RaiseDisputeSheet extends StatefulWidget {
  const _RaiseDisputeSheet();
  @override
  State<_RaiseDisputeSheet> createState() => _RaiseDisputeSheetState();
}

class _RaiseDisputeSheetState extends State<_RaiseDisputeSheet> {
  late Future<List<DisputeCategory>> _categories = DisputeService.instance
      .categories();
  final _subject = TextEditingController(),
      _description = TextEditingController(),
      _bookingId = TextEditingController();
  String _type = 'DISPUTE';
  String? _category;
  bool _saving = false;
  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    _bookingId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_category == null ||
        _subject.text.trim().isEmpty ||
        _description.text.trim().isEmpty)
      return;
    setState(() => _saving = true);
    try {
      await DisputeService.instance.create(
        type: _type,
        category: _category!,
        subject: _subject.text,
        description: _description.text,
        bookingId: _bookingId.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: FutureBuilder<List<DisputeCategory>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          if (snapshot.hasError)
            return _Error(
              message: _message(snapshot.error),
              onRetry: () => setState(
                () => _categories = DisputeService.instance.categories(),
              ),
            );
          final categories = snapshot.requireData;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How can we help?',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Request type'),
                items: const [
                  DropdownMenuItem(value: 'HELP', child: Text('Ask for help')),
                  DropdownMenuItem(
                    value: 'DISPUTE',
                    child: Text('Raise a dispute'),
                  ),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'What is this about?',
                ),
                items: categories
                    .map(
                      (c) =>
                          DropdownMenuItem(value: c.key, child: Text(c.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subject,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Describe the issue',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bookingId,
                decoration: const InputDecoration(
                  labelText: 'Booking ID (optional)',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving || _category == null ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandForest,
                  foregroundColor: Colors.white,
                ),
                child: Text(_saving ? 'Submitting…' : 'Submit'),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class DisputeDetailPage extends StatefulWidget {
  const DisputeDetailPage({super.key, required this.id});
  final String id;
  @override
  State<DisputeDetailPage> createState() => _DisputeDetailPageState();
}

class _DisputeDetailPageState extends State<DisputeDetailPage> {
  late Future<CustomerDispute> _future = DisputeService.instance.get(widget.id);
  final _reply = TextEditingController();
  bool _sending = false;
  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _set(CustomerDispute value) =>
      setState(() => _future = Future.value(value));
  Future<void> _send(CustomerDispute item) async {
    if (_reply.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final next = await DisputeService.instance.reply(item.id, _reply.text);
      _reply.clear();
      _set(next);
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _close(CustomerDispute item) async {
    try {
      _set(await DisputeService.instance.close(item.id));
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: const Text('Support request'),
      backgroundColor: Colors.white,
    ),
    body: FutureBuilder<CustomerDispute>(
      future: _future,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (s.hasError)
          return _Error(
            message: _message(s.error),
            onRetry: () => setState(
              () => _future = DisputeService.instance.get(widget.id),
            ),
          );
        final item = s.requireData;
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    item.subject,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.reference} • ${item.status}',
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 16),
                  Text(item.description),
                  if (item.resolution != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text('Resolution: ${item.resolution}'),
                    ),
                  const Divider(height: 32),
                  for (final message in item.messages)
                    Align(
                      alignment: message.mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: message.mine
                              ? const Color(0xFFE4F3EA)
                              : const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(message.body),
                      ),
                    ),
                ],
              ),
            ),
            if (item.canReply)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reply,
                          decoration: const InputDecoration(
                            hintText: 'Reply to support',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _sending ? null : () => _send(item),
                        icon: const Icon(
                          Icons.send,
                          color: AppColors.brandForest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (item.canClose)
              TextButton(
                onPressed: () => _close(item),
                child: const Text('Close this request'),
              ),
          ],
        );
      },
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

String _message(Object? error) => error is ApiException
    ? error.message
    : 'Unable to connect to support. Please try again.';
