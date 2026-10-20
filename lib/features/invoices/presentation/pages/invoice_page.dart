import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:receipt_printer/receipt_printer.dart';

import '../../../../core/models/api/invoice.dart';
import '../../../../core/services/api_exception.dart';
import '../../../../core/services/invoice_service.dart';

const _navy = Color(0xFF15202B);
const _muted = Color(0xFF6C7785);
const _mint = Color(0xFF20A46A);

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  late Future<Invoice> _invoice = _load();
  bool _isDownloading = false;
  ReceiptPrinterStage _printStage = ReceiptPrinterStage.processing;
  bool _didStartPrint = false;

  void _startPrint() {
    if (_didStartPrint) return;
    _didStartPrint = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _printStage = ReceiptPrinterStage.printing);
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _printStage = ReceiptPrinterStage.complete);
      });
    });
  }

  Future<Invoice> _load() =>
      InvoiceService.instance.getForBooking(widget.bookingId);

  Future<void> _download(Invoice invoice) async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await InvoiceService.instance.downloadPdf(widget.bookingId);
      await FileSaver.instance.saveFile(
        name: invoice.invoiceNumber.isEmpty ? 'invoice' : invoice.invoiceNumber,
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice PDF downloaded.')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not download the invoice PDF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F5F7),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF3F5F7),
      title: const Text('Invoice'),
    ),
    body: FutureBuilder<Invoice>(
      future: _invoice,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _error(snapshot.error);
        final invoice = snapshot.requireData;
        _startPrint();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 352,
                child: ReceiptPrinter(
                  key: ValueKey(invoice.invoiceNumber),
                  preset: ReceiptPrinterPreset.modern,
                  stage: _printStage,
                  child: ReceiptPaper(child: _Receipt(invoice: invoice)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _isDownloading ? null : () => _download(invoice),
              icon: _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.download),
              label: Text(_isDownloading ? 'Downloading…' : 'Download PDF'),
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _error(Object? error) {
    final message = error is ApiException && error.statusCode == 404
        ? 'Your invoice is not available yet.'
        : error is ApiException
        ? error.message
        : 'Could not load this invoice.';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          TextButton(
            onPressed: () => setState(() => _invoice = _load()),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .06),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFE2F6EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.receiptText, color: _mint),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mr Bob Home Services',
                    style: TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Service invoice',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            _StatusPill(paid: invoice.isPaid),
          ],
        ),
        const SizedBox(height: 26),
        const Text(
          'TOTAL AMOUNT',
          style: TextStyle(
            color: _muted,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _money(invoice.total),
          style: const TextStyle(
            color: _navy,
            fontWeight: FontWeight.w800,
            fontSize: 34,
          ),
        ),
        const SizedBox(height: 4),
        Text(invoice.invoiceNumber, style: const TextStyle(color: _muted)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Divider(),
        ),
        for (final item in invoice.items)
          _line(item.description, _money(item.amount)),
        const SizedBox(height: 10),
        _line('Subtotal', _money(invoice.subtotal), muted: true),
        _line('Tax', _money(invoice.tax), muted: true),
        if (invoice.payment case final payment?) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _line('Amount paid', _money(payment.amountPaid)),
          if (payment.method != null)
            _line('Payment method', payment.method!, muted: true),
          if (!invoice.isPaid)
            _line('Balance due', _money(invoice.balanceDue), emphasis: true),
        ],
      ],
    ),
  );

  static Widget _line(
    String label,
    String value, {
    bool muted = false,
    bool emphasis = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: muted ? _muted : _navy,
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: emphasis ? _mint : _navy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  static String _money(num amount) => '₹${amount.toStringAsFixed(0)}';
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.paid});
  final bool paid;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: paid ? const Color(0xFFE2F6EC) : const Color(0xFFFFF1D6),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      paid ? 'PAID' : 'DUE',
      style: TextStyle(
        color: paid ? _mint : const Color(0xFFB96B00),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
