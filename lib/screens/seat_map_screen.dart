import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bus_models.dart';
import '../state/bus_state.dart';
import 'book_seat_screen.dart';
import 'booking_details_screen.dart';

class SeatMapScreen extends StatelessWidget {
  const SeatMapScreen({super.key});

  void showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _onSeatTap(BuildContext context, Seat seat) async {
    final bus = context.read<BusState>(); // read BEFORE any await

    // taken seat: open its details
    if (seat.isTaken) {
      final name = seat.passenger!.name;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingDetailsScreen(seat: seat),
        ),
      );
      if (!context.mounted) return;
      if (result == true) {
        await bus.cancel(seat.number);
        if (!context.mounted) return;
        showMessage(context, 'Booking cancelled for $name (seat ${seat.number})');
      } else if (result is String) {
        await bus.rename(seat.number, result);
        if (!context.mounted) return;
        showMessage(context, 'Seat ${seat.number} is now for $result');
      }
      return;
    }

    // free seat: open the booking screen, and hand it the SAME brain
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<BusState>.value(
          value: bus,
          child: BookSeatScreen(
            seatNumber: seat.number,
            price: BusState.price,
            takenNames: bus.takenNames,
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (result != null) {
      final booking = result as Booking;
      await bus.book(seat.number, booking);
      if (!context.mounted) return;
      showMessage(context, 'Seat ${seat.number} booked for ${booking.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bus = context.watch<BusState>(); // rebuild at every change

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horizon Express'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _body(context, bus),
    );
  }

  Widget _body(BuildContext context, BusState bus) {
    if (bus.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(bus.error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (bus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final seats = bus.seats;

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.indigo,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${BusState.route} · ${BusState.price} RWF',
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Seats sold: ${bus.sold} / ${seats.length}   ·   Money made: ${bus.money} RWF',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: seats.length,
            itemBuilder: (context, index) {
              final seat = seats[index];
              return InkWell(
                onTap: () => _onSeatTap(context, seat),
                child: Container(
                  decoration: BoxDecoration(
                    color: seat.isTaken
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(seat.isTaken ? Icons.person : Icons.event_seat),
                      Text('Seat ${seat.number}'),
                      if (seat.isTaken)
                        Text(
                          seat.passenger!.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}