import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/bus_models.dart';
import 'book_seat_screen.dart';
import 'booking_details_screen.dart';

// The signed-in user's own bookings: users/{uid}/bookings
// (temporary here: it moves into the repository in the next step)
CollectionReference<Map<String, dynamic>> bookingsRef() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('bookings');
}

class SeatMapScreen extends StatefulWidget {
  const SeatMapScreen({super.key});

  @override
  State<SeatMapScreen> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends State<SeatMapScreen> {
  static const route = 'Huye';
  static const price = 3000;

  void showMessage(String text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  // Build the 12 seats from the documents that Firestore sent
  List<Seat> seatsFrom(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final seats = List.generate(12, (i) => Seat(i + 1));
    for (final doc in snapshot.docs) {
      final number = int.tryParse(doc.id);
      if (number == null || number < 1 || number > 12) continue;
      final data = doc.data();
      seats[number - 1].passenger = Passenger(data['name'] as String);
      seats[number - 1].paid = (data['paid'] as num).toInt();
    }
    return seats;
  }

  Future<void> cancelBooking(Seat seat) async {
    final name = seat.passenger!.name;
    await bookingsRef().doc('${seat.number}').delete();
    showMessage('Booking cancelled for $name (seat ${seat.number})');
  }

  Future<void> renameBooking(Seat seat, String newName) async {
    await bookingsRef().doc('${seat.number}').update({'name': newName});
    showMessage('Seat ${seat.number} is now for $newName');
  }

  void onSeatTap(Seat seat, List<Seat> seats) {
    // taken seat: open its details
    if (seat.isTaken) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingDetailsScreen(seat: seat),
        ),
      ).then((result) {
        if (result == true) {
          cancelBooking(seat);
        } else if (result is String) {
          renameBooking(seat, result);
        }
      });
      return;
    }

    // free seat: open the booking screen
    final takenNames = seats
        .where((s) => s.isTaken)
        .map((s) => s.passenger!.name.toLowerCase())
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookSeatScreen(
          seatNumber: seat.number,
          price: price,
          takenNames: takenNames,
        ),
      ),
    ).then((result) async {
      if (result != null) {
        final booking = result as Booking;
        await bookingsRef().doc('${seat.number}').set({
          'name': booking.name,
          'paid': price,
          'cash': booking.cash,
          'createdAt': FieldValue.serverTimestamp(),
        });
        showMessage('Seat ${seat.number} booked for ${booking.name}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: bookingsRef().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final seats = seatsFrom(snapshot.data!);
          final sold = seats.where((s) => s.isTaken).length;
          final money = seats.fold<int>(0, (sum, s) => sum + s.paid);

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
                    const Text(
                      '$route · $price RWF',
                      style: TextStyle(color: Colors.white, fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seats sold: $sold / ${seats.length}   ·   Money made: $money RWF',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: seats.length,
                  itemBuilder: (context, index) {
                    final seat = seats[index];
                    return InkWell(
                      onTap: () => onSeatTap(seat, seats),
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
                            Icon(seat.isTaken
                                ? Icons.person
                                : Icons.event_seat),
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
        },
      ),
    );
  }
}