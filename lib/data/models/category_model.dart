import 'package:isar/isar.dart';

part 'category_model.g.dart';

@collection
class CategoryModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String name;

  late int colorValue;
  late int iconCodePoint;
  late String iconFontFamily;
  late String type; // 'burn' or 'store'
  int? parentId;    // null = top-level category; non-null = subcategory
}
