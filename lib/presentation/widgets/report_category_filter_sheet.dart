import 'package:flutter/material.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/domain/entities/category_entity.dart';

/// Multi-select category filter for report flows (amounts per row).
/// [showSubcategories] true: subs grouped under parent, ordered by name.
class ReportCategoryFilterSheet extends StatefulWidget {
  const ReportCategoryFilterSheet({
    super.key,
    required this.categories,
    required this.allCategories,
    required this.showSubcategories,
    required this.initialSelected,
    required this.onApply,
  });

  final Map<CategoryEntity, double> categories;
  final List<CategoryEntity> allCategories;
  final bool showSubcategories;
  final Set<int> initialSelected;
  final ValueChanged<Set<int>> onApply;

  @override
  State<ReportCategoryFilterSheet> createState() =>
      _ReportCategoryFilterSheetState();
}

class _ReportCategoryFilterSheetState extends State<ReportCategoryFilterSheet> {
  late Set<int> _selected;
  final _search = TextEditingController();

  void _onSearchChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  String get _q => _search.text.trim().toLowerCase();

  CategoryEntity? _categoryById(int id) {
    for (final c in widget.allCategories) {
      if (c.id == id) return c;
    }
    return null;
  }

  bool _nameMatches(CategoryEntity c) => _q.isEmpty || c.name.toLowerCase().contains(_q);

  List<Widget> _buildRows() {
    if (!widget.showSubcategories) {
      final entries = widget.categories.entries
          .where((e) => _nameMatches(e.key))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return [
        for (final e in entries) _categoryTile(e.key, e.value),
      ];
    }

    final byParent = <int, List<MapEntry<CategoryEntity, double>>>{};
    for (final e in widget.categories.entries) {
      final pid = e.key.parentId;
      if (pid == null) continue;
      byParent.putIfAbsent(pid, () => []).add(e);
    }
    for (final list in byParent.values) {
      list.sort((a, b) => a.key.name.compareTo(b.key.name));
    }

    final parentIds = byParent.keys.toList()
      ..sort((a, b) {
        final na = _categoryById(a)?.name ?? '';
        final nb = _categoryById(b)?.name ?? '';
        return na.compareTo(nb);
      });

    final rows = <Widget>[];
    for (final pid in parentIds) {
      final parent = _categoryById(pid);
      if (parent == null) continue;

      var subs = byParent[pid]!;
      if (_q.isNotEmpty) {
        final parentMatches = parent.name.toLowerCase().contains(_q);
        subs = subs
            .where(
              (e) =>
                  parentMatches ||
                  e.key.name.toLowerCase().contains(_q),
            )
            .toList();
      }
      if (subs.isEmpty) continue;

      rows.add(_parentHeader(parent));
      for (final e in subs) {
        rows.add(_categoryTile(e.key, e.value, indent: true));
      }
    }
    return rows;
  }

  Widget _parentHeader(CategoryEntity parent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: parent.color.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              parent.name.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.38),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryTile(
    CategoryEntity cat,
    double amount, {
    bool indent = false,
  }) {
    final isSelected = _selected.contains(cat.id);
    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          _selected.remove(cat.id);
        } else {
          _selected.add(cat.id);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(bottom: 8, left: indent ? 12 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              CurrencyFormatter.formatCompact(amount),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? cat.color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? cat.color : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final listHeight = MediaQuery.of(context).size.height * 0.52;
    final rows = _buildRows();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
            child: Row(
              children: [
                const Text(
                  'FILTER BY CATEGORY',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (_selected.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _selected.clear()),
                    child: const Text(
                      'Clear all',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _search,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.showSubcategories
                    ? 'Search categories & subcategories'
                    : 'Search categories',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 22,
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
                    width: 1.1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: listHeight,
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      _q.isEmpty
                          ? 'No categories'
                          : 'No matches for "${_search.text.trim()}"',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    children: rows,
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomPad),
            child: SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  widget.onApply(Set.from(_selected));
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selected.isEmpty
                        ? 'Show All'
                        : 'Apply (${_selected.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
