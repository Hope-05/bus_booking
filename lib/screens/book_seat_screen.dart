import 'dart:io'; // NEW

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // NEW

import '../models/bus_models.dart';
import '../utils/change.dart';

class BookSeatScreen extends StatefulWidget {
  const BookSeatScreen({
    super.key,
    required this.seatNumber,
    required this.price,
    required this.takenNames,
    required this.onUpload, // NEW
  });

  final int seatNumber;
  final int price;
  final List<String> takenNames;
  final Future<String> Function(File photo) onUpload; // NEW

  @override
  State<BookSeatScreen> createState() => _BookSeatScreenState();
}

class _BookSeatScreenState extends State<BookSeatScreen> {
  final nameController = TextEditingController();
  final cashController = TextEditingController();
  File? _photo; // NEW: picked on this phone, not uploaded yet
  bool _saving = false; // NEW

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

  // NEW
  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 70,
    );
    if (picked == null) return; // the user cancelled
    setState(() => _photo = File(picked.path));
  }

  // CHANGED: now async, uploads the photo first, then returns the booking
  Future<void> confirm() async {
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

    setState(() => _saving = true);
    try {
      String? photoUrl;
      if (_photo != null) {
        photoUrl = await widget.onUpload(_photo!);
      }
      if (!mounted) return;
      Navigator.pop(context, Booking(name, cash, photoUrl: photoUrl));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage('Could not upload the photo: $e');
    }
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
          const SizedBox(height: 16),
          // NEW: photo preview and the two buttons
          if (_photo != null) ...[
            Image.file(_photo!, height: 180, fit: BoxFit.cover),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _saving ? null : () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _saving ? null : () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : confirm,
            child: Text(_saving ? 'Saving...' : 'Confirm'),
          ),
        ],
      ),
    );
  }
}