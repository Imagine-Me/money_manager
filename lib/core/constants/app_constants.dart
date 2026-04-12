import 'package:flutter/material.dart';

enum TransactionType {
  burn, // Expenditure
  store, // Savings & Investments
  transfer, // Account-to-account transfer
  income; // Earned income (salary, business, etc.)

  String get label => switch (this) {
        burn => 'Burn',
        store => 'Store',
        transfer => 'Transfer',
        income => 'Income',
      };
  String get description => switch (this) {
        burn => 'Expenditure',
        store => 'Savings & Investments',
        transfer => 'Account Transfer',
        income => 'Earned Income',
      };

  static TransactionType fromString(String value) {
    return switch (value) {
      'store' => store,
      'transfer' => transfer,
      'income' => income,
      _ => burn,
    };
  }
}

enum RecurringFrequency {
  weekly,
  monthly,
  yearly;

  String get label => switch (this) {
        weekly => 'Weekly',
        monthly => 'Monthly',
        yearly => 'Yearly',
      };

  static RecurringFrequency fromString(String value) {
    return switch (value) {
      'monthly' => monthly,
      'yearly' => yearly,
      _ => weekly,
    };
  }
}

class AppConstants {
  AppConstants._();

  static const String appName = 'VaultCash';
  static const String currencySymbol = '₹';
  static const int dailyReminderHour = 21;
  static const int dailyReminderMinute = 0;
  static const int notificationId = 0;

  static const List<Color> categoryColors = [
    Color(0xFFFF6B6B), // Red
    Color(0xFFFF8E53), // Orange
    Color(0xFFFFD166), // Yellow
    Color(0xFF06D6A0), // Mint
    Color(0xFF4ECDC4), // Teal
    Color(0xFF6BCB77), // Green
    Color(0xFF118AB2), // Dark Blue
    Color(0xFF6B78E6), // Indigo
    Color(0xFF9B59B6), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFF795548), // Brown
  ];

  static final List<IconData> categoryIconOptions = [
    Icons.restaurant,
    Icons.directions_car,
    Icons.shopping_bag,
    Icons.health_and_safety,
    Icons.movie,
    Icons.school,
    Icons.receipt_long,
    Icons.flight,
    Icons.home,
    Icons.savings,
    Icons.trending_up,
    Icons.coffee,
    Icons.fitness_center,
    Icons.music_note,
    Icons.card_giftcard,
    Icons.devices,
    Icons.pets,
    Icons.spa,
    Icons.local_grocery_store,
    Icons.category,
    // Extended set
    Icons.credit_card,
    Icons.account_balance,
    Icons.local_hospital,
    Icons.phone_android,
    Icons.wifi,
    Icons.bolt,
    Icons.security,
    Icons.subscriptions,
    Icons.two_wheeler,
    Icons.train,
    Icons.local_gas_station,
    Icons.fastfood,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.style,
    Icons.sports_esports,
    Icons.menu_book,
    Icons.laptop_mac,
    Icons.work,
    Icons.child_care,
    Icons.local_pharmacy,
    Icons.hotel,
    Icons.monetization_on,
    Icons.pie_chart,
    Icons.show_chart,
    Icons.currency_exchange,
    Icons.domain,
    Icons.code,
    Icons.palette,
    Icons.edit,
  ];

  static const List<String> categoryIconLabels = [
    'Food',
    'Transport',
    'Shopping',
    'Health',
    'Movies',
    'Education',
    'Bills',
    'Travel',
    'Home',
    'Savings',
    'Investment',
    'Coffee',
    'Fitness',
    'Music',
    'Gifts',
    'Tech',
    'Pets',
    'Wellness',
    'Groceries',
    'Others',
    // Extended set
    'Credit Card',
    'Bank',
    'Hospital',
    'Phone',
    'Internet',
    'Utilities',
    'Insurance',
    'Subscriptions',
    'Bike',
    'Train',
    'Fuel',
    'Fast Food',
    'Cafe',
    'Drinks',
    'Clothing',
    'Gaming',
    'Books',
    'Laptop',
    'Work',
    'Child',
    'Pharmacy',
    'Hotel',
    'Gold',
    'Pie Chart',
    'Stocks',
    'Crypto',
    'Real Estate',
    'Coding',
    'Design',
    'Writing',
  ];
}
