import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/report_filter_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/views/report/report_dialogs.dart';
import 'package:money_manager/presentation/views/report/report_period_data.dart';
import 'package:money_manager/presentation/views/report/report_widgets.dart';
import 'package:money_manager/presentation/widgets/bento_card.dart';
import 'package:money_manager/presentation/widgets/spending_pie_chart.dart';
import 'package:money_manager/presentation/widgets/transaction_list_tile.dart';

class ReportDetailView extends ConsumerStatefulWidget {
  const ReportDetailView({super.key, required this.entity});

  final ReportFilterEntity entity;

  @override
  ConsumerState<ReportDetailView> createState() => _ReportDetailViewState();
}

class _ReportDetailViewState extends ConsumerState<ReportDetailView> {
  ReportPeriod _period = ReportPeriod.month;
  ReportTypeTab _selectedTab = ReportTypeTab.burn;
  DateTime _selectedDate = DateTime.now();
  DateTime _compareDate =
      DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
  bool _showSubcategories = false;
  Set<int> _categoryFilterIds = {};
  int? _activePresetId;
  String _activePresetName = '';

  @override
  void initState() {
    super.initState();
    final e = widget.entity;
    _period = periodFromStr(e.period);
    _selectedTab = typeTabFromStr(e.typeTab);
    _categoryFilterIds = Set.from(e.categoryFilterIds);
    _showSubcategories = e.showSubcategories;
    _activePresetId = e.id;
    _activePresetName = e.name;
  }

  TransactionType get _selectedType => switch (_selectedTab) {
        ReportTypeTab.burn => TransactionType.burn,
        ReportTypeTab.store => TransactionType.store,
        ReportTypeTab.income => TransactionType.income,
      };

  void _goBack() {
    setState(() {
      switch (_period) {
        case ReportPeriod.month:
          final prevSel =
              DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
          _selectedDate = prevSel;
          _compareDate = DateTime(prevSel.year, prevSel.month - 1, 1);
          break;
        case ReportPeriod.year:
          _selectedDate = DateTime(_selectedDate.year - 1);
          _compareDate = DateTime(_selectedDate.year - 1);
          break;
        case ReportPeriod.overall:
          break;
      }
      _categoryFilterIds = {};
    });
  }

  void _goForward() {
    setState(() {
      switch (_period) {
        case ReportPeriod.month:
          final nextSel =
              DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          _selectedDate = nextSel;
          _compareDate = DateTime(nextSel.year, nextSel.month - 1, 1);
          break;
        case ReportPeriod.year:
          _selectedDate = DateTime(_selectedDate.year + 1);
          _compareDate = DateTime(_selectedDate.year - 1);
          break;
        case ReportPeriod.overall:
          break;
      }
      _categoryFilterIds = {};
    });
  }

