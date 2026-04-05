import 'package:flutter/material.dart';
import 'package:money_manager/core/services/preferences_service.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/presentation/views/home_shell.dart';
import 'package:money_manager/services/backup_service.dart';
import 'package:money_manager/services/google_auth_service.dart';

// ─── Currency data ────────────────────────────────────────────────────────────

class _Currency {
  final String symbol;
  final String name;
  final String code;
  final String locale;
  final String flag;

  const _Currency({
    required this.symbol,
    required this.name,
    required this.code,
    required this.locale,
    required this.flag,
  });
}

const _currencies = [
  _Currency(symbol: '₹', name: 'Indian Rupee',       code: 'INR', locale: 'en_IN', flag: '🇮🇳'),
  _Currency(symbol: '\$', name: 'US Dollar',          code: 'USD', locale: 'en_US', flag: '🇺🇸'),
  _Currency(symbol: '€', name: 'Euro',               code: 'EUR', locale: 'de_DE', flag: '🇪🇺'),
  _Currency(symbol: '£', name: 'British Pound',      code: 'GBP', locale: 'en_GB', flag: '🇬🇧'),
  _Currency(symbol: '¥', name: 'Japanese Yen',       code: 'JPY', locale: 'ja_JP', flag: '🇯🇵'),
  _Currency(symbol: '¥', name: 'Chinese Yuan',       code: 'CNY', locale: 'zh_CN', flag: '🇨🇳'),
  _Currency(symbol: '₩', name: 'South Korean Won',  code: 'KRW', locale: 'ko_KR', flag: '🇰🇷'),
  _Currency(symbol: 'A\$', name: 'Australian Dollar', code: 'AUD', locale: 'en_AU', flag: '🇦🇺'),
  _Currency(symbol: 'C\$', name: 'Canadian Dollar',  code: 'CAD', locale: 'en_CA', flag: '🇨🇦'),
  _Currency(symbol: 'CHF', name: 'Swiss Franc',      code: 'CHF', locale: 'de_CH', flag: '🇨🇭'),
  _Currency(symbol: 'R\$', name: 'Brazilian Real',   code: 'BRL', locale: 'pt_BR', flag: '🇧🇷'),
  _Currency(symbol: '₺', name: 'Turkish Lira',      code: 'TRY', locale: 'tr_TR', flag: '🇹🇷'),
  _Currency(symbol: '₽', name: 'Russian Rouble',    code: 'RUB', locale: 'ru_RU', flag: '🇷🇺'),
  _Currency(symbol: 'Rp', name: 'Indonesian Rupiah', code: 'IDR', locale: 'id_ID', flag: '🇮🇩'),
  _Currency(symbol: 'RM', name: 'Malaysian Ringgit', code: 'MYR', locale: 'ms_MY', flag: '🇲🇾'),
  _Currency(symbol: '฿', name: 'Thai Baht',         code: 'THB', locale: 'th_TH', flag: '🇹🇭'),
  _Currency(symbol: '₱', name: 'Philippine Peso',   code: 'PHP', locale: 'en_PH', flag: '🇵🇭'),
  _Currency(symbol: '₦', name: 'Nigerian Naira',    code: 'NGN', locale: 'en_NG', flag: '🇳🇬'),
  _Currency(symbol: 'R',  name: 'South African Rand', code: 'ZAR', locale: 'en_ZA', flag: '🇿🇦'),
  _Currency(symbol: 'د.إ', name: 'UAE Dirham',      code: 'AED', locale: 'ar_AE', flag: '🇦🇪'),
  _Currency(symbol: '﷼', name: 'Saudi Riyal',       code: 'SAR', locale: 'ar_SA', flag: '🇸🇦'),
  _Currency(symbol: 'S\$', name: 'Singapore Dollar', code: 'SGD', locale: 'en_SG', flag: '🇸🇬'),
  _Currency(symbol: 'kr',  name: 'Swedish Krona',    code: 'SEK', locale: 'sv_SE', flag: '🇸🇪'),
  _Currency(symbol: 'kr',  name: 'Norwegian Krone',  code: 'NOK', locale: 'nb_NO', flag: '🇳🇴'),
  _Currency(symbol: 'kr',  name: 'Danish Krone',     code: 'DKK', locale: 'da_DK', flag: '🇩🇰'),
  _Currency(symbol: 'zł',  name: 'Polish Złoty',     code: 'PLN', locale: 'pl_PL', flag: '🇵🇱'),
  _Currency(symbol: 'Kč',  name: 'Czech Koruna',     code: 'CZK', locale: 'cs_CZ', flag: '🇨🇿'),
  _Currency(symbol: '₫',  name: 'Vietnamese Đồng',  code: 'VND', locale: 'vi_VN', flag: '🇻🇳'),
  _Currency(symbol: '৳',  name: 'Bangladeshi Taka', code: 'BDT', locale: 'bn_BD', flag: '🇧🇩'),
  _Currency(symbol: '₨',  name: 'Pakistani Rupee',  code: 'PKR', locale: 'ur_PK', flag: '🇵🇰'),
];

// ─── View ─────────────────────────────────────────────────────────────────────

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _selectedIndex = 0;
  String _search = '';
  bool _saving = false;
  bool _restoring = false;
  final _searchController = TextEditingController();

  List<_Currency> get _filtered {
    if (_search.isEmpty) return _currencies;
    final q = _search.toLowerCase();
    return _currencies.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.code.toLowerCase().contains(q) ||
        c.symbol.toLowerCase().contains(q)).toList();
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final c = _filtered[_selectedIndex];
    await PreferencesService.instance.saveCurrency(
      symbol: c.symbol,
      name: c.name,
      locale: c.locale,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  Future<void> _restoreFromDrive() async {
    setState(() => _restoring = true);
    try {
      final user = await GoogleAuthService.instance.signIn();
      if (user == null) {
        setState(() => _restoring = false);
        return;
      }
      final found = await BackupService.instance.restoreFromDrive();
      if (!mounted) return;
      if (found) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      } else {
        setState(() => _restoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No backup found on Google Drive.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _restoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    // Reset selected index when search changes
    final selected = _selectedIndex.clamp(0, filtered.isEmpty ? 0 : filtered.length - 1);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.storeColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to\nVaultCash',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Choose your currency to get started.\nThis cannot be changed later.',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() {
                        _search = v;
                        _selectedIndex = 0;
                      }),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Search currency…',
                        hintStyle: TextStyle(color: Colors.white30),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white30, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── List ───────────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No currencies found',
                          style: TextStyle(color: Colors.white38)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final c = filtered[i];
                        final isSelected = i == selected;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withValues(alpha: 0.18)
                                  : AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor.withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.06),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Flag
                                Text(c.flag,
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 14),
                                // Name + code
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white70,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        c.code,
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                // Symbol badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                            .withValues(alpha: 0.3)
                                        : Colors.white
                                            .withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    c.symbol,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.white54,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 10),
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppTheme.primaryColor, size: 20),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ── Confirm button ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_saving || _restoring || filtered.isEmpty)
                      ? null
                      : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              filtered.isEmpty
                                  ? 'Select a currency'
                                  : 'Continue with ${filtered[selected].symbol} ${filtered[selected].code}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            if (filtered.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ],
                        ),
                ),
              ),
            ),

            // ── Restore from Drive ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: (_saving || _restoring) ? null : _restoreFromDrive,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _restoring
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white38, strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download_rounded, size: 18),
                  label: Text(
                    _restoring
                        ? 'Restoring…'
                        : 'Restore from Google Drive',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
