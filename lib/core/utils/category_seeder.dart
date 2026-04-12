import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:money_manager/data/models/category_model.dart';

/// Seeds default parent categories and subcategories on first launch.
/// Safe to call on every app start — skips seeding if data already exists.
class CategorySeeder {
  CategorySeeder._();

  static Future<void> seed(Isar isar) async {
    final count = await isar.categoryModels.count();
    if (count > 0) return;

    await isar.writeTxn(() async {
      // ── BURN parents ──────────────────────────────────────────────────────
      final foodId = await isar.categoryModels.put(
        _parent('Food & Drink', const Color(0xFFFF8E53), Icons.restaurant_rounded, 'burn'),
      );
      final shoppingId = await isar.categoryModels.put(
        _parent('Shopping', const Color(0xFFE91E63), Icons.shopping_bag_rounded, 'burn'),
      );
      final transportId = await isar.categoryModels.put(
        _parent('Transport', const Color(0xFF42A5F5), Icons.directions_car_rounded, 'burn'),
      );
      final housingId = await isar.categoryModels.put(
        _parent('Housing', const Color(0xFF7B63E6), Icons.home_rounded, 'burn'),
      );
      final healthId = await isar.categoryModels.put(
        _parent('Health', const Color(0xFFEF5350), Icons.favorite_rounded, 'burn'),
      );
      final entId = await isar.categoryModels.put(
        _parent('Entertainment', const Color(0xFFFFCA28), Icons.movie_rounded, 'burn'),
      );
      final travelId = await isar.categoryModels.put(
        _parent('Travel', const Color(0xFF26C6DA), Icons.flight_rounded, 'burn'),
      );
      final eduId = await isar.categoryModels.put(
        _parent('Education', const Color(0xFF26A69A), Icons.school_rounded, 'burn'),
      );
      final billsId = await isar.categoryModels.put(
        _parent('Bills & Fees', const Color(0xFF8D6E63), Icons.receipt_long_rounded, 'burn'),
      );
      final loansId = await isar.categoryModels.put(
        _parent('Loans & EMI', const Color(0xFFFF7043), Icons.account_balance_wallet_rounded, 'burn'),
      );

      // ── INCOME parents ────────────────────────────────────────────────────
      await isar.categoryModels.put(
        _parent('Salary', const Color(0xFF66BB6A), Icons.payments_rounded, 'income'),
      );
      await isar.categoryModels.put(
        _parent('Business', const Color(0xFFFFB300), Icons.business_center_rounded, 'income'),
      );
      await isar.categoryModels.put(
        _parent('Mutual Fund', const Color(0xFF42A5F5), Icons.pie_chart_rounded, 'income'),
      );
      await isar.categoryModels.put(
        _parent('App Revenue', const Color(0xFFAB47BC), Icons.smartphone_rounded, 'income'),
      );
      await isar.categoryModels.put(
        _parent('Gifts Received', const Color(0xFFE91E63), Icons.card_giftcard_rounded, 'income'),
      );
      await isar.categoryModels.put(
        _parent('Rental Income', const Color(0xFF26C6DA), Icons.home_work_rounded, 'income'),
      );
      await isar.categoryModels.put(
        _parent('Trade', const Color(0xFF26C6DA), Icons.candlestick_chart_rounded, 'income'),
      );
      await isar.categoryModels.put(
        _parent('Savings', const Color(0xFF4ECDC4), Icons.savings_rounded, 'store'),
      );
      final freelanceId = await isar.categoryModels.put(
        _parent('Freelance', const Color(0xFF26A69A), Icons.laptop_mac, 'store'),
      );
      final investId = await isar.categoryModels.put(
        _parent('Investment', const Color(0xFF42A5F5), Icons.trending_up_rounded, 'store'),
      );
      await isar.categoryModels.put(
        _parent('Side Business', const Color(0xFFFFCA28), Icons.store_rounded, 'store'),
      );
      await isar.categoryModels.put(
        _parent('Gifts Received', const Color(0xFFE91E63), Icons.card_giftcard_rounded, 'store'),
      );

      // ── BURN subcategories ────────────────────────────────────────────────

      // Food & Drink
      final fc = const Color(0xFFFF8E53);
      await _subs(isar, foodId, fc, 'burn', [
        ('Restaurants', Icons.restaurant_rounded),
        ('Cafes', Icons.local_cafe_rounded),
        ('Groceries', Icons.local_grocery_store_rounded),
        ('Fast Food', Icons.fastfood_rounded),
        ('Alcohol', Icons.local_bar_rounded),
      ]);

      // Shopping
      final sc = const Color(0xFFE91E63);
      await _subs(isar, shoppingId, sc, 'burn', [
        ('Online Shopping', Icons.shopping_cart_rounded),
        ('Clothing', Icons.style_rounded),
        ('Electronics', Icons.devices_rounded),
        ('Games', Icons.sports_esports_rounded),
        ('Books', Icons.menu_book_rounded),
      ]);

      // Transport
      final tc = const Color(0xFF42A5F5);
      await _subs(isar, transportId, tc, 'burn', [
        ('Fuel', Icons.local_gas_station_rounded),
        ('Parking', Icons.local_parking_rounded),
        ('Public Transport', Icons.directions_bus_rounded),
        ('Taxi & Rides', Icons.local_taxi_rounded),
      ]);

      // Housing
      final hc = const Color(0xFF7B63E6);
      await _subs(isar, housingId, hc, 'burn', [
        ('Rent', Icons.house_rounded),
        ('Utilities', Icons.bolt_rounded),
        ('Internet', Icons.wifi_rounded),
        ('Maintenance', Icons.build_rounded),
      ]);

      // Health
      final hlc = const Color(0xFFEF5350);
      await _subs(isar, healthId, hlc, 'burn', [
        ('Doctor', Icons.medical_services_rounded),
        ('Pharmacy', Icons.local_pharmacy_rounded),
        ('Gym', Icons.fitness_center_rounded),
        ('Wellness', Icons.spa_rounded),
      ]);

      // Entertainment
      final ec = const Color(0xFFFFCA28);
      await _subs(isar, entId, ec, 'burn', [
        ('Movies', Icons.movie_rounded),
        ('Streaming Services', Icons.play_circle_rounded),
        ('Events', Icons.event_rounded),
        ('Music', Icons.music_note_rounded),
      ]);

      // Travel
      final trc = const Color(0xFF26C6DA);
      await _subs(isar, travelId, trc, 'burn', [
        ('Flights', Icons.flight_rounded),
        ('Hotels', Icons.hotel_rounded),
        ('Sightseeing', Icons.photo_camera_rounded),
      ]);

      // Education
      final edc = const Color(0xFF26A69A);
      await _subs(isar, eduId, edc, 'burn', [
        ('Courses', Icons.school_rounded),
        ('Textbooks', Icons.menu_book_rounded),
        ('Study Apps', Icons.apps_rounded),
      ]);

      // Bills & Fees
      final bc = const Color(0xFF8D6E63);
      await _subs(isar, billsId, bc, 'burn', [
        ('Phone Bill', Icons.phone_android_rounded),
        ('Insurance', Icons.security_rounded),
        ('Taxes', Icons.account_balance_rounded),
        ('App Subscriptions', Icons.subscriptions_rounded),
        ('Credit Card EMI', Icons.credit_card_rounded),
      ]);

      // Loans & EMI
      final lc = const Color(0xFFFF7043);
      await _subs(isar, loansId, lc, 'burn', [
        ('Car Loan', Icons.directions_car_rounded),
        ('Bike Loan', Icons.two_wheeler_rounded),
        ('Personal Loan', Icons.person_rounded),
        ('Home Loan', Icons.home_rounded),
        ('Education Loan', Icons.school_rounded),
        ('Gold Loan', Icons.monetization_on_rounded),
      ]);

      // ── STORE subcategories ───────────────────────────────────────────────

      // Freelance
      final frc = const Color(0xFF26A69A);
      await _subs(isar, freelanceId, frc, 'store', [
        ('Dev Projects', Icons.code_rounded),
        ('Design Projects', Icons.palette_rounded),
        ('Writing', Icons.edit_rounded),
        ('Consulting', Icons.work_rounded),
      ]);

      // Investment
      final ic = const Color(0xFF42A5F5);
      await _subs(isar, investId, ic, 'store', [
        ('Stocks', Icons.show_chart_rounded),
        ('Crypto', Icons.currency_exchange_rounded),
        ('Mutual Funds', Icons.pie_chart_rounded),
        ('Real Estate', Icons.domain_rounded),
      ]);
    });
  }

