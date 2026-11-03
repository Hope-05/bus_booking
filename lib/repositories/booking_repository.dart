import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bus_models.dart';

class BookingRepository {
  BookingRepository(this.uid);

  final String uid;

  // users/{uid}/bookings: the path your security rules protect.
  CollectionReference<Map<String, dynamic>> get _bookings =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookings');

  // The pipe: the 12 seats now, and again after every change.
  Stream<List<Seat>> watchSeats() => _bookings.snapshots().map((snapshot) {
    final seats = List.generate(12, (i) => Seat(i + 1));
    for (final doc in snapshot.docs) {
      final number = int.tryParse(doc.id);
      if (number == null || number < 1 || number > 12) continue;
      final data = doc.data();
      seats[number - 1].passenger = Passenger(data['name'] as String);
      seats[number - 1].paid = (data['paid'] as num).toInt();
    }
    return seats;
  });

  Future<void> book(int seatNumber, Booking booking, int price) =>
      _bookings.doc('$seatNumber').set({
        'name': booking.name,
        'paid': price,
        'cash': booking.cash,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> rename(int seatNumber, String newName) =>
      _bookings.doc('$seatNumber').update({'name': newName});

  Future<void> cancel(int seatNumber) =>
      _bookings.doc('$seatNumber').delete();
}