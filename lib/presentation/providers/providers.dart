import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/data/datasources/local/isar_service.dart';
import 'package:money_manager/data/repositories/category_repository_impl.dart';
import 'package:money_manager/data/repositories/transaction_repository_impl.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/domain/repositories/category_repository.dart';
import 'package:money_manager/domain/repositories/transaction_repository.dart';
import 'package:money_manager/domain/usecases/analytics_engine.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService.instance;
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(isarServiceProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.watch(isarServiceProvider));
});

final analyticsEngineProvider = Provider<AnalyticsEngine>((ref) {
  return const AnalyticsEngine();
});

// ─── Streams / Watches ────────────────────────────────────────────────────────

final categoryListProvider = StreamProvider<List<CategoryEntity>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

final transactionListProvider = StreamProvider<List<TransactionEntity>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

// ─── Analytics ────────────────────────────────────────────────────────────────

final analyticsProvider = Provider<AsyncValue<_Analytics>>((ref) {
  final txAsync = ref.watch(transactionListProvider);
  final engine = ref.watch(analyticsEngineProvider);

  return txAsync.whenData((transactions) {
    final monthly = engine.getMonthlyTransactions(transactions);
    return _Analytics(
      totalBurn: engine.getTotalBurn(transactions),
      totalStore: engine.getTotalStore(transactions),
      delta: engine.calculateDelta(transactions),
      weeklySpend: engine.getWeeklySpend(transactions),
      burnCategoryBreakdown: engine.getCategoryBreakdown(
        transactions,
        type: TransactionType.burn,
      ),
      storeCategoryBreakdown: engine.getCategoryBreakdown(
        transactions,
        type: TransactionType.store,
      ),
      monthlyBurn: engine.getMonthlyBurn(transactions),
      monthlyStore: engine.getMonthlyStore(transactions),
      prevMonthlyBurn: engine.getPrevMonthlyBurn(transactions),
      prevMonthlyStore: engine.getPrevMonthlyStore(transactions),
      monthlyBurnCategoryBreakdown: engine.getCategoryBreakdown(
        monthly,
        type: TransactionType.burn,
      ),
      monthlyTransactions: monthly,
    );
  });
});

class _Analytics {
  final double totalBurn;
  final double totalStore;
  final double delta;
  final List<double> weeklySpend;
  final Map<CategoryEntity, double> burnCategoryBreakdown;
  final Map<CategoryEntity, double> storeCategoryBreakdown;
  final double monthlyBurn;
  final double monthlyStore;
  final double prevMonthlyBurn;
  final double prevMonthlyStore;
  final Map<CategoryEntity, double> monthlyBurnCategoryBreakdown;
  final List<TransactionEntity> monthlyTransactions;

  const _Analytics({
    required this.totalBurn,
    required this.totalStore,
    required this.delta,
    required this.weeklySpend,
    required this.burnCategoryBreakdown,
    required this.storeCategoryBreakdown,
    required this.monthlyBurn,
    required this.monthlyStore,
    required this.prevMonthlyBurn,
    required this.prevMonthlyStore,
    required this.monthlyBurnCategoryBreakdown,
    required this.monthlyTransactions,
  });

  double get totalBalance => totalStore - totalBurn;
}

// Export _Analytics as AppAnalytics for use in views.
typedef AppAnalytics = _Analytics;

// ─── Category State ───────────────────────────────────────────────────────────

class CategorySearchNotifier extends StateNotifier<List<CategoryEntity>> {
  CategorySearchNotifier(this._repo) : super([]);

  final CategoryRepository _repo;

  Future<void> search(String query) async {
    final results = await _repo.searchByName(query);
    state = results;
  }

  void clear() => state = [];
}

final categorySearchProvider =
    StateNotifierProvider<CategorySearchNotifier, List<CategoryEntity>>((ref) {
  return CategorySearchNotifier(ref.watch(categoryRepositoryProvider));
});

// ─── Transaction Filter ───────────────────────────────────────────────────────

enum FilterType { all, burn, store }

final filterProvider = StateProvider<FilterType>((ref) => FilterType.all);

final filteredTransactionProvider = Provider<AsyncValue<List<TransactionEntity>>>(
  (ref) {
    final filter = ref.watch(filterProvider);
    final txAsync = ref.watch(transactionListProvider);

    return txAsync.whenData((transactions) {
      return switch (filter) {
        FilterType.all => transactions,
        FilterType.burn =>
          transactions.where((t) => t.type == TransactionType.burn).toList(),
        FilterType.store =>
          transactions.where((t) => t.type == TransactionType.store).toList(),
      };
    });
  },
);
