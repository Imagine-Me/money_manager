import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/report_filter_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/views/report_detail_view.dart';

// ─── Report List View ─────────────────────────────────────────────────────────

class ReportListView extends ConsumerWidget {
  const ReportListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersAsync = ref.watch(reportFilterListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      floatingActionButton: FloatingActionButton(
        heroTag: 'report_fab',
        onPressed: () => _openFormSheet(context, null),
        backgroundColor: AppTheme.primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title bar ──────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Reports',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // ── Body ──────────────────────────────────────────────────
            Expanded(
              child: filtersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryColor),
                ),
                error: (e, _) => Center(
                  child: Text(e.toString(),
                      style: const TextStyle(color: AppTheme.burnColor)),
                ),
                data: (filters) {
                  if (filters.isEmpty) {
                    return const _EmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: filters.length,
                    itemBuilder: (_, i) => _ReportCard(entity: filters[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _openFormSheet(BuildContext context, ReportFilterEntity? initial) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportFormSheet(initial: initial),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.white24,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No saved reports yet',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to create your first report',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Report card ──────────────────────────────────────────────────────────────

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.entity});

  final ReportFilterEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = entity.typeTab == 'income';
    final isBurn = entity.typeTab == 'burn';
    final accent = isBurn
        ? AppTheme.burnColor
        : isIncome
            ? AppTheme.incomeColor
            : AppTheme.storeColor;
    final typeLabel = isBurn ? 'BURN' : isIncome ? 'INCOME' : 'STORE';
    final typeIcon = isBurn
        ? Icons.local_fire_department_rounded
        : isIncome
            ? Icons.account_balance_wallet_rounded
            : Icons.savings_rounded;

    // ── Compute this-month total and prev-month delta ──────────────────────
    final txType = isBurn
        ? TransactionType.burn
        : isIncome
            ? TransactionType.income
            : TransactionType.store;
    final now = DateTime.now();
    final prevMonthDate = DateTime(now.year, now.month - 1);
    final txs = ref.watch(transactionListProvider).value ?? [];
    double thisTotal = 0;
    double prevTotal = 0;
    for (final tx in txs) {
      if (tx.type != txType) continue;
      if (entity.categoryFilterIds.isNotEmpty) {
        final cat = tx.category;
        if (cat == null) continue;
        // Match by direct ID (subcategory filter) or by parentId (parent filter)
        final matched = entity.categoryFilterIds.contains(cat.id) ||
            (cat.parentId != null &&
                entity.categoryFilterIds.contains(cat.parentId));
        if (!matched) continue;
      }
      final d = tx.date;
      if (d.year == now.year && d.month == now.month) {
        thisTotal += tx.amount;
      } else if (d.year == prevMonthDate.year &&
          d.month == prevMonthDate.month) {
        prevTotal += tx.amount;
      }
    }
    final deltaPct =
        prevTotal > 0 ? (thisTotal - prevTotal) / prevTotal * 100 : null;
    final hasPrev = deltaPct != null;
    final isUp = deltaPct != null && deltaPct > 0;
    // For burn: going up is bad (red). For store/income: going up is good.
    final deltaIsGood = isBurn ? !isUp : isUp;
    final deltaColor = deltaPct != null && deltaPct.abs() < 0.1
        ? Colors.white38
        : deltaIsGood
            ? AppTheme.storeColor
            : AppTheme.burnColor;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReportDetailView(entity: entity),
        ),
      ),
      onLongPress: () => _showActionSheet(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            // ── Type icon pill ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: accent, size: 20),
            ),
            const SizedBox(width: 14),

            // ── Name + meta ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entity.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: accent.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Category count (if any filter)
                      if (entity.categoryFilterIds.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${entity.categoryFilterIds.length} cats',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],


                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  thisTotal > 0 ? _fmtAmt(thisTotal) : '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (hasPrev) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                      deltaPct.abs() < 0.1
                            ? Icons.remove_rounded
                            : isUp
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                        color: deltaColor,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${deltaPct.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: deltaColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtAmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }

  void _showActionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportActionSheet(
        entity: entity,
        // Pass the outer context (has Riverpod scope + Navigator) for
        // opening the form sheet and showing the undo snackbar.
        outerContext: context,
        ref: ref,
      ),
    );
  }
}

// ─── Action sheet (long-press) ────────────────────────────────────────────────

class _ReportActionSheet extends StatelessWidget {
  const _ReportActionSheet({
    required this.entity,
    required this.outerContext,
    required this.ref,
  });

