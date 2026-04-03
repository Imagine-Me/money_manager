import 'package:flutter/material.dart';

enum TransactionType {
  burn, // Expenditure
  store, // Savings & Investments
  transfer; // Account-to-account transfer

  String get label => switch (this) {
        burn => 'Burn',
        store => 'Store',
        transfer => 'Transfer',
      };
  String get description => switch (this) {
        burn => 'Expenditure',
        store => 'Savings & Investments',
        transfer => 'Account Transfer',
      };

  static TransactionType fromString(String value) {
    return switch (value) {
      'store' => store,
      'transfer' => transfer,
      _ => burn,
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
  ];
}
