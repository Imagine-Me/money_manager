import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/views/add_transaction_view.dart';
import 'package:money_manager/presentation/widgets/transaction_list_tile.dart';

class TransactionsView extends ConsumerWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final filteredAsync = ref.watch(filteredTransactionProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddTransactionView()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Filter Tabs ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: FilterType.values.map((f) {
                final isSelected = filter == f;
                late Color color;
                late String label;
                late IconData icon;
                switch (f) {
                  case FilterType.all:
                    color = AppTheme.primaryColor;
                    label = 'All';
                    icon = Icons.all_inclusive_rounded;
                  case FilterType.burn:
                    color = AppTheme.burnColor;
                    label = 'Burn';
                    icon = Icons.local_fire_department_rounded;
                  case FilterType.store:
                    color = AppTheme.storeColor;
                    label = 'Store';
                    icon = Icons.savings_rounded;
                }
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(filterProvider.notifier).state = f,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.2)
                              : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? color.withValues(alpha: 0.5)
                                : Colors.white10,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon,
                                size: 15,
                                color: isSelected ? color : Colors.white38),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? color : Colors.white38,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ─── Transactions List ───────────────────────────────────────────────
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
              error: (e, _) => Center(
                child: Text(
                  e.toString(),
                  style: const TextStyle(color: AppTheme.burnColor),
                ),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            color: Colors.white24, size: 56),
                        const SizedBox(height: 16),
                        const Text(
                          'No transactions',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 18,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add one using the button below',
                          style: TextStyle(color: Colors.white24, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: transactions.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: TransactionListTile(
                      transaction: transactions[i],
                      onDelete: () => ref
                          .read(transactionRepositoryProvider)
                          .delete(transactions[i].id),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddTransactionView(
                              existing: transactions[i]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'tx_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddTransactionView()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