  // ── Migration: add Income categories for existing users ──────────────────

  /// Adds income-type categories if they don't already exist.
  /// Safe to call on every startup — no-ops if already present.
  static Future<void> seedIncome(Isar isar) async {
    final existing = await isar.categoryModels
        .filter()
        .typeEqualTo('income')
        .findFirst();
    if (existing != null) return;

    await isar.writeTxn(() async {
      await isar.categoryModels.put(
        _parent('Salary', const Color(0xFF66BB6A), Icons.payments_rounded, 'income'),
      );
      await isar.categoryModels.put(
        _parent('Business', const Color(0xFFFFB300), Icons.business_center_rounded, 'income'),
      );
      await isar.categoryModels.put(
        _parent('Mutual Fund', const Color(0xFF42A5F5), Icons.pie_chart_rounded, 'income'),
      );
      await isar.categoryModels.put(
        _parent('App Revenue', const Color(0xFFAB47BC), Icons.smartphone_rounded, 'income'),
      );
      await isar.categoryModels.put(
        _parent('Gifts Received', const Color(0xFFE91E63), Icons.card_giftcard_rounded, 'income'),
      );
      await isar.categoryModels.put(
        _parent('Rental Income', const Color(0xFF26C6DA), Icons.home_work_rounded, 'income'),
      );
    });
  }

