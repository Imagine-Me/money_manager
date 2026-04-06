import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/domain/entities/account_entity.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/recurring_transaction_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/widgets/bank_logo.dart';
import 'package:money_manager/presentation/widgets/category_picker.dart';

// ─── Recurring View ───────────────────────────────────────────────────────────

class RecurringView extends ConsumerWidget {
  const RecurringView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringTransactionListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppTheme.bgColor,
            elevation: 0,
            titleSpacing: 16,
            title: const Text(
              'Recurring',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: recurringAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 2,
                  ),
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
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat_rounded,
                              color: Colors.white12, size: 56),
                          SizedBox(height: 16),
                          Text(
                            'No recurring transactions yet',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 15),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Tap + to add one',
                            style: TextStyle(
                                color: Colors.white24, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecurringCard(
                        recurring: items[i],
                        onEdit: () => _openSheet(context, existing: items[i]),
                        onDelete: () =>
                            _confirmDelete(context, ref, items[i]),
                      ),
                    ),
                    childCount: items.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'recurring_fab',
        onPressed: () => _openSheet(context),
        backgroundColor: AppTheme.primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  void _openSheet(BuildContext context,
      {RecurringTransactionEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecurringSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      RecurringTransactionEntity recurring) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Recurring',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${recurring.title}"? Future transactions will not be created.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.burnColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(recurringTransactionRepositoryProvider)
          .delete(recurring.id);
    }
  }
}

// ─── Recurring Card ───────────────────────────────────────────────────────────

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.recurring,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringTransactionEntity recurring;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isBurn = recurring.type == TransactionType.burn;
    final typeColor = isBurn ? AppTheme.burnColor : AppTheme.storeColor;
    final typeIcon =
        isBurn ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(typeIcon, color: typeColor, size: 18),
        ),
        title: Text(
          recurring.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          _buildSubtitle(),
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.formatCompact(recurring.amount),
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              color: AppTheme.cardElevated,
              icon: const Icon(Icons.more_vert_rounded,
                  color: Colors.white38, size: 20),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 18, color: Colors.white70),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem(
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

  String _buildSubtitle() {
    final freq = recurring.frequency.label;
    final start = recurring.startDate;
    final end = recurring.endDate;
    if (start == null && end == null) return freq;
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    if (start != null && end != null) return '$freq  ·  ${fmt(start)} – ${fmt(end)}';
    if (start != null) return '$freq  ·  from ${fmt(start)}';
    return '$freq  ·  until ${fmt(end!)}';
  }
}

// ─── Recurring Sheet ──────────────────────────────────────────────────────────

class _RecurringSheet extends ConsumerStatefulWidget {
  const _RecurringSheet({this.existing});

  final RecurringTransactionEntity? existing;

  @override
  ConsumerState<_RecurringSheet> createState() => _RecurringSheetState();
}

