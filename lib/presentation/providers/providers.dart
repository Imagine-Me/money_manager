import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/data/datasources/local/isar_service.dart';
import 'package:money_manager/data/repositories/account_repository_impl.dart';
import 'package:money_manager/data/repositories/category_repository_impl.dart';
import 'package:money_manager/data/repositories/recurring_transaction_repository_impl.dart';
import 'package:money_manager/data/repositories/report_filter_repository_impl.dart';
import 'package:money_manager/data/repositories/transaction_repository_impl.dart';
import 'package:money_manager/domain/entities/account_entity.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/recurring_transaction_entity.dart';
import 'package:money_manager/domain/entities/report_filter_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/domain/repositories/account_repository.dart';
import 'package:money_manager/domain/repositories/category_repository.dart';
import 'package:money_manager/domain/repositories/recurring_transaction_repository.dart';
import 'package:money_manager/domain/repositories/report_filter_repository.dart';
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

final recurringTransactionRepositoryProvider =
    Provider<RecurringTransactionRepository>((ref) {
  return RecurringTransactionRepositoryImpl(ref.watch(isarServiceProvider));
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(ref.watch(isarServiceProvider));
});

final analyticsEngineProvider = Provider<AnalyticsEngine>((ref) {
  return const AnalyticsEngine();
});

// ─── Streams / Watches ────────────────────────────────────────────────────────

final categoryListProvider = StreamProvider<List<CategoryEntity>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

final accountListProvider = StreamProvider<List<AccountEntity>>((ref) {
  return ref.watch(accountRepositoryProvider).watchAll();
});

final primaryAccountProvider = Provider<AsyncValue<AccountEntity?>>((ref) {
  return ref.watch(accountListProvider).whenData((accounts) {
    if (accounts.isEmpty) return null;
    return accounts.firstWhere(
      (a) => a.isPrimary,
      orElse: () => accounts.first,
    );
  });
});

final transactionListProvider = StreamProvider<List<TransactionEntity>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

final recurringTransactionListProvider =
    StreamProvider<List<RecurringTransactionEntity>>((ref) {
  return ref.watch(recurringTransactionRepositoryProvider).watchAll();
});

// ─── Analytics ────────────────────────────────────────────────────────────────

final analyticsProvider = Provider<AsyncValue<AppAnalytics>>((ref) {
  final txAsync = ref.watch(transactionListProvider);
  final catAsync = ref.watch(categoryListProvider);
  final engine = ref.watch(analyticsEngineProvider);

  return switch ((txAsync, catAsync)) {
    (AsyncLoading(), _) || (_, AsyncLoading()) => const AsyncValue.loading(),
    (AsyncError(:final error, :final stackTrace), _) =>
      AsyncValue.error(error, stackTrace),
    (_, AsyncError(:final error, :final stackTrace)) =>
      AsyncValue.error(error, stackTrace),
    (AsyncData(value: final transactions), AsyncData(value: final categories)) =>
      AsyncValue.data(() {
        final monthly = engine.getMonthlyTransactions(transactions);
        return _Analytics(
          totalBurn: engine.getTotalBurn(transactions),
          totalStore: engine.getTotalStore(transactions),
          delta: engine.calculateDelta(transactions),
          weeklySpend: engine.getWeeklySpend(transactions),
          burnCategoryBreakdown: engine.getCategoryBreakdown(
            transactions, type: TransactionType.burn,
          ),
          storeCategoryBreakdown: engine.getCategoryBreakdown(
            transactions, type: TransactionType.store,
          ),
          burnParentBreakdown: engine.getParentCategoryBreakdown(
            transactions, allCategories: categories, type: TransactionType.burn,
          ),
          storeParentBreakdown: engine.getParentCategoryBreakdown(
            transactions, allCategories: categories, type: TransactionType.store,
          ),
          monthlyBurn: engine.getMonthlyBurn(transactions),
          monthlyStore: engine.getMonthlyStore(transactions),
          prevMonthlyBurn: engine.getPrevMonthlyBurn(transactions),
          prevMonthlyStore: engine.getPrevMonthlyStore(transactions),
          monthlyBurnCategoryBreakdown: engine.getCategoryBreakdown(
            monthly, type: TransactionType.burn,
          ),
          monthlyBurnParentBreakdown: engine.getParentCategoryBreakdown(
            monthly, allCategories: categories, type: TransactionType.burn,
          ),
          monthlyTransactions: monthly,
        );
      }()),
    _ => const AsyncValue.loading(),
  };
});

class _Analytics {
  final double totalBurn;
  final double totalStore;
  final double delta;
  final List<double> weeklySpend;
  final Map<CategoryEntity, double> burnCategoryBreakdown;
  final Map<CategoryEntity, double> storeCategoryBreakdown;
  final Map<CategoryEntity, double> burnParentBreakdown;
  final Map<CategoryEntity, double> storeParentBreakdown;
  final double monthlyBurn;
  final double monthlyStore;
  final double prevMonthlyBurn;
  final double prevMonthlyStore;
  final Map<CategoryEntity, double> monthlyBurnCategoryBreakdown;
  final Map<CategoryEntity, double> monthlyBurnParentBreakdown;
  final List<TransactionEntity> monthlyTransactions;

  const _Analytics({
    required this.totalBurn,
    required this.totalStore,
    required this.delta,
    required this.weeklySpend,
    required this.burnCategoryBreakdown,
    required this.storeCategoryBreakdown,
    required this.burnParentBreakdown,
    required this.storeParentBreakdown,
    required this.monthlyBurn,
    required this.monthlyStore,
    required this.prevMonthlyBurn,
    required this.prevMonthlyStore,
    required this.monthlyBurnCategoryBreakdown,
    required this.monthlyBurnParentBreakdown,
    required this.monthlyTransactions,
  });

  double get totalBalance => totalStore - totalBurn;
}

// ─── Navigation ───────────────────────────────────────────────────────────────

/// Index of the currently visible tab in HomeShell (0=Dashboard, 1=Reports…)
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// A pending filter preset to be applied when the reports tab opens.
final pendingReportFilterProvider =
    StateProvider<ReportFilterEntity?>((ref) => null);

/// Incremented each time the user taps Reports in the bottom nav directly
/// (not via a dashboard preset chip). ReportView listens and clears filters.
final reportFilterResetProvider = StateProvider<int>((ref) => 0);

// ─── Report filter presets ────────────────────────────────────────────────────

final reportFilterRepositoryProvider = Provider<ReportFilterRepository>((ref) {
  return ReportFilterRepositoryImpl(ref.watch(isarServiceProvider));
});

final reportFilterListProvider =
    StreamProvider<List<ReportFilterEntity>>((ref) {
  return ref.watch(reportFilterRepositoryProvider).watchAll();
});

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

enum FilterType { all, burn, store, income }

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
        FilterType.income =>
          transactions.where((t) => t.type == TransactionType.income).toList(),
      };
    });
  },
);
