import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  static const _keyCurrencySymbol = 'currency_symbol';
  static const _keyCurrencyName = 'currency_name';
  static const _keyCurrencyLocale = 'currency_locale';
  static const _keySetupDone = 'setup_done';
  static const _keyLoginDone = 'login_done';
  static const _keyInstalledDate = 'installed_date';
  static const _keyDismissedMissedDays = 'dismissed_missed_days';
  static const _keyLastBackupDate = 'last_backup_date';

  late SharedPreferences _prefs;

  // Loaded into memory once at startup
  late String currencySymbol;
  late String currencyName;
  late String currencyLocale;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    currencySymbol = _prefs.getString(_keyCurrencySymbol) ?? '₹';
    currencyName = _prefs.getString(_keyCurrencyName) ?? 'Indian Rupee';
    currencyLocale = _prefs.getString(_keyCurrencyLocale) ?? 'en_IN';
    // Record install date on first ever launch
    if (!_prefs.containsKey(_keyInstalledDate)) {
      await _prefs.setString(
          _keyInstalledDate,
          DateTime.now().toIso8601String().substring(0, 10));
    }
  }

  bool get isSetupDone => _prefs.getBool(_keySetupDone) ?? false;

  bool get loginDone => _prefs.getBool(_keyLoginDone) ?? false;

  Future<void> saveLoginDone() async {
    await _prefs.setBool(_keyLoginDone, true);
  }

  /// The date the app was first launched (date-only, UTC-midnight equivalent).
  DateTime get installedDate {
    final raw = _prefs.getString(_keyInstalledDate);
    if (raw == null) return DateTime.now();
    return DateTime.parse(raw);
  }

  /// ISO date strings (yyyy-MM-dd) the user has swiped away.
  Set<String> get dismissedMissedDays {
    final raw = _prefs.getString(_keyDismissedMissedDays);
    if (raw == null) return {};
    return Set<String>.from(jsonDecode(raw) as List);
  }

  Future<void> dismissMissedDay(DateTime date) async {
    final key = date.toIso8601String().substring(0, 10);
    final current = dismissedMissedDays;
    current.add(key);
    await _prefs.setString(
        _keyDismissedMissedDays, jsonEncode(current.toList()));
  }

  DateTime? get lastBackupDate {
    final raw = _prefs.getString(_keyLastBackupDate);
    if (raw == null) return null;
    return DateTime.parse(raw);
  }

  Future<void> setLastBackupDate(DateTime date) async {
    await _prefs.setString(_keyLastBackupDate, date.toIso8601String());
  }

  Future<void> saveCurrency({
    required String symbol,
    required String name,
    required String locale,
  }) async {
    currencySymbol = symbol;
    currencyName = name;
    currencyLocale = locale;
    await _prefs.setString(_keyCurrencySymbol, symbol);
    await _prefs.setString(_keyCurrencyName, name);
    await _prefs.setString(_keyCurrencyLocale, locale);
    await _prefs.setBool(_keySetupDone, true);
  }
}
