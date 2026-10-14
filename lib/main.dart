import 'package:flutter/material.dart';

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

// ---------- APP ----------

void main() {
  runApp(const BusApp());
}

class BusApp extends StatelessWidget {
  const BusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const SeatMapScreen(),
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

  final seats = List.generate(12, (i) => Seat(i + 1));

  @override
  void initState() {
    super.initState();
    // sample bookings so the app is never empty
    seats[0].passenger = Passenger('Keza');
    seats[0].paid = price;
    seats[3].passenger = Passenger('Eric');
    seats[3].paid = price;
    seats[6].passenger = Passenger('Aline');
    seats[6].paid = price;
  }

  int get sold => seats.where((s) => s.isTaken).length;
  int get money => sold * price;

  void showMessage(String text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  void cancelBooking(Seat seat) {
    final name = seat.passenger!.name;
    setState(() {
      seat.passenger = null;
      seat.paid = 0;
    });
    // Step 6: the waitlist promotion will go here, inside this function
    showMessage('Booking cancelled for $name (seat ${seat.number})');
  }

  void onSeatTap(Seat seat) {
    // taken seat: open its details
    if (seat.isTaken) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingDetailsScreen(seat: seat),
        ),
      ).then((result) {
        if (result == true) cancelBooking(seat);
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
    ).then((result) {
      if (result != null) {
        final booking = result as Booking;
        setState(() {
          seat.passenger = Passenger(booking.name);
          seat.paid = price;
        });
        showMessage('Seat ${seat.number} booked for ${booking.name}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horizon Express')),
      body: Column(
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
                  onTap: () => onSeatTap(seat),
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