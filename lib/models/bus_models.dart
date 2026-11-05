class Passenger {
  Passenger(this.name, {this.priority = false, this.photoUrl}); // NEW photoUrl

  final String name;
  final bool priority;
  final String? photoUrl; // NEW: link to the passenger's photo, or null
}

class Seat {
  Seat(this.number);

  final int number;
  Passenger? passenger; // null means the seat is free
  int paid = 0;

  bool get isTaken => passenger != null;
}

class Booking {
  Booking(this.name, this.cash, {this.photoUrl}); // NEW photoUrl

  final String name;
  final int cash;
  final String? photoUrl; // NEW
}