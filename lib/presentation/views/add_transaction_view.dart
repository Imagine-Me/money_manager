import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/domain/entities/account_entity.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/domain/entities/recurring_transaction_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/widgets/bank_logo.dart';

class AddTransactionView extends ConsumerStatefulWidget {
  const AddTransactionView({super.key, this.existing});

  final TransactionEntity? existing;

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
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  // ─── Recurring state ───────────────────────────────────────────────────────
  bool _isRecurring = false;
  RecurringFrequency _recurFrequency = RecurringFrequency.monthly;
  int _recurDay = DateTime.now().day; // day-of-month default
  int _recurMonth = DateTime.now().month; // for yearly

  @override
  void initState() {
    super.initState();
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
                _CategoryPicker(
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

              // ─── Date (hidden when recurring) ─────────────────────────
              if (!_isRecurring) ...[
                _FieldLabel(label: 'Date'),
                const SizedBox(height: 8),
                _DatePicker(
                  selected: _selectedDate,
                  onChanged: (d) => setState(() => _selectedDate = d),
                ),
                const SizedBox(height: 20),
              ],

              // ─── Recurring toggle + config (burn/store only) ──────────
              if (_type != TransactionType.transfer) ...[
                _RecurringToggle(
                  isRecurring: _isRecurring,
                  onChanged: (v) => setState(() {
                    _isRecurring = v;
                    if (v) {
                      // Reset to sensible defaults
                      _recurFrequency = RecurringFrequency.monthly;
                      _recurDay = DateTime.now().day;
                      _recurMonth = DateTime.now().month;
                    }
                  }),
                ),
                if (_isRecurring) ...[
                  const SizedBox(height: 12),
                  _RecurringConfig(
                    frequency: _recurFrequency,
                    recurDay: _recurDay,
                    recurMonth: _recurMonth,
                    onFrequencyChanged: (f) => setState(() {
                      _recurFrequency = f;
                      _recurDay = f == RecurringFrequency.weekly
                          ? DateTime.now().weekday
                          : DateTime.now().day;
                      _recurMonth = DateTime.now().month;
                    }),
                    onDayChanged: (d) => setState(() => _recurDay = d),
                    onMonthChanged: (m) => setState(() => _recurMonth = m),
                  ),
                ],
                const SizedBox(height: 20),
              ],

              // ─── Account / From + To (for transfer) ──────────────────────
              if (accounts.isNotEmpty) ...[  
                if (_type == TransactionType.transfer) ...[  
                  _FieldLabel(label: 'From Account'),
                  const SizedBox(height: 8),
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
        final title =
            '${resolvedAccount?.name ?? 'Account'} → ${resolvedTo?.name ?? 'Account'}';
        final tx = TransactionEntity(
          id: widget.existing?.id ?? 0,
          title: title,
          amount: amount,
          date: _selectedDate,
          type: TransactionType.transfer,
          note: '',
          accountId: resolvedAccount?.id,
          toAccountId: resolvedTo?.id,
        );
        await txRepo.save(tx);
      } else if (_isRecurring) {
        // ── Save as a recurring template ──────────────────────────────
        final recurRepo = ref.read(recurringTransactionRepositoryProvider);
        final entity = RecurringTransactionEntity(
          id: 0,
          title: _titleController.text.trim(),
          amount: amount,
          type: _type,
          note: _noteController.text.trim(),
          frequency: _recurFrequency,
          recurDay: _recurDay,
          recurMonth: _recurMonth,
          accountId: resolvedAccount?.id,
          category: _selectedCategory,
        );
        await recurRepo.save(entity, _selectedCategory!);
        // Immediately process in case today is already the due date.
        await recurRepo.processDueTransactions();
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isRecurring
                    ? 'Recurring transaction saved!'
                    : widget.existing == null
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

// ─── Category Picker ───────────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.selected,
    required this.type,
    required this.onChanged,
  });

  final CategoryEntity? selected;
  final TransactionType type;
  final ValueChanged<CategoryEntity?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCategorySheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected != null
                ? selected!.color.withValues(alpha: 0.5)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            if (selected != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected!.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(selected!.icon, color: selected!.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected!.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      selected!.type.label,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Icon(Icons.category_rounded, color: Colors.white38, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Select or create a category',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ],
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(
        currentType: type,
        onSelect: onChanged,
      ),
    );
  }
}

// ─── Category Bottom Sheet ─────────────────────────────────────────────────────

class _CategorySheet extends ConsumerStatefulWidget {
  const _CategorySheet({required this.currentType, required this.onSelect});

  final TransactionType currentType;
  final ValueChanged<CategoryEntity?> onSelect;

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  // Navigation state
  CategoryEntity? _selectedParent;

  // New/edit form state
  bool _showNewForm = false;
  CategoryEntity? _editingCategory;
  int? _newCategoryParentId;
  final _nameController = TextEditingController();
  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;
  late TransactionType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
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

            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 16, 12),
              child: Row(
                children: [
                  if (_selectedParent != null && !_showNewForm)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white70),
                      onPressed: () =>
                          setState(() => _selectedParent = null),
                    )
                  else
                    const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      _showNewForm
                          ? (_editingCategory != null
                              ? 'Edit Category'
                              : 'New Category')
                          : (_selectedParent != null
                              ? _selectedParent!.name
                              : 'Category'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _toggleNewForm,
                    icon: Icon(_showNewForm ? Icons.close : Icons.add,
                        size: 16),
                    label: Text(_showNewForm ? 'Cancel' : 'New'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),

            // New / edit form
            if (_showNewForm)
              categoriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (cats) => _NewCategoryForm(
                  nameController: _nameController,
                  selectedColorIndex: _selectedColorIndex,
                  selectedIconIndex: _selectedIconIndex,
                  selectedType: _selectedType,
                  isEditing: _editingCategory != null,
                  onColorChanged: (i) =>
                      setState(() => _selectedColorIndex = i),
                  onIconChanged: (i) =>
                      setState(() => _selectedIconIndex = i),
                  onTypeChanged: (t) => setState(() => _selectedType = t),
                  onSave: _saveCategory,
                  parentOptions: cats
                      .where((c) => c.parentId == null)
                      .toList(),
                  selectedParentId: _newCategoryParentId,
                  onParentChanged: (id) =>
                      setState(() => _newCategoryParentId = id),
                ),
              ),

            // Category list / grid
            if (!_showNewForm)
              Expanded(
                child: categoriesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor),
                  ),
                  error: (e, _) => Center(
                    child: Text(e.toString(),
                        style:
                            const TextStyle(color: AppTheme.burnColor)),
                  ),
                  data: (cats) => _selectedParent == null
                      ? _ParentGrid(
                          cats: cats,
                          currentType: widget.currentType,
                          controller: controller,
                          onParentTapped: (parent) {
                            final hasSubs =
                                cats.any((c) => c.parentId == parent.id);
                            if (hasSubs) {
                              setState(() => _selectedParent = parent);
                            } else {
                              widget.onSelect(parent);
                              Navigator.of(context).pop();
                            }
                          },
                          onEdit: (cat) => _startEdit(cat, cats),
                          onDelete: _confirmDelete,
                        )
                      : _SubcategoryList(
                          parent: _selectedParent!,
                          subs: cats
                              .where((c) =>
                                  c.parentId == _selectedParent!.id)
                              .toList(),
                          controller: controller,
                          onSelect: (sub) {
                            widget.onSelect(sub);
                            Navigator.of(context).pop();
                          },
                          onEdit: (cat) => _startEdit(cat, cats),
                          onDelete: _confirmDelete,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _toggleNewForm() {
    setState(() {
      _showNewForm = !_showNewForm;
      if (!_showNewForm) {
        _editingCategory = null;
        _newCategoryParentId = null;
        _nameController.clear();
        _selectedColorIndex = 0;
        _selectedIconIndex = 0;
        _selectedType = widget.currentType;
      }
    });
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final color = AppConstants.categoryColors[_selectedColorIndex];
    final icon = AppConstants.categoryIconOptions[_selectedIconIndex];
    final isEdit = _editingCategory != null;

    final entity = CategoryEntity(
      id: isEdit ? _editingCategory!.id : 0,
      name: name,
      colorValue: color.toARGB32(),
      iconCodePoint: icon.codePoint,
      iconFontFamily: icon.fontFamily ?? 'MaterialIcons',
      type: _selectedType,
      parentId: isEdit ? _editingCategory!.parentId : _newCategoryParentId,
    );

    final savedId = await ref.read(categoryRepositoryProvider).save(entity);

    if (isEdit) {
      if (mounted) {
        setState(() {
          _showNewForm = false;
          _editingCategory = null;
          _newCategoryParentId = null;
          _nameController.clear();
          _selectedColorIndex = 0;
          _selectedIconIndex = 0;
          _selectedType = widget.currentType;
        });
      }
    } else {
      final saved =
          await ref.read(categoryRepositoryProvider).getById(savedId);
      if (saved != null && mounted) {
        widget.onSelect(saved);
        Navigator.of(context).pop();
      }
    }
  }

  void _startEdit(CategoryEntity cat, List<CategoryEntity> allCats) {
    final colorIdx = AppConstants.categoryColors
        .indexWhere((c) => c.toARGB32() == cat.colorValue);
    final iconIdx = AppConstants.categoryIconOptions
        .indexWhere((ic) => ic.codePoint == cat.iconCodePoint);
    _nameController.text = cat.name;
    setState(() {
      _editingCategory = cat;
      _newCategoryParentId = cat.parentId;
      _selectedColorIndex = colorIdx < 0 ? 0 : colorIdx;
      _selectedIconIndex = iconIdx < 0 ? 0 : iconIdx;
      _selectedType = cat.type;
      _showNewForm = true;
    });
  }

  Future<void> _confirmDelete(CategoryEntity cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Category',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${cat.name}"? Existing transactions won\'t be affected.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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
      await ref.read(categoryRepositoryProvider).delete(cat.id);
    }
  }
}

// ─── Parent Category Grid ──────────────────────────────────────────────────────

class _ParentGrid extends StatelessWidget {
  const _ParentGrid({
    required this.cats,
    required this.currentType,
    required this.controller,
    required this.onParentTapped,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CategoryEntity> cats;
  final TransactionType currentType;
  final ScrollController controller;
  final ValueChanged<CategoryEntity> onParentTapped;
  final ValueChanged<CategoryEntity> onEdit;
  final ValueChanged<CategoryEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    final parents = cats
        .where((c) => c.parentId == null && c.type == currentType)
        .toList();

    if (parents.isEmpty) {
      return const Center(
        child: Text(
          'No categories yet.\nTap "New" to create one.',
          style: TextStyle(color: Colors.white38),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: parents.length,
      itemBuilder: (_, i) {
        final parent = parents[i];
        final hasSubs = cats.any((c) => c.parentId == parent.id);
        return GestureDetector(
          onLongPress: () => _showActions(context, parent),
          onTap: () => onParentTapped(parent),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: parent.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      Icon(parent.icon, color: parent.color, size: 22),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    parent.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSubs)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.chevron_right_rounded,
                        color: Colors.white24, size: 14),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActions(BuildContext context, CategoryEntity cat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.white70),
              title: const Text('Edit',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                onEdit(cat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.burnColor),
              title: const Text('Delete',
                  style: TextStyle(color: AppTheme.burnColor)),
              onTap: () {
                Navigator.pop(context);
                onDelete(cat);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subcategory List ──────────────────────────────────────────────────────────

class _SubcategoryList extends StatelessWidget {
  const _SubcategoryList({
    required this.parent,
    required this.subs,
    required this.controller,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryEntity parent;
  final List<CategoryEntity> subs;
  final ScrollController controller;
  final ValueChanged<CategoryEntity> onSelect;
  final ValueChanged<CategoryEntity> onEdit;
  final ValueChanged<CategoryEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    if (subs.isEmpty) {
      return const Center(
        child: Text('No subcategories.',
            style: TextStyle(color: Colors.white38)),
      );
    }
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: subs.length,
      itemBuilder: (_, i) {
        final sub = subs[i];
        return ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: CircleAvatar(
            backgroundColor: sub.color.withValues(alpha: 0.2),
            child: Icon(sub.icon, color: sub.color, size: 20),
          ),
          title:
              Text(sub.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(parent.name,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 11)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded,
                    size: 18, color: Colors.white38),
                onPressed: () => onEdit(sub),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppTheme.burnColor),
                onPressed: () => onDelete(sub),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          onTap: () => onSelect(sub),
        );
      },
    );
  }
}

// ─── New Category Form ─────────────────────────────────────────────────────────

class _NewCategoryForm extends StatelessWidget {
  const _NewCategoryForm({
    required this.nameController,
    required this.selectedColorIndex,
    required this.selectedIconIndex,
    required this.onColorChanged,
    required this.onIconChanged,
    required this.onSave,
    required this.isEditing,
    required this.selectedType,
    required this.onTypeChanged,
    required this.parentOptions,
    required this.selectedParentId,
    required this.onParentChanged,
  });

  final TextEditingController nameController;
  final int selectedColorIndex;
  final int selectedIconIndex;
  final ValueChanged<int> onColorChanged;
  final ValueChanged<int> onIconChanged;
  final VoidCallback onSave;
  final bool isEditing;
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onTypeChanged;
  final List<CategoryEntity> parentOptions;
  final int? selectedParentId;
  final ValueChanged<int?> onParentChanged;

  @override
  Widget build(BuildContext context) {
    final filteredParents =
        parentOptions.where((c) => c.type == selectedType).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
          // Type toggle
          Row(
            children: TransactionType.values.map((t) {
              final isSelected = selectedType == t;
              final color = t == TransactionType.burn
                  ? AppTheme.burnColor
                  : AppTheme.storeColor;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTypeChanged(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 38,
                    margin: EdgeInsets.only(
                        right: t == TransactionType.burn ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.2)
                          : AppTheme.cardElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.6)
                            : Colors.white10,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          t == TransactionType.burn
                              ? Icons.local_fire_department_rounded
                              : Icons.savings_rounded,
                          size: 14,
                          color: isSelected ? color : Colors.white38,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          t.label,
                          style: TextStyle(
                            color: isSelected ? color : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Name field
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Category name',
              prefixIcon: Icon(Icons.label_rounded),
            ),
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),

          // Parent selector (only for new categories)
          if (!isEditing && filteredParents.isNotEmpty) ...[
            const Text('Parent (optional)',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            DropdownButton<int?>(
              value: filteredParents.any((c) => c.id == selectedParentId)
                  ? selectedParentId
                  : null,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceColor,
              hint: const Text('None (top-level)',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              underline: Container(
                  height: 1, color: Colors.white12),
              onChanged: onParentChanged,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('None (top-level)',
                      style: TextStyle(color: Colors.white54)),
                ),
                ...filteredParents.map(
                  (c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(c.icon, color: c.color, size: 16),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Color row
          const Text('Color',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.categoryColors.length,
              itemBuilder: (_, i) {
                final selected = i == selectedColorIndex;
                return GestureDetector(
                  onTap: () => onColorChanged(i),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppConstants.categoryColors[i],
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Icon row
          const Text('Icon',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.categoryIconOptions.length,
              itemBuilder: (_, i) {
                final selected = i == selectedIconIndex;
                final color =
                    AppConstants.categoryColors[selectedColorIndex];
                return GestureDetector(
                  onTap: () => onIconChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.3)
                          : AppTheme.cardElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(color: color)
                          : Border.all(color: Colors.white10),
                    ),
                    child: Icon(
                      AppConstants.categoryIconOptions[i],
                      color: selected ? color : Colors.white38,
                      size: 18,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
              child:
                  Text(isEditing ? 'Update Category' : 'Create Category'),
            ),
          ),
        ],
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

// ─── Recurring Toggle ─────────────────────────────────────────────────────────

class _RecurringToggle extends StatelessWidget {
  const _RecurringToggle({
    required this.isRecurring,
    required this.onChanged,
  });

  final bool isRecurring;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tab(false, Icons.looks_one_rounded, 'One-time'),
          _tab(true, Icons.repeat_rounded, 'Recurring'),
        ],
      ),
    );
  }

  Widget _tab(bool value, IconData icon, String label) {
    final isSelected = isRecurring == value;
    const color = AppTheme.primaryColor;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
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
  }
}

// ─── Recurring Config ────────────────────────────────────────────────────────

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
          // ─── Frequency row ─────────────────────────────────────────────
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

          // ─── Day picker ────────────────────────────────────────────────
          if (frequency == RecurringFrequency.weekly) ...[
            const Text('Repeat on',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final weekday = i + 1; // 1=Mon … 7=Sun
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
                          color: isSelected ? Colors.black : Colors.white54,
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
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
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
            // Yearly
            Row(
              children: [
                const Text('Month',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<int>(
                    value: recurMonth,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceColor,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
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
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
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

// ─── Day Dropdown helper ──────────────────────────────────────────────────────

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
