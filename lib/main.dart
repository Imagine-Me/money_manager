import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/services/preferences_service.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/data/datasources/local/isar_service.dart';
import 'package:money_manager/presentation/views/dashboard_view.dart';
import 'package:money_manager/presentation/views/onboarding_view.dart';
import 'package:money_manager/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialise Isar database.
  await IsarService.instance.open();

  // Load user preferences (currency etc.).
  await PreferencesService.instance.load();

  // Initialise and schedule daily notification.
  final notifService = NotificationService.instance;
  await notifService.initialize();
  await notifService.requestPermissions();
  await notifService.scheduleDailyReminder();

  runApp(ProviderScope(child: VaultCashApp()));
}

class VaultCashApp extends StatelessWidget {
  const VaultCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isSetup = PreferencesService.instance.isSetupDone;
    return MaterialApp(
      title: 'VaultCash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isSetup ? const DashboardView() : const OnboardingView(),
    );
  }
}