  Future<void> _savePreset(BuildContext context) async {
    int id = 0;
    String? name;

    if (_activePresetId != null) {
      final update = await showDialog<bool>(
        context: context,
        builder: (_) =>
            ReportPresetUpdateDialog(presetName: _activePresetName),
      );
      if (update == null) return;
      if (update) {
        id = _activePresetId!;
        name = _activePresetName;
      }
    }

    if (id == 0) {
      name = await showDialog<String>(
        context: context,
        builder: (_) => const ReportSavePresetDialog(),
      );
      if (name == null || name.trim().isEmpty) return;
      name = name.trim();
    }

    final entity = ReportFilterEntity(
      id: id,
      name: name!,
      period: periodToStr(_period),
      typeTab: typeTabToStr(_selectedTab),
      categoryFilterIds: _categoryFilterIds.toList(),
      showSubcategories: _showSubcategories,
      createdAt: DateTime.now(),
    );
    await ref.read(reportFilterRepositoryProvider).save(entity);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(id != 0
              ? '"$name" updated'
              : 'Filter "$name" saved'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openCategoryFilterSheet(
      BuildContext context, Map<CategoryEntity, double> categories) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportCategoryFilterSheet(
        categories: categories,
        initialSelected: Set.from(_categoryFilterIds),
        onApply: (ids) => setState(() => _categoryFilterIds = ids),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionListProvider);
    final catAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: txAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
          error: (e, _) => Center(
            child: Text(e.toString(),
                style: const TextStyle(color: AppTheme.burnColor)),
          ),
          data: (allTx) {
            final allCategories = catAsync.valueOrNull ?? [];
            final now = DateTime.now();
            final bool canGoNext = switch (_period) {
              ReportPeriod.month => _selectedDate.year < now.year ||
                  (_selectedDate.year == now.year &&
                      _selectedDate.month < now.month),
              ReportPeriod.year => _selectedDate.year < now.year,
              ReportPeriod.overall => false,
            };

            final rawData = PeriodData.compute(
              allTx,
              allCategories,
              _period,
              _selectedDate,
              typeFilter: _selectedType,
            );
            final rawBreakdown = _showSubcategories
                ? rawData.breakdownFor(_selectedType)
                : rawData.parentBreakdownFor(_selectedType);

            final sheetCats = _showSubcategories
                ? allCategories.where((c) => c.parentId != null && c.type == _selectedType).toList()
                : allCategories.where((c) => c.parentId == null && c.type == _selectedType).toList();
            final filterSheetCategories = Map.fromEntries(
              (sheetCats.map((cat) {
                final amount = rawBreakdown.entries
                    .where((e) => e.key.id == cat.id)
                    .fold(0.0, (s, e) => s + e.value);
                return MapEntry(cat, amount);
              }).toList()
                ..sort((a, b) => b.value.compareTo(a.value))),
            );

            final data = _categoryFilterIds.isEmpty
                ? rawData
                : PeriodData.compute(
                    allTx,
                    allCategories,
                    _period,
                    _selectedDate,
                    typeFilter: _selectedType,
                    categoryIdFilter: _categoryFilterIds,
                    showSubcategories: _showSubcategories,
                  );
            final selectedBreakdown = _showSubcategories
                ? data.breakdownFor(_selectedType)
                : data.parentBreakdownFor(_selectedType);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: 0.08)),
                            ),
                            child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70,
                                size: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.entity.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        TypeBadge(type: _selectedType),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: PeriodSelector(
                      selected: _period,
                      onChanged: (p) => setState(() {
                        final now = DateTime.now();
                        _period = p;
                        _selectedDate = now;
                        _categoryFilterIds = {};
                        switch (p) {
                          case ReportPeriod.month:
                            _compareDate =
                                DateTime(now.year, now.month - 1, 1);
                            break;
                          case ReportPeriod.year:
                            _compareDate = DateTime(now.year - 1);
                            break;
                          case ReportPeriod.overall:
                            _compareDate = DateTime(2000);
                            break;
                        }
                      }),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_period != ReportPeriod.overall) ...[
                        DateNavigator(
                          label: data.periodLabel,
                          onPrev: _goBack,
                          onNext: canGoNext ? _goForward : null,
                        ),
                        const SizedBox(height: 12),
                      ],

