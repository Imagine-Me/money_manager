import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/domain/entities/account_entity.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/widgets/bank_logo.dart';
import 'package:money_manager/presentation/widgets/category_picker.dart';
import 'package:money_manager/services/backup_service.dart';

class AddTransactionView extends ConsumerStatefulWidget {
  const AddTransactionView({super.key, this.existing, this.initialDate});

  final TransactionEntity? existing;
  final DateTime? initialDate;

  @override
  ConsumerState<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends ConsumerState<AddTransactionView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.burn;
  CategoryEntity? _selectedCategory;
  AccountEntity? _selectedAccount; // null = use primary
  AccountEntity? _toAccount; // destination for transfer type
  bool _noFromAccount = false; // transfer: true = external source, no from account
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    if (widget.existing != null) {
      final e = widget.existing!;
      _titleController.text = e.title;
      _amountController.text = e.amount.toStringAsFixed(2);
      _noteController.text = e.note;
      _type = e.type;
      _selectedCategory = e.category;
      _selectedDate = e.date;
      // accountId resolved lazily in build via accountListProvider
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountListProvider);
    final accounts = accountsAsync.valueOrNull ?? [];

    // Resolve account to show in picker:
    // for existing tx use saved accountId; for new tx use primary / first.
    AccountEntity? effectiveAccount = _selectedAccount;
    if (effectiveAccount == null && accounts.isNotEmpty) {
      final existingAccountId = widget.existing?.accountId;
      if (existingAccountId != null) {
        try {
          effectiveAccount =
              accounts.firstWhere((a) => a.id == existingAccountId);
        } catch (_) {}
      }
      effectiveAccount ??= accounts.firstWhere(
        (a) => a.isPrimary,
        orElse: () => accounts.first,
      );
    }

