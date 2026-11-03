import 'package:flutter/material.dart';

import '../models/bus_models.dart';
import '../utils/change.dart';

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