  // ── Migration: ensure all income categories exist ─────────────────────────

  /// Inserts each income category individually if it doesn't already exist.
  /// Safe to call on every startup even when data is already present —
  /// only missing entries are written.
  static Future<void> seedMissingIncome(Isar isar) async {
    final desired = [
      ('Salary',         const Color(0xFF66BB6A), Icons.payments_rounded),
      ('Business',       const Color(0xFFFFB300), Icons.business_center_rounded),
      ('Mutual Fund',    const Color(0xFF42A5F5), Icons.pie_chart_rounded),
      ('App Revenue',    const Color(0xFFAB47BC), Icons.smartphone_rounded),
      ('Gifts Received', const Color(0xFFE91E63), Icons.card_giftcard_rounded),
      ('Rental Income',  const Color(0xFF26C6DA), Icons.home_work_rounded),
      ('Freelance',      const Color(0xFF26A69A), Icons.laptop_mac),
      ('Dividends',      const Color(0xFF42A5F5), Icons.show_chart_rounded),
      ('Interest',       const Color(0xFF4ECDC4), Icons.account_balance_rounded),
      ('Trade',          const Color(0xFF26C6DA), Icons.candlestick_chart_rounded),
    ];

    for (final (name, color, icon) in desired) {
      final exists = await isar.categoryModels
          .filter()
          .nameEqualTo(name)
          .typeEqualTo('income')
          .findFirst();
      if (exists != null) continue;

      await isar.writeTxn(() async {
        await isar.categoryModels.put(_parent(name, color, icon, 'income'));
      });
    }
  }

  // ── Migration: add Loans & EMI for existing users ─────────────────────────

  /// Adds the Loans & EMI category if it doesn't already exist.
  /// Safe to call on every startup — no-ops if category is present.
  static Future<void> seedLoans(Isar isar) async {
    final existing = await isar.categoryModels
        .filter()
        .nameEqualTo('Loans & EMI')
        .findFirst();
    if (existing != null) return;

    await isar.writeTxn(() async {
      final loansId = await isar.categoryModels.put(
        _parent('Loans & EMI', const Color(0xFFFF7043), Icons.account_balance_wallet_rounded, 'burn'),
      );
      const lc = Color(0xFFFF7043);
      await _subs(isar, loansId, lc, 'burn', [
        ('Car Loan', Icons.directions_car_rounded),
        ('Bike Loan', Icons.two_wheeler_rounded),
        ('Personal Loan', Icons.person_rounded),
        ('Home Loan', Icons.home_rounded),
        ('Education Loan', Icons.school_rounded),
        ('Gold Loan', Icons.monetization_on_rounded),
      ]);
    });
  }

  // ── Migration: move Credit Card EMI to Bills & Fees ───────────────────────

  /// Moves the "Credit Card EMI" subcategory from "Loans & EMI" to
  /// "Bills & Fees" for existing users. Safe to call on every startup.
  static Future<void> moveCreditCardEMIToBills(Isar isar) async {
    // Find Bills & Fees parent
    final bills = await isar.categoryModels
        .filter()
        .nameEqualTo('Bills & Fees')
        .findFirst();
    if (bills == null) return;

    // Find Credit Card EMI subcategory under Loans & EMI
    final loans = await isar.categoryModels
        .filter()
        .nameEqualTo('Loans & EMI')
        .findFirst();
    if (loans == null) return;

    final emiEntry = await isar.categoryModels
        .filter()
        .nameEqualTo('Credit Card EMI')
        .parentIdEqualTo(loans.id)
        .findFirst();
    if (emiEntry == null) return; // already moved or doesn't exist

    // Re-parent to Bills & Fees
    await isar.writeTxn(() async {
      emiEntry.parentId = bills.id;
      emiEntry.colorValue = bills.colorValue;
      await isar.categoryModels.put(emiEntry);
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static CategoryModel _parent(
    String name,
    Color color,
    IconData icon,
    String type,
  ) =>
      CategoryModel()
        ..name = name
        ..colorValue = color.toARGB32()
        ..iconCodePoint = icon.codePoint
        ..iconFontFamily = icon.fontFamily ?? 'MaterialIcons'
        ..type = type;

  static Future<void> _subs(
    Isar isar,
    int parentId,
    Color color,
    String type,
    List<(String, IconData)> entries,
  ) async {
    for (final (name, icon) in entries) {
      await isar.categoryModels.put(
        CategoryModel()
          ..name = name
          ..colorValue = color.toARGB32()
          ..iconCodePoint = icon.codePoint
          ..iconFontFamily = icon.fontFamily ?? 'MaterialIcons'
          ..type = type
          ..parentId = parentId,
      );
    }
  }
}
