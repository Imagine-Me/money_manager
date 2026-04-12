import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/domain/entities/category_entity.dart';


// ─── Year picker dialog ───────────────────────────────────────────────────────

class ReportYearPickerDialog extends StatelessWidget {
  const ReportYearPickerDialog({
    super.key,
    required this.initial,
    required this.currentYear,
  });

  final int initial;
  final int currentYear;

  @override
  Widget build(BuildContext context) {
    final years = List.generate(12, (i) => currentYear - 1 - i);
    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SELECT YEAR',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.6,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: years.length,
              itemBuilder: (_, i) {
                final year = years[i];
                final isSelected = year == initial;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, year),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppTheme.primaryColor : AppTheme.bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$year',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Month picker dialog ──────────────────────────────────────────────────────

class ReportMonthPickerDialog extends StatefulWidget {
  const ReportMonthPickerDialog({
    super.key,
    required this.initial,
    required this.currentDate,
  });

  final DateTime initial;
  final DateTime currentDate;

  @override
  State<ReportMonthPickerDialog> createState() =>
      _ReportMonthPickerDialogState();
}

class _ReportMonthPickerDialogState extends State<ReportMonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.white70, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  '$_year',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed:
                      _year >= now.year ? null : () => setState(() => _year++),
                  icon: Icon(
                    Icons.chevron_right,
                    color: _year >= now.year ? Colors.white24 : Colors.white70,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: 12,
              itemBuilder: (_, i) {
                final month = i + 1;
                final dt = DateTime(_year, month, 1);
                final isFuture =
                    dt.isAfter(DateTime(now.year, now.month, 1));
                final isSameAsCurrent =
                    dt.year == widget.currentDate.year &&
                        dt.month == widget.currentDate.month;
                final isSelected = dt.year == widget.initial.year &&
                    dt.month == widget.initial.month;
                final disabled = isFuture || isSameAsCurrent;

                return GestureDetector(
                  onTap: disabled ? null : () => Navigator.pop(context, dt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : disabled
                              ? Colors.transparent
                              : AppTheme.bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white
                                .withValues(alpha: disabled ? 0.04 : 0.08),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat('MMM').format(dt),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : disabled
                                ? Colors.white24
                                : Colors.white70,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Preset update dialog ─────────────────────────────────────────────────────

class ReportPresetUpdateDialog extends StatelessWidget {
  const ReportPresetUpdateDialog({super.key, required this.presetName});

  final String presetName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SAVE FILTER',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _btn(
              context,
              label: 'Update "$presetName"',
              primary: true,
              result: true,
            ),
            const SizedBox(height: 10),
            _btn(
              context,
              label: 'Save as new',
              primary: false,
              result: false,
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context,
      {required String label,
      required bool primary,
      required bool result}) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, result),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: primary
              ? AppTheme.primaryColor.withValues(alpha: 0.12)
              : AppTheme.bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primary
                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: primary ? AppTheme.primaryColor : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Save preset dialog ───────────────────────────────────────────────────────

class ReportSavePresetDialog extends StatefulWidget {
  const ReportSavePresetDialog({super.key});

  @override
  State<ReportSavePresetDialog> createState() => _ReportSavePresetDialogState();
}

class _ReportSavePresetDialogState extends State<ReportSavePresetDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SAVE FILTER PRESET',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Monthly Food',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 14),
                filled: true,
                fillColor: AppTheme.bgColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) Navigator.pop(context, v.trim());
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    final v = _controller.text.trim();
                    if (v.isNotEmpty) Navigator.pop(context, v);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

// ─── Category filter sheet ────────────────────────────────────────────────────

class ReportCategoryFilterSheet extends StatefulWidget {
  const ReportCategoryFilterSheet({
    super.key,
    required this.categories,
    required this.initialSelected,
    required this.onApply,
  });

  final Map<CategoryEntity, double> categories;
  final Set<int> initialSelected;
  final ValueChanged<Set<int>> onApply;

  @override
  State<ReportCategoryFilterSheet> createState() =>
      _ReportCategoryFilterSheetState();
}

class _ReportCategoryFilterSheetState
    extends State<ReportCategoryFilterSheet> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
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
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: widget.categories.length,
              itemBuilder: (_, i) {
                final entry = widget.categories.entries.elementAt(i);
                final cat = entry.key;
                final amount = entry.value;
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
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          _compact(amount),
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
                            color:
                                isSelected ? cat.color : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? cat.color : Colors.white24,
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
              },
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

  String _compact(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }
}

/// Minimal data contract so dialogs don't depend on CategoryEntity.
abstract class CategoryData {
  int get id;
  String get name;
  Color get color;
}