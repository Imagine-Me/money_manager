import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/services/preferences_service.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/services/backup_service.dart';
import 'package:money_manager/services/google_auth_service.dart';
import 'package:money_manager/services/notification_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  GoogleSignInAccount? _user;
  bool _isLoading = false;
  bool _notifEnabled = true;
  TimeOfDay _notifTime = const TimeOfDay(hour: 21, minute: 0);
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _user = GoogleAuthService.instance.currentUser;
    final prefs = PreferencesService.instance;
    _notifEnabled = prefs.notificationEnabled;
    _notifTime = TimeOfDay(
      hour: prefs.notificationHour,
      minute: prefs.notificationMinute,
    );
    if (_user == null) {
      _trySilentSignIn();
    }
  }

  Future<void> _setNotificationEnabled(bool enabled) async {
    final prefs = PreferencesService.instance;
    await prefs.setNotificationEnabled(enabled);
    if (enabled) {
      await NotificationService.instance.requestPermissions();
      await NotificationService.instance.scheduleDailyReminder();
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
    if (!mounted) return;
    setState(() => _notifEnabled = enabled);
    _setStatus(
      enabled
          ? 'Daily reminder enabled'
          : 'Daily reminder disabled',
      isError: false,
    );
  }

  Future<void> _pickNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notifTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppTheme.primaryColor,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    final prefs = PreferencesService.instance;
    await prefs.setNotificationTime(hour: picked.hour, minute: picked.minute);
    if (_notifEnabled) {
      await NotificationService.instance.scheduleDailyReminder();
    }
    if (!mounted) return;
    setState(() => _notifTime = picked);
    _setStatus(
      'Reminder time updated to ${picked.format(context)}',
      isError: false,
    );
  }

  Future<void> _trySilentSignIn() async {
    final account = await GoogleAuthService.instance.signInSilently();
    if (mounted) setState(() => _user = account);
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final account = await GoogleAuthService.instance.signIn();
      if (mounted) setState(() => _user = account);
    } catch (e) {
      _setStatus('Sign-in failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await GoogleAuthService.instance.signOut();
    if (mounted) setState(() => _user = null);
  }

  Future<void> _backupNow() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    try {
      await BackupService.instance.backupToDrive();
      _setStatus('Backup successful!', isError: false);
    } catch (e) {
      _setStatus('Backup failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    final confirmed = await _showRestoreConfirmation();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    try {
      final found = await BackupService.instance.restoreFromDrive();
      if (found) {
        _setStatus('Restore successful! Restart the app to see changes.',
            isError: false);
      } else {
        _setStatus('No backup found on Google Drive.', isError: true);
      }
    } catch (e) {
      _setStatus('Restore failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showRestoreConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Restore Backup?',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            content: const Text(
              'This will replace ALL current data with the backup from Google Drive. This action cannot be undone.',
              style: TextStyle(color: Colors.white60, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white38)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Restore',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _setStatus(String message, {required bool isError}) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _statusIsError = isError;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return DateFormat('d MMM yyyy, h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ── Google Drive Backup section ────────────────────────────────
            _sectionHeader('Google Drive Backup'),
            const SizedBox(height: 8),
            _driveCard(),

            const SizedBox(height: 28),

            // ── Notifications section ─────────────────────────────────────
            _sectionHeader('Notifications'),
            const SizedBox(height: 8),
            _notificationCard(),

            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              _statusBanner(),
            ],

            const SizedBox(height: 28),

            // ── App info section ───────────────────────────────────────────
            _sectionHeader('About'),
            const SizedBox(height: 8),
            _infoCard(),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _driveCard() {
    final lastBackup =
        _formatDate(PreferencesService.instance.lastBackupDate);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          if (_user == null) ...[
            _cardTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded,
                    color: Colors.white38, size: 20),
              ),
              title: 'Not connected',
              subtitle: 'Sign in to enable cloud backup',
            ),
            const Divider(height: 1, color: Colors.white10),
            _actionTile(
              icon: Icons.login_rounded,
              label: 'Sign in with Google',
              color: AppTheme.primaryColor,
              onTap: _isLoading ? null : _signIn,
              isLoading: _isLoading,
            ),
          ] else ...[
            _cardTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                child: Text(
                  (_user!.displayName ?? _user!.email)
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ),
              title: _user!.displayName ?? _user!.email,
              subtitle: _user!.displayName != null ? _user!.email : null,
            ),
            const Divider(height: 1, color: Colors.white10),
            _cardTile(
              leading: const Icon(Icons.history_rounded,
                  color: Colors.white38, size: 22),
              title: 'Last backup',
              subtitle: lastBackup,
            ),
            const Divider(height: 1, color: Colors.white10),
            _actionTile(
              icon: Icons.backup_rounded,
              label: 'Backup Now',
              color: AppTheme.storeColor,
              onTap: _isLoading ? null : _backupNow,
              isLoading: _isLoading,
            ),
            const Divider(height: 1, color: Colors.white10),
            _actionTile(
              icon: Icons.restore_rounded,
              label: 'Restore from Backup',
              color: Colors.orangeAccent,
              onTap: _isLoading ? null : _restore,
              isLoading: false,
            ),
            const Divider(height: 1, color: Colors.white10),
            _actionTile(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              color: Colors.white38,
              onTap: _isLoading ? null : _signOut,
              isLoading: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardTile({
    required Widget leading,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: color, strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (_statusIsError ? Colors.redAccent : AppTheme.storeColor)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (_statusIsError ? Colors.redAccent : AppTheme.storeColor)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _statusIsError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: _statusIsError ? Colors.redAccent : AppTheme.storeColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: _statusIsError ? Colors.redAccent : AppTheme.storeColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: _notifEnabled,
            onChanged: (v) => _setNotificationEnabled(v),
            activeThumbColor: AppTheme.primaryColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            title: const Text(
              'Daily Reminder',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              _notifEnabled
                  ? 'Enabled at ${_notifTime.format(context)}'
                  : 'Disabled',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          _actionTile(
            icon: Icons.schedule_rounded,
            label: 'Reminder Time: ${_notifTime.format(context)}',
            color: _notifEnabled ? AppTheme.primaryColor : Colors.white38,
            onTap: _notifEnabled ? _pickNotificationTime : null,
            isLoading: false,
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    final prefs = PreferencesService.instance;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          _cardTile(
            leading: const Icon(Icons.currency_exchange_rounded,
                color: Colors.white38, size: 22),
            title: 'Currency',
            subtitle: '${prefs.currencySymbol} — ${prefs.currencyName}',
          ),
          const Divider(height: 1, color: Colors.white10),
          _cardTile(
            leading: const Icon(Icons.info_outline_rounded,
                color: Colors.white38, size: 22),
            title: 'Version',
            subtitle: '1.0.0',
          ),
        ],
      ),
    );
  }
}
