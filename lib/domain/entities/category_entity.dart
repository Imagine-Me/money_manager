import 'package:flutter/material.dart';
import 'package:money_manager/core/constants/app_constants.dart';

class CategoryEntity {
  final int id;
  final String name;
  final int colorValue;
  final int iconCodePoint;
  final String iconFontFamily;
  final TransactionType type;
  final int? parentId; // null = top-level; non-null = subcategory

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.type,
    this.parentId,
  });

  bool get isSubcategory => parentId != null;

  Color get color => Color(colorValue);

  IconData get icon => IconData(iconCodePoint, fontFamily: iconFontFamily);

  CategoryEntity copyWith({
    int? id,
    String? name,
    int? colorValue,
    int? iconCodePoint,
    String? iconFontFamily,
    TransactionType? type,
    int? parentId,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
