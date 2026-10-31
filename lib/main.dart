import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

// ---------- MODEL ----------

class Passenger {
  Passenger(this.name, {this.priority = false});

  final String name;
  final bool priority;
}

class Seat {
  Seat(this.number);

  final int number;
  Passenger? passenger; // null means the seat is free
  int paid = 0;

  bool get isTaken => passenger != null;
}

class Booking {
  Booking(this.name, this.cash);

  final String name;
  final int cash;
}

// Lab 6: change as notes, biggest first
String changeInNotes(int change) {
  if (change == 0) return 'No change';
  const notes = [5000, 2000, 1000, 500, 100];
  final parts = <String>[];
  var left = change;
  for (final note in notes) {
    final count = left ~/ note;
    if (count > 0) {
      parts.add('$note × $count');
      left -= count * note;
    }
  }
  return parts.join(' · ');
}

// The signed-in user's own bookings: users/{uid}/bookings
CollectionReference<Map<String, dynamic>> bookingsRef() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('bookings');
}

// ---------- APP ----------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BusApp());
}

class BusApp extends StatelessWidget {
  const BusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == null) {
          return const LoginScreen();
        }
        return const SeatMapScreen();
      },
    );
  }
}

// ---------- SCREEN 1: SEAT MAP ----------

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

// ---------- SCREEN 2: BOOK A SEAT ----------

class BookSeatScreen extends StatefulWidget {
  const BookSeatScreen({
    super.key,
    required this.seatNumber,
    required this.price,
    required this.takenNames,
  });

  final int seatNumber;
  final int price;
  final List<String> takenNames;

  @override
  State<BookSeatScreen> createState() => _BookSeatScreenState();
}

class _BookSeatScreenState extends State<BookSeatScreen> {
  final nameController = TextEditingController();
  final cashController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    cashController.dispose();
    super.dispose();
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  void confirm() {
    final name = nameController.text.trim();
    final cash = int.tryParse(cashController.text.trim());

    // every check first, nothing changes if one fails
    if (name.isEmpty) {
      showMessage('Type the passenger name first');
      return;
    }
    if (widget.takenNames.contains(name.toLowerCase())) {
      showMessage('$name already has a seat');
      return;
    }
    if (cash == null) {
      showMessage('Cash must be a whole number');
      return;
    }
    if (cash < widget.price) {
      showMessage('Cash must be at least ${widget.price} RWF');
      return;
    }
    if (cash % 100 != 0) {
      showMessage('Cash must be a multiple of 100');
      return;
    }
    Navigator.pop(context, Booking(name, cash));
  }

  @override
  Widget build(BuildContext context) {
    final cash = int.tryParse(cashController.text.trim());
    final canShowChange =
        cash != null && cash >= widget.price && cash % 100 == 0;

    return Scaffold(
      appBar: AppBar(title: Text('Book seat ${widget.seatNumber}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Price: ${widget.price} RWF'),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Passenger name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: cashController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cash handed over (RWF)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (canShowChange)
            Text('Change: ${changeInNotes(cash - widget.price)}'),
          const SizedBox(height: 24),
          FilledButton(onPressed: confirm, child: const Text('Confirm')),
        ],
      ),
    );
  }
}

// ---------- SCREEN 3: BOOKING DETAILS ----------

class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({super.key, required this.seat});

  final Seat seat;

  void confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel booking?'),
          content: Text(
            '${seat.passenger!.name} will lose seat ${seat.number}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext); // close the box
                Navigator.pop(context, true); // go back, saying "cancel"
              },
              child: const Text('Yes, cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> editName(BuildContext context) async {
    final controller = TextEditingController(text: seat.passenger!.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit passenger name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (newName != null && newName.isNotEmpty && context.mounted) {
      Navigator.pop(context, newName); // go back, saying "new name"
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seat ${seat.number}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seat.passenger!.name,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text('Paid: ${seat.paid} RWF'),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => editName(context),
              child: const Text('Edit name'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => confirmCancel(context),
              child: const Text('Cancel booking'),
            ),
          ],
        ),
      ),
    );
  }
}