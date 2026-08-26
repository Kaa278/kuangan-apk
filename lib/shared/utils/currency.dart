import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String formatIDR(double amount, {bool compact = false}) {
  if (compact && amount.abs() >= 1000000) {
    final val = amount / 1000000;
    return 'Rp ${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}jt';
  }
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

String formatIDRSigned(double amount) {
  final s = formatIDR(amount.abs());
  return amount >= 0 ? '+$s' : '-$s';
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Clean decimals and everything that's not a digit
    String baseText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (baseText.isEmpty) {
      return newValue.copyWith(
          text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    double value = double.parse(baseText);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    String newText = formatter.format(value).trim();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
