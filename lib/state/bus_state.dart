import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/bus_models.dart';
import '../repositories/booking_repository.dart';

class BusState extends ChangeNotifier {
  BusState(this._repo) {
    // Born: open the pipe to the backend, once.
    _subscription = _repo.watchSeats().listen(
          (list) {
        _seats = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = 'Could not load your bookings.';
        notifyListeners();
      },
    );
  }

  final BookingRepository _repo;
  StreamSubscription<List<Seat>>? _subscription;

  static const route = 'Huye';
  static const price = 3000;

  // The data: private, so only the brain can change it.
  List<Seat> _seats = List.generate(12, (i) => Seat(i + 1));
  bool _loading = true;
  String? _error;

  // Read-only views for the screens.
  List<Seat> get seats => _seats;
  bool get loading => _loading;
  String? get error => _error;

  // Computed: never saved, worked out every time it is read.
  int get sold => _seats.where((s) => s.isTaken).length;
  int get seatsLeft => _seats.length - sold;
  int get money => _seats.fold<int>(0, (sum, s) => sum + s.paid);
  List<String> get takenNames =>
      _seats.where((s) => s.isTaken).map((s) => s.passenger!.name.toLowerCase()).toList();

  // Actions: the brain hands the job to the repository.
  Future<void> book(int seatNumber, Booking booking) =>
      _repo.book(seatNumber, booking, price);
  Future<void> rename(int seatNumber, String newName) =>
      _repo.rename(seatNumber, newName);
  Future<void> cancel(int seatNumber) => _repo.cancel(seatNumber);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}