                      SummaryCard(
                        data: data,
                        type: _selectedType,
                        deltaAmount: _computeDelta(allTx),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DrillToggle(
                              showSubcategories: _showSubcategories,
                              onChanged: (v) => setState(
                                  () => _toggleDrill(v, allCategories)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterIconButton(
                            activeCount: _categoryFilterIds.length,
                            onTap: () => _openCategoryFilterSheet(
                                context, filterSheetCategories),
                          ),
                          const SizedBox(width: 8),
                          SavePresetButton(
                            isActive: _activePresetId != null,
                            onTap: () => _savePreset(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (data.barValues.any((v) => v > 0)) ...[
                        BentoCard(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              cardLabel('SPENDING TREND'),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 170,
                                child: ReportBarChart(
                                  labels: data.barLabels,
                                  values: data.barValues,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (selectedBreakdown.isNotEmpty) ...[
                        BentoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              cardLabel(
                                  _selectedType == TransactionType.burn
                                      ? 'WHERE MONEY WENT'
                                      : _selectedType == TransactionType.store
                                          ? 'WHERE MONEY STORED'
                                          : 'WHERE MONEY CAME FROM'),
                              const SizedBox(height: 20),
                              SpendingPieChart(data: selectedBreakdown),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        BentoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              cardLabel('CATEGORY BREAKDOWN'),
                              const SizedBox(height: 16),
                              ...selectedBreakdown.entries.map(
                                (e) => CategoryBar(
                                  category: e.key,
                                  amount: e.value,
                                  total: data.totalFor(_selectedType),
                                  color: _selectedType == TransactionType.burn
                                      ? AppTheme.burnColor
                                      : _selectedType == TransactionType.store
                                          ? AppTheme.storeColor
                                          : AppTheme.incomeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_period != ReportPeriod.overall) ...[
                        SpendingComparisonCard(
                          current: data,
                          currentDate: _selectedDate,
                          period: _period,
                          selectedType: _selectedType,
                          compare: PeriodData.compute(
                            allTx,
                            allCategories,
                            _period,
                            _compareDate,
                            typeFilter: _selectedType,
                            categoryIdFilter: _categoryFilterIds,
                            showSubcategories: _showSubcategories,
                          ),
                          compareDate: _compareDate,
                          onCompareDateChanged: (d) =>
                              setState(() => _compareDate = d),
                        ),
                        const SizedBox(height: 12),
                      ],

                      BentoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                cardLabel('TRANSACTIONS'),
                                const Spacer(),
                                CountBadge(
                                    count: data.transactions.length),
                              ],
                            ),
                            Builder(builder: (_) {
                              final filtered = data.transactions;
                              if (filtered.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 32),
                                  child: Center(
                                    child: Text(
                                      'No transactions for this period',
                                      style: TextStyle(
                                          color: Colors.white38),
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: [
                                  const SizedBox(height: 8),
                                  ...filtered.map(
                                    (tx) => TransactionListTile(
                                      transaction: tx,
                                      onDelete: () => ref
                                          .read(
                                              transactionRepositoryProvider)
                                          .delete(tx.id),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  double? _computeDelta(List<TransactionEntity> allTx) {
    bool catMatch(TransactionEntity t) {
      if (_categoryFilterIds.isEmpty) return true;
      if (t.category == null) return false;
      final cat = t.category!;
      return _showSubcategories
          ? _categoryFilterIds.contains(cat.id)
          : _categoryFilterIds.contains(cat.parentId ?? cat.id);
    }

    if (_period == ReportPeriod.month) {
      final sel = _selectedDate;
      final day = sel.day;
      final curStart = DateTime(sel.year, sel.month, 1);
      final curEnd =
          DateTime(sel.year, sel.month, day, 23, 59, 59, 999);
      final prevStart = DateTime(sel.year, sel.month - 1, 1);
      final prevDays =
          DateTime(prevStart.year, prevStart.month + 1, 0).day;
      final prevDay = day <= prevDays ? day : prevDays;
      final prevEnd = DateTime(
          prevStart.year, prevStart.month, prevDay, 23, 59, 59, 999);
      double sum(DateTime s, DateTime e) => allTx
          .where((t) =>
              t.type == _selectedType &&
              !t.date.isBefore(s) &&
              !t.date.isAfter(e) &&
              catMatch(t))
          .fold(0.0, (a, t) => a + t.amount);
      return sum(curStart, curEnd) - sum(prevStart, prevEnd);
    } else if (_period == ReportPeriod.year) {
      final sel = _selectedDate;
      final curStart = DateTime(sel.year, 1, 1);
      final curEnd =
          DateTime(sel.year, sel.month + 1, 0, 23, 59, 59, 999);
      final prevStart = DateTime(sel.year - 1, 1, 1);
      final prevEnd =
          DateTime(sel.year - 1, sel.month + 1, 0, 23, 59, 59, 999);
      double sum(DateTime s, DateTime e) => allTx
          .where((t) =>
              t.type == _selectedType &&
              !t.date.isBefore(s) &&
              !t.date.isAfter(e) &&
              catMatch(t))
          .fold(0.0, (a, t) => a + t.amount);
      return sum(curStart, curEnd) - sum(prevStart, prevEnd);
    }
    return null;
  }

  void _toggleDrill(bool v, List<CategoryEntity> allCategories) {
    if (_categoryFilterIds.isEmpty) {
      _showSubcategories = v;
      return;
    }
    if (v) {
      _categoryFilterIds = allCategories
          .where((c) =>
              c.parentId != null &&
              _categoryFilterIds.contains(c.parentId))
          .map((c) => c.id)
          .toSet();
    } else {
      _categoryFilterIds = allCategories
          .where((c) =>
              c.parentId != null && _categoryFilterIds.contains(c.id))
          .map((c) => c.parentId!)
          .toSet();
    }
    _showSubcategories = v;
  }
}
