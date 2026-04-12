import 'dart:convert';
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:money_manager/core/services/preferences_service.dart';
import 'package:money_manager/data/datasources/local/isar_service.dart';
import 'package:money_manager/data/models/account_model.dart';
import 'package:money_manager/data/models/category_model.dart';
import 'package:money_manager/data/models/recurring_transaction_model.dart';
import 'package:money_manager/data/models/report_filter_model.dart';
import 'package:money_manager/data/models/transaction_model.dart';
import 'package:money_manager/services/google_auth_service.dart';

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const _backupFileName = 'vaultcash_backup.json';

  // ─── Export ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportData() async {
    final db = IsarService.instance.db;

    final accounts = await db.accountModels.where().anyId().findAll();
    final categories = await db.categoryModels.where().anyId().findAll();
    final transactions =
        await db.transactionModels.where().anyId().findAll();
    for (final tx in transactions) {
      await tx.category.load();
    }
    final recurring =
        await db.recurringTransactionModels.where().anyId().findAll();
    for (final r in recurring) {
      await r.category.load();
    }
    final reportFilters =
        await db.reportFilterModels.where().anyId().findAll();

    final prefs = PreferencesService.instance;
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'currency': {
        'symbol': prefs.currencySymbol,
        'name': prefs.currencyName,
        'locale': prefs.currencyLocale,
      },
      'accounts': accounts.map(_accountToMap).toList(),
      'categories': categories.map(_categoryToMap).toList(),
      'transactions': transactions.map(_transactionToMap).toList(),
      'recurringTransactions': recurring.map(_recurringToMap).toList(),
      'reportFilters': reportFilters.map(_reportFilterToMap).toList(),
    };
  }

  Map<String, dynamic> _accountToMap(AccountModel m) => {
        'id': m.id,
        'name': m.name,
        'bankCode': m.bankCode,
        'balance': m.balance,
        'colorValue': m.colorValue,
        'isPrimary': m.isPrimary,
      };

  Map<String, dynamic> _categoryToMap(CategoryModel m) => {
        'id': m.id,
        'name': m.name,
        'colorValue': m.colorValue,
        'iconCodePoint': m.iconCodePoint,
        'iconFontFamily': m.iconFontFamily,
        'type': m.type,
        'parentId': m.parentId,
      };

  Map<String, dynamic> _transactionToMap(TransactionModel m) => {
        'id': m.id,
        'title': m.title,
        'amount': m.amount,
        'date': m.date.toIso8601String(),
        'type': m.type,
        'note': m.note,
        'accountId': m.accountId,
        'toAccountId': m.toAccountId,
        'categoryId': m.category.value?.id,
      };

  Map<String, dynamic> _recurringToMap(RecurringTransactionModel m) => {
        'id': m.id,
        'title': m.title,
        'amount': m.amount,
        'type': m.type,
        'note': m.note,
        'frequency': m.frequency,
        'recurDay': m.recurDay,
        'recurMonth': m.recurMonth,
        'accountId': m.accountId,
        'lastExecutedDate': m.lastExecutedDate?.toIso8601String(),
        'categoryId': m.category.value?.id,
      };

  Map<String, dynamic> _reportFilterToMap(ReportFilterModel m) => {
        'id': m.id,
        'name': m.name,
        'period': m.period,
        'typeTab': m.typeTab,
        'categoryFilterIds': m.categoryFilterIds,
        'showSubcategories': m.showSubcategories,
        'createdAt': m.createdAt.toIso8601String(),
      };

  // ─── Import ──────────────────────────────────────────────────────────────────

  Future<void> importData(Map<String, dynamic> data) async {
    final db = IsarService.instance.db;

    final accountMaps =
        (data['accounts'] as List).cast<Map<String, dynamic>>();
    final categoryMaps =
        (data['categories'] as List).cast<Map<String, dynamic>>();
    final txMaps =
        (data['transactions'] as List).cast<Map<String, dynamic>>();
    final recurMaps =
        (data['recurringTransactions'] as List).cast<Map<String, dynamic>>();
    final filterMaps = data.containsKey('reportFilters')
        ? (data['reportFilters'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    // Restore currency settings if present
    if (data.containsKey('currency')) {
      final c = data['currency'] as Map<String, dynamic>;
      await PreferencesService.instance.saveCurrency(
        symbol: c['symbol'] as String,
        name: c['name'] as String,
        locale: c['locale'] as String,
      );
    }

    await db.writeTxn(() async {
      // Clear in dependency order (transactions first, then accounts/categories)
      await db.transactionModels.clear();
      await db.recurringTransactionModels.clear();
      await db.accountModels.clear();
      await db.categoryModels.clear();
      await db.reportFilterModels.clear();

      // Import categories (transactions reference them by link)
      final categories = categoryMaps.map((m) {
        return CategoryModel()
          ..id = m['id'] as int
          ..name = m['name'] as String
          ..colorValue = m['colorValue'] as int
          ..iconCodePoint = m['iconCodePoint'] as int
          ..iconFontFamily = m['iconFontFamily'] as String
          ..type = m['type'] as String
          ..parentId = m['parentId'] as int?;
      }).toList();
      await db.categoryModels.putAll(categories);

      // Import accounts
      final accounts = accountMaps.map((m) {
        return AccountModel()
          ..id = m['id'] as int
          ..name = m['name'] as String
          ..bankCode = m['bankCode'] as String?
          ..balance = (m['balance'] as num).toDouble()
          ..colorValue = m['colorValue'] as int
          ..isPrimary = m['isPrimary'] as bool;
      }).toList();
      await db.accountModels.putAll(accounts);

      // Import transactions then save category links
      final txns = txMaps.map((m) {
        return TransactionModel()
          ..id = m['id'] as int
          ..title = m['title'] as String
          ..amount = (m['amount'] as num).toDouble()
          ..date = DateTime.parse(m['date'] as String)
          ..type = m['type'] as String
          ..note = m['note'] as String
          ..accountId = m['accountId'] as int?
          ..toAccountId = m['toAccountId'] as int?;
      }).toList();
      await db.transactionModels.putAll(txns);

      for (int i = 0; i < txns.length; i++) {
        final categoryId = txMaps[i]['categoryId'] as int?;
        if (categoryId != null) {
          final cat = await db.categoryModels.get(categoryId);
          if (cat != null) {
            txns[i].category.value = cat;
            await txns[i].category.save();
          }
        }
      }

      // Import recurring transactions then save category links
      final recurrings = recurMaps.map((m) {
        return RecurringTransactionModel()
          ..id = m['id'] as int
          ..title = m['title'] as String
          ..amount = (m['amount'] as num).toDouble()
          ..type = m['type'] as String
          ..note = m['note'] as String
          ..frequency = m['frequency'] as String
          ..recurDay = m['recurDay'] as int
          ..recurMonth = m['recurMonth'] as int
          ..accountId = m['accountId'] as int?
          ..lastExecutedDate = m['lastExecutedDate'] != null
              ? DateTime.parse(m['lastExecutedDate'] as String)
              : null;
      }).toList();
      await db.recurringTransactionModels.putAll(recurrings);

      for (int i = 0; i < recurrings.length; i++) {
        final categoryId = recurMaps[i]['categoryId'] as int?;
        if (categoryId != null) {
          final cat = await db.categoryModels.get(categoryId);
          if (cat != null) {
            recurrings[i].category.value = cat;
            await recurrings[i].category.save();
          }
        }
      }

      // Restore report filter presets
      if (filterMaps.isNotEmpty) {
        final filters = filterMaps.map((m) {
          return ReportFilterModel()
            ..id = m['id'] as int
            ..name = m['name'] as String
            ..period = m['period'] as String
            ..typeTab = m['typeTab'] as String
            ..categoryFilterIds =
                (m['categoryFilterIds'] as List).cast<int>()
            ..showSubcategories = m['showSubcategories'] as bool
            ..createdAt = DateTime.parse(m['createdAt'] as String);
        }).toList();
        await db.reportFilterModels.putAll(filters);
      }
    });
  }

  // ─── Drive ───────────────────────────────────────────────────────────────────

  Future<T> _withDrive<T>(
      Future<T> Function(drive.DriveApi api) fn) async {
    final headers = await GoogleAuthService.instance.getAuthHeaders();
    if (headers == null) throw StateError('Not signed in to Google');
    final client = _AuthClient(headers);
    try {
      return await fn(drive.DriveApi(client));
    } finally {
      client.close();
    }
  }

  Future<String?> _findBackupFileId(drive.DriveApi api) async {
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName'",
      $fields: 'files(id)',
    );
    return list.files?.firstOrNull?.id;
  }

  /// Silently syncs to Drive if the user is signed in. Fire-and-forget — never
  /// throws. Call this after any mutation (save / delete transaction).
  void triggerAutoSync() {
    if (GoogleAuthService.instance.currentUser == null) return;
    backupToDrive().catchError((_) {});
  }

  /// Exports all data and uploads it to Google Drive appdata.
  Future<void> backupToDrive() async {
    final data = await exportData();
    final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));

    await _withDrive((api) async {
      final stream = Stream<List<int>>.value(jsonBytes);
      final media = drive.Media(stream, jsonBytes.length,
          contentType: 'application/json');

      final existingId = await _findBackupFileId(api);
      if (existingId != null) {
        await api.files.update(drive.File(), existingId, uploadMedia: media);
      } else {
        final file = drive.File()
          ..name = _backupFileName
          ..parents = ['appDataFolder'];
        await api.files.create(file, uploadMedia: media);
      }
    });

    await PreferencesService.instance
        .setLastBackupDate(DateTime.now());
  }

  /// Downloads the backup from Google Drive and imports it.
  /// Returns false if no backup exists on Drive.
  Future<bool> restoreFromDrive() async {
    return _withDrive((api) async {
      final fileId = await _findBackupFileId(api);
      if (fileId == null) return false;

      final response = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      final json =
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      await importData(json);
      return true;
    });
  }

  /// Returns true if a backup file exists on Drive (user must be signed in).
  Future<bool> hasBackupOnDrive() async {
    return _withDrive((api) async {
      final id = await _findBackupFileId(api);
      return id != null;
    });
  }
}

// ─── HTTP client that injects Google auth headers ────────────────────────────
class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final _inner = http.Client();

  _AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
