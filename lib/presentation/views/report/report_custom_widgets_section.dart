import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/domain/entities/custom_report_widget_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/views/report/report_create_custom_widget_sheet.dart';
import 'package:money_manager/presentation/views/report/report_custom_spend_card.dart';
import 'package:money_manager/presentation/views/report/report_period_data.dart';

class ReportCustomWidgetsSection extends ConsumerStatefulWidget {
  const ReportCustomWidgetsSection({
    super.key,
    required this.period,
    required this.selectedDate,
    required this.now,
    required this.transactions,
    this.onCustomReportTap,
  });

  final ReportPeriod period;
  final DateTime selectedDate;
  final DateTime now;
  final List<TransactionEntity> transactions;
  final void Function(CustomReportWidgetEntity entity)? onCustomReportTap;

  @override
  ConsumerState<ReportCustomWidgetsSection> createState() =>
      _ReportCustomWidgetsSectionState();
}

class _ReportCustomWidgetsSectionState
    extends ConsumerState<ReportCustomWidgetsSection> {
  /// When true, list is reorderable until user saves or cancels.
  bool _reorderMode = false;

  /// Local order while reordering; null when not editing order.
  List<CustomReportWidgetEntity>? _workingOrder;

  Future<void> _confirmDelete(CustomReportWidgetEntity e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardElevated,
        title: const Text(
          'Remove report?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '"${e.name}" will be removed from Insights.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppTheme.burnColor),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(customReportWidgetRepositoryProvider).delete(e.id);
      if (_workingOrder != null) {
        setState(() {
          _workingOrder!.removeWhere((x) => x.id == e.id);
        });
      }
    }
  }

  void _openSheet({CustomReportWidgetEntity? editing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.12,
        ),
        child: ReportCreateCustomWidgetSheet(
          period: widget.period,
          selectedDate: widget.selectedDate,
          editing: editing,
        ),
      ),
    );
  }

  Future<void> _saveOrder() async {
    final order = _workingOrder;
    if (order == null || order.isEmpty) return;
    await ref.read(customReportWidgetRepositoryProvider).setDisplayOrder(
          order.map((e) => e.id).toList(),
        );
    if (mounted) {
      setState(() {
        _reorderMode = false;
        _workingOrder = null;
      });
    }
  }

  void _cancelReorder() {
    setState(() {
      _reorderMode = false;
      _workingOrder = null;
    });
  }

  void _setReorderMode(bool enabled, List<CustomReportWidgetEntity> fromStream) {
    setState(() {
      _reorderMode = enabled;
      if (enabled) {
        _workingOrder = List.from(fromStream);
      } else {
        _workingOrder = null;
      }
    });
  }

  Widget _buildCard(CustomReportWidgetEntity e, {required bool reordering}) {
    final card = ReportCustomSpendCard(
      entity: e,
      transactions: widget.transactions,
      period: widget.period,
      selectedDate: widget.selectedDate,
      now: widget.now,
      onDelete: () => _confirmDelete(e),
      onEdit: () => _openSheet(editing: e),
      showDragHandle: reordering,
    );
    if (reordering ||
        widget.onCustomReportTap == null) {
      return card;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => widget.onCustomReportTap!(e),
        child: card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customAsync = ref.watch(customReportWidgetListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        customAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (widgets) {
            if (widgets.isEmpty) {
              return Text(
                'YOUR REPORTS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'YOUR REPORTS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _reorderMode,
                        onChanged: (v) {
                          if (v == null) return;
                          _setReorderMode(v, widgets);
                        },
                        activeColor: AppTheme.primaryColor,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _setReorderMode(!_reorderMode, widgets),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Text(
                          'Reorder',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        if (_reorderMode && _workingOrder != null) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Drag cards to set order, then save.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _saveOrder,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Save order',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: _cancelReorder,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        customAsync.when(
          loading: () => const SizedBox(height: 8),
          error: (_, _) => const SizedBox.shrink(),
          data: (widgets) {
            if (widgets.isEmpty) return const SizedBox.shrink();

            if (_reorderMode && _workingOrder != null) {
              final list = _workingOrder!;
              return ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 6 * animation.value,
                    color: Colors.transparent,
                    child: child,
                  );
                },
                itemCount: list.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final moved = list.removeAt(oldIndex);
                    list.insert(newIndex, moved);
                  });
                },
                itemBuilder: (context, i) {
                  final e = list[i];
                  return Padding(
                    key: ValueKey(e.id),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ReorderableDragStartListener(
                      index: i,
                      child: _buildCard(e, reordering: true),
                    ),
                  );
                },
              );
            }

            return Column(
              children: [
                for (final e in widgets) ...[
                  _buildCard(e, reordering: false),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
        OutlinedButton.icon(
          onPressed: () => _openSheet(),
          icon: Icon(
            Icons.add_chart_rounded,
            color: AppTheme.primaryColor.withValues(alpha: 0.95),
            size: 22,
          ),
          label: const Text(
            'Create a report',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'When you are signed in with Google, custom reports are included in your Drive backup (same as transactions).',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.32),
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
