import 'package:intl/intl.dart';

extension DoubleFormatting on double {
  String get currencyFormat =>
      NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.', decimalDigits: 2)
          .format(this);
}

extension DateTimeFormatting on DateTime {
  String get formattedDate => DateFormat('dd MMM yyyy').format(this);
  String get formattedDateTime => DateFormat('dd MMM yyyy, hh:mm a').format(this);
  String get formattedTime => DateFormat('hh:mm a').format(this);
}

extension StringCapitalize on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
