import 'package:intl/intl.dart';
import 'package:money_manager/core/services/preferences_service.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String get _symbol => PreferencesService.instance.currencySymbol;
  static String get _locale => PreferencesService.instance.currencyLocale;

  static String format(double amount) {
    return NumberFormat.currency(
      symbol: _symbol,
      decimalDigits: 2,
      locale: _locale,
    ).format(amount);
  }

  static String formatCompact(double amount) {
    return NumberFormat.compactCurrency(
      symbol: _symbol,
      decimalDigits: 1,
      locale: _locale,
    ).format(amount);
  }

  static String formatDelta(double delta) {
    final sign = delta >= 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(1)}%';
  }
}

class DateFormatter {
  DateFormatter._();

  static final _dateFormatter = DateFormat('dd MMM yyyy');
  static final _shortFormatter = DateFormat('dd MMM');
  static final _dayFormatter = DateFormat('EEE');
  static final _monthYearFormatter = DateFormat('MMMM yyyy');

  static String formatDate(DateTime date) => _dateFormatter.format(date);
  static String formatShort(DateTime date) => _shortFormatter.format(date);
  static String formatDay(DateTime date) => _dayFormatter.format(date);
  static String formatMonthYear(DateTime date) =>
      _monthYearFormatter.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return _dateFormatter.format(date);
  }
}