class _RecurringSheetState extends ConsumerState<_RecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  TransactionType _type = TransactionType.burn;
  CategoryEntity? _selectedCategory;
  AccountEntity? _selectedAccount;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  int _recurDay = DateTime.now().day;
  int _recurMonth = DateTime.now().month;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _amountController.text = e.amount.toStringAsFixed(2);
      _type = e.type;
      _selectedCategory = e.category;
      _frequency = e.frequency;
      _recurDay = e.recurDay;
      _recurMonth = e.recurMonth;
      _startDate = e.startDate;
      _endDate = e.endDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountListProvider);
    final accounts = accountsAsync.valueOrNull ?? [];

    AccountEntity? effectiveAccount = _selectedAccount;
    if (effectiveAccount == null && accounts.isNotEmpty) {
      final existingId = widget.existing?.accountId;
      if (existingId != null) {
        try {
          effectiveAccount = accounts.firstWhere((a) => a.id == existingId);
        } catch (_) {}
      }
      effectiveAccount ??= accounts.firstWhere(
        (a) => a.isPrimary,
        orElse: () => accounts.first,
      );
    }

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
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

                  // ─── Header ────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.repeat_rounded,
                            color: AppTheme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.existing == null
                            ? 'New Recurring'
                            : 'Edit Recurring',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── Type toggle ───────────────────────────────────────
                  _RecurringTypeToggle(
                    value: _type,
                    onChanged: (v) => setState(() {
                      _type = v;
                      _selectedCategory = null;
                    }),
                  ),
                  const SizedBox(height: 20),

                  // ─── Title ─────────────────────────────────────────────
                  const Text('TITLE',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'e.g. Netflix, Salary…',
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(Icons.title_rounded,
                          color: Colors.white38, size: 20),
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
                        borderSide: const BorderSide(
                            color: AppTheme.primaryColor, width: 1.5),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: 20),

                  // ─── Amount ────────────────────────────────────────────
                  const Text('AMOUNT',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(Icons.currency_rupee_rounded,
                          color: Colors.white38, size: 20),
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
                        borderSide: const BorderSide(
                            color: AppTheme.primaryColor, width: 1.5),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter amount';
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return 'Invalid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ─── Category ──────────────────────────────────────────
                  const Text('CATEGORY',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  CategoryPicker(
                    selected: _selectedCategory,
                    type: _type,
                    onChanged: (c) => setState(() => _selectedCategory = c),
                  ),
                  const SizedBox(height: 20),

                  // ─── Account ───────────────────────────────────────────
                  if (accounts.isNotEmpty) ...[
                    const Text('ACCOUNT',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    _AccountDropdown(
                      label: '',
                      accounts: accounts,
                      selected: effectiveAccount ?? accounts.first,
                      onChanged: (a) =>
                          setState(() => _selectedAccount = a),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ─── Schedule ──────────────────────────────────────────
                  const Text('SCHEDULE',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  _RecurringConfig(
                    frequency: _frequency,
                    recurDay: _recurDay,
                    recurMonth: _recurMonth,
                    onFrequencyChanged: (f) => setState(() {
                      _frequency = f;
                      _recurDay = f == RecurringFrequency.weekly
                          ? DateTime.now().weekday
                          : DateTime.now().day;
                      _recurMonth = DateTime.now().month;
                    }),
                    onDayChanged: (d) => setState(() => _recurDay = d),
                    onMonthChanged: (m) => setState(() => _recurMonth = m),
                  ),
                  const SizedBox(height: 20),

                  // ─── Date range ────────────────────────────────────────
                  const Text('DATE RANGE (OPTIONAL)',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerTile(
                          label: 'Start',
                          date: _startDate,
                          onPick: () => _pickDate(
                            initial: _startDate,
                            onPicked: (d) => setState(() => _startDate = d),
                          ),
                          onClear: () => setState(() => _startDate = null),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DatePickerTile(
                          label: 'End',
                          date: _endDate,
                          onPick: () => _pickDate(
                            initial: _endDate ?? _startDate,
                            firstDate: _startDate,
                            onPicked: (d) => setState(() => _endDate = d),
                          ),
                          onClear: () => setState(() => _endDate = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ─── Save ──────────────────────────────────────────────
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
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final accounts = ref.read(accountListProvider).valueOrNull ?? [];
      AccountEntity? resolvedAccount = _selectedAccount;
      if (resolvedAccount == null && accounts.isNotEmpty) {
        final existingId = widget.existing?.accountId;
        if (existingId != null) {
          try {
            resolvedAccount = accounts.firstWhere((a) => a.id == existingId);
          } catch (_) {}
        }
        resolvedAccount ??= accounts.firstWhere(
          (a) => a.isPrimary,
          orElse: () => accounts.first,
        );
      }

      final recurRepo = ref.read(recurringTransactionRepositoryProvider);
      final entity = RecurringTransactionEntity(
        id: widget.existing?.id ?? 0,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        type: _type,
        note: '',
        frequency: _frequency,
        recurDay: _recurDay,
        recurMonth: _recurMonth,
        accountId: resolvedAccount?.id,
        startDate: _startDate,
        endDate: _endDate,
        category: _selectedCategory,
      );
      await recurRepo.save(entity, _selectedCategory!);
      await recurRepo.processDueTransactions();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing == null
                ? 'Recurring transaction saved!'
                : 'Recurring transaction updated!'),
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

  Future<void> _pickDate({
    DateTime? initial,
    DateTime? firstDate,
    required void Function(DateTime) onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppTheme.primaryColor,
            onPrimary: Colors.white,
            surface: AppTheme.surfaceColor,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }
}

// ─── Date Picker Tile ─────────────────────────────────────────────────────────

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDate
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 15,
              color: hasDate ? AppTheme.primaryColor : Colors.white38,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: hasDate
                          ? AppTheme.primaryColor
                          : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    hasDate
                        ? '${date!.day.toString().padLeft(2, '0')}/'
                            '${date!.month.toString().padLeft(2, '0')}/'
                            '${date!.year}'
                        : 'Not set',
                    style: TextStyle(
                      color: hasDate ? Colors.white : Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 15, color: Colors.white38),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecurringTypeToggle extends StatelessWidget {
  const _RecurringTypeToggle({
    required this.value,
    required this.onChanged,
  });

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    const types = [TransactionType.burn, TransactionType.store];
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: types.map((type) {
          final isSelected = value == type;
          final color = type == TransactionType.burn
              ? AppTheme.burnColor
              : AppTheme.storeColor;
          final icon = type == TransactionType.burn
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded;
          final label =
              type == TransactionType.burn ? 'Expense' : 'Income';
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: color.withValues(alpha: 0.5))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        size: 16,
                        color: isSelected ? color : Colors.white38),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? color : Colors.white38,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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

// ─── Recurring Config ─────────────────────────────────────────────────────────

class _RecurringConfig extends StatelessWidget {
  const _RecurringConfig({
    required this.frequency,
    required this.recurDay,
    required this.recurMonth,
    required this.onFrequencyChanged,
    required this.onDayChanged,
    required this.onMonthChanged,
  });

  final RecurringFrequency frequency;
  final int recurDay;
  final int recurMonth;
  final ValueChanged<RecurringFrequency> onFrequencyChanged;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<int> onMonthChanged;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: RecurringFrequency.values.map((f) {
              final isSelected = frequency == f;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onFrequencyChanged(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 36,
                    margin: EdgeInsets.only(
                        right: f != RecurringFrequency.yearly ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.2)
                          : AppTheme.cardElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.6)
                            : Colors.white10,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        f.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.white38,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          if (frequency == RecurringFrequency.weekly) ...[
            const Text('Repeat on',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final weekday = i + 1;
                final isSelected = recurDay == weekday;
                return GestureDetector(
                  onTap: () => onDayChanged(weekday),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.cardElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _weekdays[i][0],
                        style: TextStyle(
                          color:
                              isSelected ? Colors.black : Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ] else if (frequency == RecurringFrequency.monthly) ...[
            Row(
              children: [
                const Text('Day of month',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(
                  child: _DayDropdown(
                    value: recurDay,
                    max: 31,
                    onChanged: onDayChanged,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Text('Month',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<int>(
                    value: recurMonth,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceColor,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    underline:
                        Container(height: 1, color: Colors.white12),
                    onChanged: (v) {
                      if (v != null) onMonthChanged(v);
                    },
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(_months[i]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Day',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: _DayDropdown(
                    value: recurDay,
                    max: 31,
                    onChanged: onDayChanged,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Day Dropdown ─────────────────────────────────────────────────────────────

class _DayDropdown extends StatelessWidget {
  const _DayDropdown({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value.clamp(1, max),
      isExpanded: true,
      dropdownColor: AppTheme.surfaceColor,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      underline: Container(height: 1, color: Colors.white12),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      items: List.generate(
        max,
        (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
      ),
    );
  }
}

// ─── Account Dropdown ─────────────────────────────────────────────────────────

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.label,
    required this.accounts,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<AccountEntity> accounts;
  final AccountEntity selected;
  final ValueChanged<AccountEntity> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected.color.withValues(alpha: 0.4)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AccountEntity>(
              value: accounts.contains(selected) ? selected : accounts.first,
              isExpanded: true,
              dropdownColor: AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              icon: const Icon(Icons.expand_more_rounded,
                  color: Colors.white38, size: 18),
              items: accounts.map((a) {
                return DropdownMenuItem(
                  value: a,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: BankLogo(
                            bank: a.bank,
                            color: a.color,
                            size: 24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (a) {
                if (a != null) onChanged(a);
              },
            ),
          ),
        ),
      ],
    );
  }
}
