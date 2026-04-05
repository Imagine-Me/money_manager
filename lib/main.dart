import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/services/preferences_service.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/data/datasources/local/isar_service.dart';
import 'package:money_manager/data/repositories/recurring_transaction_repository_impl.dart';
import 'package:money_manager/presentation/views/home_shell.dart';
import 'package:money_manager/presentation/views/login_view.dart';
import 'package:money_manager/presentation/views/onboarding_view.dart';
import 'package:money_manager/services/backup_service.dart';
import 'package:money_manager/services/google_auth_service.dart';
import 'package:money_manager/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialise Isar database.
  await IsarService.instance.open();

  // Process any recurring transactions due today.
  await RecurringTransactionRepositoryImpl(IsarService.instance)
      .processDueTransactions();

  // Load user preferences (currency etc.).
  await PreferencesService.instance.load();

  // Initialise and schedule daily notification.
  final notifService = NotificationService.instance;
  await notifService.initialize();
  await notifService.requestPermissions();
  await notifService.scheduleDailyReminder();

  // Attempt silent sign-in and auto-backup in the background.
  // This does not block app startup.
  _tryAutoBackup();

  runApp(ProviderScope(child: VaultCashApp()));
}

/// Silently signs in (if previously authorised) and backs up data.
/// Errors are silently swallowed so they never affect app startup.
void _tryAutoBackup() {
  GoogleAuthService.instance.signInSilently().then((user) async {
    if (user == null) return;
    try {
      await BackupService.instance.backupToDrive();
    } catch (_) {
      // Auto-backup is best-effort; ignore failures.
    }
  }).catchError((_) {});
}

class VaultCashApp extends StatelessWidget {
  const VaultCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesService.instance;
    final Widget home;
    if (prefs.isSetupDone) {
      home = const HomeShell();
    } else if (prefs.loginDone) {
      home = const OnboardingView();
    } else {
      home = const LoginView();
    }
    return MaterialApp(
      title: 'VaultCash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: home,
    );
  }
}
