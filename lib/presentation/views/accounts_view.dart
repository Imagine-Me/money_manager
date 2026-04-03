import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/constants/indian_banks.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/domain/entities/account_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';

// ─── Main View ────────────────────────────────────────────────────────────────

class AccountsView extends ConsumerWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            accountsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    e.toString(),
                    style: const TextStyle(color: AppTheme.burnColor),
                  ),
                ),
              ),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const SliverFillRemaining(
                    child: _EmptyAccountsState(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),
                      _TotalBalanceCard(accounts: accounts),
                      const SizedBox(height: 16),
                      ...accounts.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AccountCard(
                              account: a,
                              onEdit: () => _openSheet(context, ref, existing: a),
                              onDelete: () => _confirmDelete(context, ref, a),
                              onSetPrimary: a.isPrimary
                                  ? null
                                  : () => ref
                                      .read(accountRepositoryProvider)
                                      .setPrimary(a.id),
                            ),
                          )),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'accounts_fab',
        onPressed: () => _openSheet(context, ref),
        backgroundColor: AppTheme.primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return const SliverAppBar(
      floating: true,
      backgroundColor: AppTheme.bgColor,
      elevation: 0,
      titleSpacing: 16,
      title: Text(
        'Accounts',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref,
      {AccountEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AccountEntity account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Account',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${account.name}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.burnColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(accountRepositoryProvider).delete(account.id);
    }
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyAccountsState extends StatelessWidget {
  const _EmptyAccountsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Accounts Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add your first account',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Total Balance Card ───────────────────────────────────────────────────────

class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({required this.accounts});

  final List<AccountEntity> accounts;

  @override
  Widget build(BuildContext context) {
    final total = accounts.fold(0.0, (sum, a) => sum + a.balance);
    final count = accounts.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count ${count == 1 ? 'Account' : 'Accounts'}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Balance',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Account Card ─────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.onEdit,
    required this.onDelete,
    this.onSetPrimary,
  });

  final AccountEntity account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetPrimary;

  @override
  Widget build(BuildContext context) {
    final bank = account.bank;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: account.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_rounded,
                color: account.color,
                size: 22,
              ),
            ),
            if (account.isPrimary)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppTheme.goldAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.black,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          account.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: bank != null
            ? Text(
                bank.name,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.formatCompact(account.balance),
              style: TextStyle(
                color: account.color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              color: AppTheme.cardElevated,
              icon: const Icon(Icons.more_vert_rounded,
                  color: Colors.white38, size: 20),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
                if (value == 'primary') onSetPrimary?.call();
              },
              itemBuilder: (_) => [
                if (onSetPrimary != null)
                  const PopupMenuItem(
                    value: 'primary',
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 18, color: AppTheme.goldAccent),
                        SizedBox(width: 8),
                        Text('Set as Primary',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 18, color: Colors.white70),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppTheme.burnColor),
                      SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(color: AppTheme.burnColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Account Sheet ────────────────────────────────────────────────────────────

class _AccountSheet extends ConsumerStatefulWidget {
  const _AccountSheet({this.existing});

  final AccountEntity? existing;

  @override
  ConsumerState<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<_AccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  IndianBank? _selectedBank;
  int _selectedColorIndex = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _balanceController.text = e.balance.toStringAsFixed(
          e.balance == e.balance.roundToDouble() ? 0 : 2);
      _selectedBank = e.bank;
      final colorIdx = AppConstants.categoryColors
          .indexWhere((c) => c.toARGB32() == e.colorValue);
      _selectedColorIndex = colorIdx < 0 ? 0 : colorIdx;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  Text(
                    isEdit ? 'Edit Account' : 'New Account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name field
                  _label('Account Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      hint: 'e.g. My Savings Account',
                      icon: Icons.label_outline_rounded,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Bank selector
                  _label('Bank (optional)'),
                  const SizedBox(height: 8),
                  _BankSelectorButton(
                    selected: _selectedBank,
                    onTap: () => _openBankPicker(),
                    onClear: () => setState(() => _selectedBank = null),
                  ),
                  const SizedBox(height: 20),

                  // Balance field
                  _label('Current Balance'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _balanceController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: _inputDecoration(
                      hint: '0.00',
                      icon: Icons.currency_rupee_rounded,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Balance is required';
                      }
                      if (double.tryParse(v.trim()) == null) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Color picker
                  _label('Color'),
                  const SizedBox(height: 10),
                  _ColorPicker(
                    selectedIndex: _selectedColorIndex,
                    onChanged: (i) => setState(() => _selectedColorIndex = i),
                  ),
                  const SizedBox(height: 28),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEdit ? 'Update Account' : 'Save Account',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      filled: true,
      fillColor: AppTheme.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
    );
  }

  Future<void> _openBankPicker() async {
    final bank = await showModalBottomSheet<IndianBank>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BankSelectorSheet(),
    );
    if (bank != null && mounted) {
      setState(() => _selectedBank = bank);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final color = AppConstants.categoryColors[_selectedColorIndex];
      final account = AccountEntity(
        id: widget.existing?.id ?? 0,
        name: _nameController.text.trim(),
        bankCode: _selectedBank?.code,
        balance: double.parse(_balanceController.text.trim()),
        colorValue: color.toARGB32(),
        isPrimary: widget.existing?.isPrimary ?? false,
      );
      await ref.read(accountRepositoryProvider).save(account);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ─── Bank Selector Button ─────────────────────────────────────────────────────

class _BankSelectorButton extends StatelessWidget {
  const _BankSelectorButton({
    required this.selected,
    required this.onTap,
    required this.onClear,
  });

  final IndianBank? selected;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected != null
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_rounded,
              size: 20,
              color: selected != null
                  ? AppTheme.primaryColor
                  : Colors.white38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected?.name ?? 'Select a bank',
                style: TextStyle(
                  color:
                      selected != null ? Colors.white : Colors.white30,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 18, color: Colors.white38),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

// ─── Bank Selector Sheet ──────────────────────────────────────────────────────

class _BankSelectorSheet extends StatefulWidget {
  const _BankSelectorSheet();

  @override
  State<_BankSelectorSheet> createState() => _BankSelectorSheetState();
}

class _BankSelectorSheetState extends State<_BankSelectorSheet> {
  final _searchController = TextEditingController();
  List<IndianBank> _filtered = IndianBanks.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    setState(() {
      _filtered = IndianBanks.search(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.93,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Select Bank',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search banks…',
                  hintStyle: const TextStyle(color: Colors.white30),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Colors.white38, size: 20),
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 1.5),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Bank list
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No banks found',
                        style: TextStyle(color: Colors.white38),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final bank = _filtered[i];
                        return ListTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_balance_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            bank.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: bank.shortName != null
                              ? Text(
                                  bank.shortName!,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.pop(context, bank),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Color Picker Row ─────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.categoryColors.length,
        itemBuilder: (_, i) {
          final color = AppConstants.categoryColors[i];
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 10),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2.5)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.55),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
