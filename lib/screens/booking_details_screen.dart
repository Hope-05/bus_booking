import 'package:flutter/material.dart';

import '../models/bus_models.dart';

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