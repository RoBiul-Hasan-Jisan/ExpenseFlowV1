import 'package:intl/intl.dart';

/// Wraps intl currency formatting with ExpenseFlow's supported currencies.
class CurrencyFormatter {
  CurrencyFormatter._();

  static const Map<String, String> _symbols = {
    'BDT': '৳',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
  };

  static const Map<String, String> _locales = {
    'BDT': 'en_BD',
    'USD': 'en_US',
    'EUR': 'de_DE',
    'GBP': 'en_GB',
    'INR': 'en_IN',
  };

  static String format(double amount, String currencyCode, {bool showSign = false}) {
    final symbol = _symbols[currencyCode] ?? currencyCode;
    final locale = _locales[currencyCode] ?? 'en_US';
    final formatter = NumberFormat.currency(locale: locale, symbol: symbol, decimalDigits: 2);
    final formatted = formatter.format(amount.abs());
    if (!showSign) return formatted;
    final sign = amount < 0 ? '-' : (amount > 0 ? '+' : '');
    return '$sign$formatted';
  }

  static String compact(double amount, String currencyCode) {
    final symbol = _symbols[currencyCode] ?? currencyCode;
    final formatter = NumberFormat.compact();
    return '$symbol${formatter.format(amount)}';
  }

  static String symbolFor(String currencyCode) => _symbols[currencyCode] ?? currencyCode;
}
