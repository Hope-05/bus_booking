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