    // Resolve destination account for transfer
    AccountEntity? effectiveTo = _toAccount;
    if (_type == TransactionType.transfer &&
        effectiveTo == null &&
        accounts.isNotEmpty) {
      final toId = widget.existing?.toAccountId;
      if (toId != null) {
        try {
          effectiveTo = accounts.firstWhere((a) => a.id == toId);
        } catch (_) {}
      }
      effectiveTo ??= accounts.firstWhere(
        (a) => a.id != effectiveAccount?.id,
        orElse: () => accounts.last,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Transaction' : 'Edit Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Type Toggle ────────────────────────────────────────────────
              _TypeToggle(
                value: _type,
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 20),

              // ─── Title + Category (hidden for transfers) ──────────────────
              if (_type != TransactionType.transfer) ...[  
                _FieldLabel(label: 'Title'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Lunch at Café',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => _onTitleChanged(),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                ),

                // ─── Smart Category Search Results ──────────────────────────
                _CategorySuggestions(
                  query: _titleController.text,
                  onSelect: (cat) => setState(() => _selectedCategory = cat),
                ),
                const SizedBox(height: 20),

                // ─── Selected Category chip ─────────────────────────────────
                _FieldLabel(label: 'Category'),
                const SizedBox(height: 8),
                CategoryPicker(
                  selected: _selectedCategory,
                  type: _type,
                  onChanged: (cat) => setState(() => _selectedCategory = cat),
                ),
                const SizedBox(height: 20),
              ],

              // ─── Amount ──────────────────────────────────────────────────────
              _FieldLabel(label: 'Amount (${AppConstants.currencySymbol})'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an amount';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ─── Date ────────────────────────────────────────────────────
              _FieldLabel(label: 'Date'),
              const SizedBox(height: 8),
              _DatePicker(
                selected: _selectedDate,
                onChanged: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 20),



              // ─── Account / From + To (for transfer) ──────────────────────
              if (accounts.isNotEmpty) ...[  
                if (_type == TransactionType.transfer) ...[  
                  // ── From Account (optional) ──
                  Row(
                    children: [
                      const _FieldLabel(label: 'From Account'),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() {
                          _noFromAccount = !_noFromAccount;
                          if (_noFromAccount) _selectedAccount = null;
                        }),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'External',
                              style: TextStyle(
                                color: _noFromAccount
                                    ? AppTheme.primaryColor
                                    : Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _noFromAccount
                                  ? Icons.toggle_on_rounded
                                  : Icons.toggle_off_rounded,
                              color: _noFromAccount
                                  ? AppTheme.primaryColor
                                  : Colors.white24,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_noFromAccount)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.input_rounded,
                              color: Colors.white38, size: 18),
                          const SizedBox(width: 10),
                          const Text(
                            'External source (salary, gift, etc.)',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    _AccountPicker(
                      accounts: accounts,
                      selected: effectiveAccount,
                      onChanged: (a) => setState(() => _selectedAccount = a),
                    ),
                  const SizedBox(height: 16),
                  _FieldLabel(label: 'To Account'),
                  const SizedBox(height: 8),
                  _AccountPicker(
                    accounts: accounts,
                    selected: effectiveTo,
                    onChanged: (a) => setState(() => _toAccount = a),
                  ),
                ] else ...[  
                  _FieldLabel(label: 'Account'),
                  const SizedBox(height: 8),
                  _AccountPicker(
                    accounts: accounts,
                    selected: effectiveAccount,
                    onChanged: (a) => setState(() => _selectedAccount = a),
                  ),
                ],
                const SizedBox(height: 20),
              ],

              // ─── Note ─────────────────────────────────────────────────────
              _FieldLabel(label: 'Note (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Any additional notes…',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // ─── Save Button ──────────────────────────────────────────────
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTitleChanged() {
    final query = _titleController.text;
    if (query.length >= 2) {
      ref.read(categorySearchProvider.notifier).search(query);
    } else {
      ref.read(categorySearchProvider.notifier).clear();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_type != TransactionType.transfer && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final txRepo = ref.read(transactionRepositoryProvider);
      final amount = double.parse(_amountController.text);
      final accounts = ref.read(accountListProvider).valueOrNull ?? [];

      // Resolve "from" account
      AccountEntity? resolvedAccount = _selectedAccount;
      if (resolvedAccount == null && accounts.isNotEmpty) {
        final existingAccountId = widget.existing?.accountId;
        if (existingAccountId != null) {
          try {
            resolvedAccount =
                accounts.firstWhere((a) => a.id == existingAccountId);
          } catch (_) {}
        }
        resolvedAccount ??= accounts.firstWhere(
          (a) => a.isPrimary,
          orElse: () => accounts.first,
        );
      }

      if (_type == TransactionType.transfer) {
        // Resolve "to" account
        AccountEntity? resolvedTo = _toAccount;
        if (resolvedTo == null && accounts.isNotEmpty) {
          final toId = widget.existing?.toAccountId;
          if (toId != null) {
            try {
              resolvedTo = accounts.firstWhere((a) => a.id == toId);
            } catch (_) {}
          }
          resolvedTo ??= accounts.firstWhere(
            (a) => a.id != resolvedAccount?.id,
            orElse: () => accounts.last,
          );
        }
        // When noFromAccount, don't use any from account
        final fromAccount = _noFromAccount ? null : resolvedAccount;
        final fromName = fromAccount?.name ?? 'External';
        final title = '$fromName → ${resolvedTo?.name ?? 'Account'}';
        final tx = TransactionEntity(
          id: widget.existing?.id ?? 0,
          title: title,
          amount: amount,
          date: _selectedDate,
          type: TransactionType.transfer,
          note: '',
          accountId: fromAccount?.id,
          toAccountId: resolvedTo?.id,
        );
        await txRepo.save(tx);
      } else {
        final tx = TransactionEntity(
          id: widget.existing?.id ?? 0,
          title: _titleController.text.trim(),
          amount: amount,
          date: _selectedDate,
          type: _type,
          note: _noteController.text.trim(),
          category: _selectedCategory,
          accountId: resolvedAccount?.id,
        );
        await txRepo.save(tx, _selectedCategory!);
      }

      if (mounted) {
        BackupService.instance.triggerAutoSync();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.existing == null
                    ? 'Transaction saved!'
                    : 'Transaction updated!'),
            backgroundColor: AppTheme.storeColor.withValues(alpha: 0.8),
          ),
        );
      }
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

// ─── Type Toggle ───────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.value, required this.onChanged});

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: TransactionType.values.map((type) {
          final isSelected = value == type;
          final color = switch (type) {
            TransactionType.burn => AppTheme.burnColor,
            TransactionType.store => AppTheme.storeColor,
            TransactionType.transfer => AppTheme.primaryColor,
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: color.withValues(alpha: 0.5))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      switch (type) {
                        TransactionType.burn =>
                          Icons.local_fire_department_rounded,
                        TransactionType.store => Icons.savings_rounded,
                        TransactionType.transfer =>
                          Icons.compare_arrows_rounded,
                      },
                      size: 18,
                      color: isSelected ? color : Colors.white38,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type.label,
                      style: TextStyle(
                        color: isSelected ? color : Colors.white38,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Category Suggestions (Smart Match) ───────────────────────────────────────

class _CategorySuggestions extends ConsumerWidget {
  const _CategorySuggestions({required this.query, required this.onSelect});

  final String query;
  final ValueChanged<CategoryEntity> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(categorySearchProvider);
    if (suggestions.isEmpty || query.length < 2) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: suggestions
            .take(4)
            .map(
              (cat) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: cat.color.withValues(alpha: 0.2),
                  radius: 18,
                  child: Icon(cat.icon, color: cat.color, size: 16),
                ),
                title: Text(cat.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text(cat.type.label,
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
                onTap: () {
                  onSelect(cat);
                  ref.read(categorySearchProvider.notifier).clear();
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Date Picker ──────────────────────────────────────────────────────────────

class _DatePicker extends StatelessWidget {
  const _DatePicker({required this.selected, required this.onChanged});

  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selected,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme.copyWith(
                    primary: AppTheme.primaryColor,
                    onSurface: Colors.white,
                  ),
              dialogTheme: const DialogThemeData(
                backgroundColor: AppTheme.surfaceColor,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: Colors.white54, size: 20),
            const SizedBox(width: 12),
            Text(
              _format(selected),
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  String _format(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(d.year, d.month, d.day);
    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ─── Account Picker ────────────────────────────────────────────────────────────

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.accounts,
    required this.selected,
    required this.onChanged,
  });

  final List<AccountEntity> accounts;
  final AccountEntity? selected;
  final ValueChanged<AccountEntity> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected != null
                ? selected!.color.withValues(alpha: 0.5)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: (selected?.color ?? AppTheme.primaryColor)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: BankLogo(
                bank: selected?.bank,
                color: selected?.color ?? Colors.white38,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    selected?.name ?? 'Select account',
                    style: TextStyle(
                      color: selected != null ? Colors.white : Colors.white38,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (selected?.bank != null)
                    Text(
                      selected!.bank!.name,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (selected != null)
              Text(
                '₹${selected!.balance.toStringAsFixed(0)}',
                style: TextStyle(
                  color: selected!.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.unfold_more_rounded,
                size: 18, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ...accounts.map((account) {
                final isSelected = selected?.id == account.id;
                return ListTile(
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: account.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: BankLogo(
                          bank: account.bank,
                          color: account.color,
                          size: 40,
                        ),
                      ),
                      if (account.isPrimary)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: AppTheme.goldAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.star_rounded,
                                color: Colors.black, size: 9),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    account.name,
                    style: TextStyle(
                      color: isSelected ? account.color : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: account.bank != null
                      ? Text(
                          account.bank!.name,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${account.balance.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: account.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle_rounded,
                            color: account.color, size: 18),
                      ],
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onChanged(account);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

