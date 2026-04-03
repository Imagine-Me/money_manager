import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  static const _keyCurrencySymbol = 'currency_symbol';
  static const _keyCurrencyName = 'currency_name';
  static const _keyCurrencyLocale = 'currency_locale';
  static const _keySetupDone = 'setup_done';

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
  }

  bool get isSetupDone => _prefs.getBool(_keySetupDone) ?? false;

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
