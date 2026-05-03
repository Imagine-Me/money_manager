import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/custom_report_widget_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/views/report/report_category_spend_helpers.dart';
import 'package:money_manager/presentation/views/report/report_period_data.dart';
import 'package:money_manager/presentation/widgets/report_category_filter_sheet.dart';

class ReportCreateCustomWidgetSheet extends ConsumerStatefulWidget {
  const ReportCreateCustomWidgetSheet({
    super.key,
    required this.period,
    required this.selectedDate,
    this.editing,
  });

  final ReportPeriod period;
  final DateTime selectedDate;

  /// When set, sheet updates this row instead of creating a new one.
  final CustomReportWidgetEntity? editing;

  @override
  ConsumerState<ReportCreateCustomWidgetSheet> createState() =>
      _ReportCreateCustomWidgetSheetState();
}

class _ReportCreateCustomWidgetSheetState
    extends ConsumerState<ReportCreateCustomWidgetSheet> {
  final _nameController = TextEditingController();
  bool _showSubcategories = false;
  Set<int> _selectedIds = {};
  TransactionType _typeFilter = TransactionType.burn;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _nameController.text = e.name;
      _showSubcategories = e.showSubcategories;
      _selectedIds = Set.from(e.categoryFilterIds);
      _typeFilter = e.typeFilter;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _setType(TransactionType t) {
    if (t == _typeFilter) return;
    setState(() {
      _typeFilter = t;
      _selectedIds.clear();
    });
  }

  void _openCategoryPicker(
    BuildContext context,
    List<CategoryEntity> allCategories,
    List<TransactionEntity> transactions,
  ) {
    final map = categoryAmountsForFilterSheet(
      allTransactions: transactions,
      allCategories: allCategories,
      period: widget.period,
      selectedDate: widget.selectedDate,
      showSubcategories: _showSubcategories,
      type: _typeFilter,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportCategoryFilterSheet(
        categories: map,
        allCategories: allCategories,
        showSubcategories: _showSubcategories,
        initialSelected: Set.from(_selectedIds),
        onApply: (ids) => setState(() => _selectedIds = ids),
      ),
    );
  }

  void _onDrillChanged(bool toSubs, List<CategoryEntity> allCategories) {
    setState(() {
      if (_selectedIds.isEmpty) {
        _showSubcategories = toSubs;
        return;
      }
      if (toSubs) {
        _selectedIds = {
          for (final c in allCategories)
            if (c.parentId != null && _selectedIds.contains(c.parentId)) c.id,
        };
      } else {
        _selectedIds = {
          for (final c in allCategories)
            if (c.parentId != null && _selectedIds.contains(c.id)) c.parentId!,
        };
      }
      _showSubcategories = toSubs;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a name for this report'),
          backgroundColor: AppTheme.burnColor,
        ),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one category'),
          backgroundColor: AppTheme.burnColor,
        ),
      );
      return;
    }

    final existing = widget.editing;
    final entity = CustomReportWidgetEntity(
      id: existing?.id ?? 0,
      name: name,
      categoryFilterIds: _selectedIds.toList(),
      showSubcategories: _showSubcategories,
      createdAt: existing?.createdAt ?? DateTime.now(),
      typeFilter: _typeFilter,
      sortOrder: existing?.sortOrder ?? 0,
    );

    await ref.read(customReportWidgetRepositoryProvider).save(entity);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Added "$name"' : 'Updated "$name"'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionListProvider);
    final catAsync = ref.watch(categoryListProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.editing != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: keyboard + bottomInset),
      child: txAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('$e', style: const TextStyle(color: AppTheme.burnColor)),
        ),
        data: (transactions) {
          return catAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child:
                    CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('$e',
                  style: const TextStyle(color: AppTheme.burnColor)),
            ),
            data: (allCategories) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          isEdit ? 'EDIT REPORT' : 'CREATE A REPORT',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track burn, store, or income for chosen categories. Amounts in the picker match your period header.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeChip(
                            label: 'Burn',
                            selected: _typeFilter == TransactionType.burn,
                            color: AppTheme.burnColor,
                            onTap: () => _setType(TransactionType.burn),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TypeChip(
                            label: 'Store',
                            selected: _typeFilter == TransactionType.store,
                            color: AppTheme.storeColor,
                            onTap: () => _setType(TransactionType.store),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TypeChip(
                            label: 'Income',
                            selected: _typeFilter == TransactionType.income,
                            color: AppTheme.incomeColor,
                            onTap: () => _setType(TransactionType.income),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Report name',
                        labelStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: AppTheme.bgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ChipChoice(
                            label: 'Categories',
                            selected: !_showSubcategories,
                            onTap: () {
                              if (!_showSubcategories) return;
                              _onDrillChanged(false, allCategories);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ChipChoice(
                            label: 'Subcategories',
                            selected: _showSubcategories,
                            onTap: () {
                              if (_showSubcategories) return;
                              _onDrillChanged(true, allCategories);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _openCategoryPicker(context, allCategories, transactions),
                      icon: Icon(
                        Icons.filter_list_rounded,
                        color: _chartColorForType(_typeFilter),
                        size: 20,
                      ),
                      label: Text(
                        _selectedIds.isEmpty
                            ? 'Select categories'
                            : '${_selectedIds.length} selected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEdit ? 'Save changes' : 'Save report',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Color _chartColorForType(TransactionType t) => switch (t) {
      TransactionType.store => AppTheme.storeColor,
      TransactionType.income => AppTheme.incomeColor,
      _ => AppTheme.primaryColor,
    };

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.22) : AppTheme.bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipChoice extends StatelessWidget {
  const _ChipChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                : AppTheme.bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor.withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
