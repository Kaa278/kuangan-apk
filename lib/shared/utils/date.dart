import 'package:intl/intl.dart';

String formatDate(DateTime date) =>
    DateFormat('d MMMM yyyy', 'id_ID').format(date);

String formatDateShort(DateTime date) =>
    DateFormat('d MMM', 'id_ID').format(date);

String formatDateMonth(DateTime date) =>
    DateFormat('MMM yyyy', 'id_ID').format(date);

String formatDateFull(DateTime date) =>
    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);

String toRelativeDay(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Kemarin';
  return formatDate(date);
}
