import 'package:flutter/material.dart';

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

void main() {
  runApp(const MaterialApp(home: Text('Bus Booking')));
}