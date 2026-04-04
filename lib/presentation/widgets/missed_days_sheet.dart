import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/services/preferences_service.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/presentation/views/add_transaction_view.dart';

// ─── Public helper ──────────────────────────────────────────────────────

/// Returns all dates from [installedDate] up to (but not including) today
/// that have no transactions AND have not been dismissed by the user.
/// Results are in newest-first order.
List<DateTime> computeMissedDays(List<TransactionEntity> allTransactions) {
  final prefs = PreferencesService.instance;
  final today = DateUtils.dateOnly(DateTime.now());
  final start = DateUtils.dateOnly(prefs.installedDate);
  final dismissed = prefs.dismissedMissedDays;

  // Set of date-only keys that have at least one transaction
  final datesWithTx = allTransactions
      .map((t) => DateUtils.dateOnly(t.date).toIso8601String().substring(0, 10))
      .toSet();

  final missed = <DateTime>[];
  var cursor = today; // include today
  while (!cursor.isBefore(start)) {
    final key = cursor.toIso8601String().substring(0, 10);
    if (!datesWithTx.contains(key) && !dismissed.contains(key)) {
      missed.add(cursor);
    }
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return missed; // newest-first
}

// ─── Sheet ──────────────────────────────────────────────────────────────

class MissedDaysSheet extends StatefulWidget {
  const MissedDaysSheet({super.key, required this.missedDays});

  final List<DateTime> missedDays;

  @override
  State<MissedDaysSheet> createState() => _MissedDaysSheetState();
}

class _MissedDaysSheetState extends State<MissedDaysSheet> {
  late final List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    _days = List.of(widget.missedDays);
  }

  Future<void> _dismiss(DateTime day) async {
    await PreferencesService.instance.dismissMissedDay(day);
    setState(() => _days.remove(day));
    if (_days.isEmpty && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────────
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.burnColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppTheme.burnColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Missed Days',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_days.length} day${_days.length == 1 ? '' : 's'} with no transactions • swipe to ignore',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Divider ──────────────────────────────────────────────
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),

          // ── List ─────────────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _days.length,
              separatorBuilder: (_, __) => Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.white.withValues(alpha: 0.05),
              ),
              itemBuilder: (context, i) {
                final day = _days[i];
                final yesterday = DateUtils.dateOnly(
                    DateTime.now().subtract(const Duration(days: 1)));
                final isYesterday = day == yesterday;
                final label =
                    isYesterday ? 'Yesterday' : DateFormat('EEEE').format(day);
                final sub = DateFormat('d MMMM yyyy').format(day);

                return Dismissible(
                  key: ValueKey(day),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _dismiss(day),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: Colors.white.withValues(alpha: 0.06),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.not_interested_rounded,
                            color: Colors.white38, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Ignore',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      sub,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              AddTransactionView(initialDate: day),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded,
                                color: AppTheme.primaryColor, size: 14),
                            SizedBox(width: 3),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Dismiss button ──────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
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

