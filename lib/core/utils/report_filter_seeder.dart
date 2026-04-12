import 'package:isar/isar.dart';
import 'package:money_manager/data/models/category_model.dart';
import 'package:money_manager/data/models/report_filter_model.dart';

class ReportFilterSeeder {
  ReportFilterSeeder._();

  static const String _periodOverall = 'overall';

  static Future<void> seedDefaultLockedPresets(Isar isar) async {
    final topLevel = await isar.categoryModels.filter().parentIdIsNull().findAll();
    final existing = await isar.reportFilterModels.where().findAll();

    List<int> idsForType(String type) {
      final ids = topLevel
          .where((c) => c.type == type)
          .map((c) => c.id)
          .toList();
      ids.sort();
      return ids;
    }

    final specs = [
      ('Burn', 'burn', idsForType('burn')),
      ('Store', 'store', idsForType('store')),
      ('Income', 'income', idsForType('income')),
    ];

    await isar.writeTxn(() async {
      for (final (name, typeTab, categoryIds) in specs) {
        final model = existing.cast<ReportFilterModel?>().firstWhere(
              (m) =>
                  m != null &&
                  m.name == name &&
                  m.typeTab == typeTab &&
                  m.period == _periodOverall,
              orElse: () => null,
            );

        if (model == null) {
          await isar.reportFilterModels.put(
            ReportFilterModel()
              ..name = name
              ..period = _periodOverall
              ..typeTab = typeTab
              ..categoryFilterIds = categoryIds
              ..showSubcategories = false
              ..createdAt = DateTime.now(),
          );
          continue;
        }

        final needsUpdate =
            model.showSubcategories || !_sameIds(model.categoryFilterIds, categoryIds);
        if (!needsUpdate) continue;

        model.categoryFilterIds = categoryIds;
        model.showSubcategories = false;
        await isar.reportFilterModels.put(model);
      }
    });
  }

  static bool isLockedPresetModel(ReportFilterModel model) {
    if (model.period != _periodOverall) return false;
    return (model.name == 'Burn' && model.typeTab == 'burn') ||
        (model.name == 'Store' && model.typeTab == 'store') ||
        (model.name == 'Income' && model.typeTab == 'income');
  }

  static bool _sameIds(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sa = a.toSet();
    final sb = b.toSet();
    if (sa.length != sb.length) return false;
    for (final id in sa) {
      if (!sb.contains(id)) return false;
    }
    return true;
  }
}