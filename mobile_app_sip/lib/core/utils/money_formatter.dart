import 'package:intl/intl.dart';

class MoneyFormatter {
  static final _solesFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
  static final _dollarsFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$ ');

  static String format(double amount, {String currency = 'PEN'}) {
    if (currency == 'USD') {
      return _dollarsFormat.format(amount);
    }
    return _solesFormat.format(amount);
  }
}
