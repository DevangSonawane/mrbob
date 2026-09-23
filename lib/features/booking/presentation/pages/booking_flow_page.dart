import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/booking.dart';
import '../../../../core/models/service_item.dart';
import '../widgets/payment_option.dart';
import '../widgets/price_breakdown.dart';
import 'booking_success_page.dart';

class BookingFlowPage extends StatefulWidget {
  const BookingFlowPage({
    super.key,
    required this.service,
    this.initialMode = 'Instant',
    this.initialSlot = 'ASAP, 20 min',
  });

  final ServiceItem service;
  final String initialMode;
  final String initialSlot;

  @override
  State<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends State<BookingFlowPage> {
  late String mode;
  late String slot;
  String payment = 'Pay now';
  final answers = <int, String>{};

  int get taxes => 49;
  int get instantFee => mode == 'Instant' ? 99 : 0;
  int get total => widget.service.price + taxes + instantFee;

  @override
  void initState() {
    super.initState();
    mode = widget.initialMode;
    slot = widget.initialSlot;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.service.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: widget.service.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.service.icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${widget.service.duration} service from Rs ${widget.service.price}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'When do you need this?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'Instant',
                icon: Icon(LucideIcons.bolt),
                label: Text('Instant'),
              ),
              ButtonSegment(
                value: 'Scheduled',
                icon: Icon(LucideIcons.calendar),
                label: Text('Slot'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (value) {
              setState(() {
                mode = value.first;
                slot = mode == 'Instant' ? 'ASAP, 20 min' : 'Today, 4:30 PM';
              });
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                (mode == 'Instant'
                        ? const [
                            'ASAP, 20 min',
                            'Next available',
                            'Priority queue',
                          ]
                        : const [
                            'Today, 4:30 PM',
                            'Tomorrow, 10:00 AM',
                            'Tomorrow, 2:00 PM',
                            'Fri, 11:30 AM',
                          ])
                    .map(
                      (item) => ChoiceChip(
                        label: Text(item),
                        selected: slot == item,
                        onSelected: (_) => setState(() => slot = item),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 22),
          Text(
            'A few details',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...widget.service.questions.indexed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                minLines: 1,
                maxLines: 2,
                onChanged: (value) => answers[entry.$1] = value,
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.edit3),
                  labelText: entry.$2,
                ),
              ),
            ),
          ),
          Text(
            'Payment',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          PaymentOption(
            title: 'Pay now',
            subtitle: 'UPI, card, wallet. Faster checkout and instant invoice.',
            icon: LucideIcons.creditCard,
            selected: payment == 'Pay now',
            onTap: () => setState(() => payment = 'Pay now'),
          ),
          const SizedBox(height: 10),
          PaymentOption(
            title: 'Pay on delivery',
            subtitle: 'Pay after OTP verification and service completion.',
            icon: LucideIcons.truck,
            selected: payment == 'Pay on delivery',
            onTap: () => setState(() => payment = 'Pay on delivery'),
          ),
          const SizedBox(height: 18),
          PriceBreakdown(
            rows: [
              ('Service charge', widget.service.price),
              if (instantFee > 0) ('Instant booking fee', instantFee),
              ('Taxes and safety fee', taxes),
            ],
            total: total,
          ),
        ],
      ),
      bottomSheet: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rs $total',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text('$mode - $slot', overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  final booking = Booking(
                    service: widget.service,
                    mode: mode,
                    slot: slot,
                    payment: payment,
                    total: total,
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingSuccessPage(booking: booking),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.circleCheck),
                label: const Text('Book'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
