import 'package:flutter/material.dart';

import '../../../../core/models/booking.dart';
import '../../../../core/theme/app_colors.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key, required this.bookings});

  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My bookings')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: booking.service.color,
                child: Icon(booking.service.icon, color: AppColors.brandForest),
              ),
              title: Text(
                booking.service.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                '${booking.mode} - ${booking.slot}\n${booking.payment} - OTP 4821',
              ),
              isThreeLine: true,
              trailing: Text(
                'Rs ${booking.total}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemCount: bookings.length,
      ),
    );
  }
}