  final ReportFilterEntity entity;
  final BuildContext outerContext;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Report name header
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              entity.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── Edit ──────────────────────────────────────────────────
          _ActionRow(
            icon: Icons.edit_outlined,
            label: 'Edit Report',
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.pop(context);
              ReportListView._openFormSheet(outerContext, entity);
            },
          ),
          const SizedBox(height: 8),

          // ── Delete ────────────────────────────────────────────────
          _ActionRow(
            icon: Icons.delete_outline_rounded,
            label: 'Delete Report',
            color: AppTheme.burnColor,
            onTap: () async {
              Navigator.pop(context);
              await ref
                  .read(reportFilterRepositoryProvider)
                  .delete(entity.id);
              if (outerContext.mounted) {
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  SnackBar(
                    content: Text('"${entity.name}" deleted'),
                    backgroundColor: AppTheme.cardElevated,
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: AppTheme.primaryColor,
                      onPressed: () async {
                        await ref
                            .read(reportFilterRepositoryProvider)
                            .save(entity);
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Report form sheet (create + edit) ───────────────────────────────────────

class _ReportFormSheet extends ConsumerStatefulWidget {
  const _ReportFormSheet({this.initial});

  final ReportFilterEntity? initial;

  @override
  ConsumerState<_ReportFormSheet> createState() => _ReportFormSheetState();
}

class _ReportFormSheetState extends ConsumerState<_ReportFormSheet> {
  // null = not yet selected
  String? _typeTab;
  bool _showSubcategories = false;
  final Set<int> _selectedCategoryIds = {};
  final _nameController = TextEditingController();

  bool get _isEdit => widget.initial != null;
  bool get _canSave =>
      _typeTab != null && _nameController.text.trim().isNotEmpty;

  TransactionType? get _txType => switch (_typeTab) {
        'burn' => TransactionType.burn,
        'store' => TransactionType.store,
        'income' => TransactionType.income,
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final e = widget.initial!;
      _typeTab = e.typeTab;
      _showSubcategories = e.showSubcategories;
      _selectedCategoryIds.addAll(e.categoryFilterIds);
      _nameController.text = e.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _setType(String type) {
    if (_typeTab != type) {
      setState(() {
        _typeTab = type;
        _selectedCategoryIds.clear();
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _typeTab == null) return;

    final entity = ReportFilterEntity(
      id: widget.initial?.id ?? 0,
      name: name,
      period: widget.initial?.period ?? 'month',
      typeTab: _typeTab!,
      categoryFilterIds: _selectedCategoryIds.toList(),
      showSubcategories: _showSubcategories,
      createdAt: widget.initial?.createdAt ?? DateTime.now(),
    );
    await ref.read(reportFilterRepositoryProvider).save(entity);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final catAsync = ref.watch(categoryListProvider);
    final allCategories = catAsync.valueOrNull ?? [];

    final List<CategoryEntity> visibleCats = _txType == null
        ? []
        : _showSubcategories
            ? allCategories
                .where((c) => c.type == _txType && c.parentId != null)
                .toList()
            : allCategories
                .where((c) => c.type == _txType && c.parentId == null)
                .toList();

    final bottomPad = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                child: Row(
                  children: [
                    Text(
                      _isEdit ? 'EDIT REPORT' : 'NEW REPORT',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white54, size: 20),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(
                      16, 20, 16, 24 + bottomPad),
                  children: [
                    // ── Section: Report type ─────────────────────────
                    _FormSectionLabel('REPORT TYPE'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeToggleButton(
                            label: 'Burn',
                            icon: Icons.local_fire_department_rounded,
                            color: AppTheme.burnColor,
                            selected: _typeTab == 'burn',
                            onTap: () => _setType('burn'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeToggleButton(
                            label: 'Store',
                            icon: Icons.savings_rounded,
                            color: AppTheme.storeColor,
                            selected: _typeTab == 'store',
                            onTap: () => _setType('store'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeToggleButton(
                            label: 'Income',
                            icon: Icons.account_balance_wallet_rounded,
                            color: AppTheme.incomeColor,
                            selected: _typeTab == 'income',
                            onTap: () => _setType('income'),
                          ),
                        ),
                      ],
                    ),

                    // ── Section: View by + categories (when type selected) ──
                    if (_typeTab != null) ...[
                      const SizedBox(height: 24),
                      _FormSectionLabel('VIEW BY'),
                      const SizedBox(height: 10),
                      _ViewByToggle(
                        showSubcategories: _showSubcategories,
                        onChanged: (v) => setState(() {
                          _showSubcategories = v;
                          _selectedCategoryIds.clear();
                        }),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _FormSectionLabel('FILTER CATEGORIES'),
                          const Spacer(),
                          if (_selectedCategoryIds.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(
                                  () => _selectedCategoryIds.clear()),
                              child: const Text(
                                'Clear all',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Leave empty to include all categories',
                        style: TextStyle(
                            color: Colors.white24, fontSize: 11),
                      ),
                      const SizedBox(height: 10),
                      if (visibleCats.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No categories found for this type',
                            style: TextStyle(
                                color: Colors.white24, fontSize: 13),
                          ),
                        )
                      else
                        ...visibleCats.map((cat) {
                          final isSelected =
                              _selectedCategoryIds.contains(cat.id);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (isSelected) {
                                _selectedCategoryIds.remove(cat.id);
                              } else {
                                _selectedCategoryIds.add(cat.id);
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cat.color.withValues(alpha: 0.12)
                                    : AppTheme.bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? cat.color.withValues(alpha: 0.6)
                                      : Colors.white.withValues(alpha: 0.07),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: cat.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      cat.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? cat.color
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? cat.color
                                            : Colors.white24,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded,
                                            color: Colors.white, size: 12)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],

                    // ── Section: Name ────────────────────────────────
                    const SizedBox(height: 24),
                    _FormSectionLabel('REPORT NAME'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. Monthly Food Burn',
                        hintStyle: const TextStyle(
                            color: Colors.white24, fontSize: 14),
                        filled: true,
                        fillColor: AppTheme.bgColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Save button ──────────────────────────────────
                    GestureDetector(
                      onTap: _canSave ? _save : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: _canSave
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _canSave
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _isEdit ? 'Update Report' : 'Save Report',
                          style: TextStyle(
                            color: _canSave ? Colors.white : Colors.white38,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Form section label ───────────────────────────────────────────────────────

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Type toggle button ───────────────────────────────────────────────────────

class _TypeToggleButton extends StatelessWidget {
  const _TypeToggleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AppTheme.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.07),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : Colors.white38, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.white38,
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── View-by toggle ───────────────────────────────────────────────────────────

class _ViewByToggle extends StatelessWidget {
  const _ViewByToggle({
    required this.showSubcategories,
    required this.onChanged,
  });

  final bool showSubcategories;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          _chip('Category', !showSubcategories, () => onChanged(false)),
          _chip('Subcategory', showSubcategories, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white38,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
