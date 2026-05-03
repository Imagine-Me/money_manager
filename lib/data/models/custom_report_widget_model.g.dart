// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_report_widget_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCustomReportWidgetModelCollection on Isar {
  IsarCollection<CustomReportWidgetModel> get customReportWidgetModels =>
      this.collection();
}

const CustomReportWidgetModelSchema = CollectionSchema(
  name: r'CustomReportWidgetModel',
  id: 9077801428312263381,
  properties: {
    r'categoryFilterIds': PropertySchema(
      id: 0,
      name: r'categoryFilterIds',
      type: IsarType.longList,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 2,
      name: r'name',
      type: IsarType.string,
    ),
    r'showSubcategories': PropertySchema(
      id: 3,
      name: r'showSubcategories',
      type: IsarType.bool,
    ),
    r'sortOrder': PropertySchema(
      id: 4,
      name: r'sortOrder',
      type: IsarType.long,
    ),
    r'transactionType': PropertySchema(
      id: 5,
      name: r'transactionType',
      type: IsarType.string,
    )
  },
  estimateSize: _customReportWidgetModelEstimateSize,
  serialize: _customReportWidgetModelSerialize,
  deserialize: _customReportWidgetModelDeserialize,
  deserializeProp: _customReportWidgetModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _customReportWidgetModelGetId,
  getLinks: _customReportWidgetModelGetLinks,
  attach: _customReportWidgetModelAttach,
  version: '3.1.0+1',
);

int _customReportWidgetModelEstimateSize(
  CustomReportWidgetModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.categoryFilterIds.length * 8;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.transactionType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _customReportWidgetModelSerialize(
  CustomReportWidgetModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLongList(offsets[0], object.categoryFilterIds);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.name);
  writer.writeBool(offsets[3], object.showSubcategories);
  writer.writeLong(offsets[4], object.sortOrder);
  writer.writeString(offsets[5], object.transactionType);
}

CustomReportWidgetModel _customReportWidgetModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CustomReportWidgetModel();
  object.categoryFilterIds = reader.readLongList(offsets[0]) ?? [];
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.name = reader.readString(offsets[2]);
  object.showSubcategories = reader.readBool(offsets[3]);
  object.sortOrder = reader.readLong(offsets[4]);
  object.transactionType = reader.readStringOrNull(offsets[5]);
  return object;
}

P _customReportWidgetModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongList(offset) ?? []) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _customReportWidgetModelGetId(CustomReportWidgetModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _customReportWidgetModelGetLinks(
    CustomReportWidgetModel object) {
  return [];
}

void _customReportWidgetModelAttach(
    IsarCollection<dynamic> col, Id id, CustomReportWidgetModel object) {
  object.id = id;
}

extension CustomReportWidgetModelQueryWhereSort
    on QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QWhere> {
  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CustomReportWidgetModelQueryWhere on QueryBuilder<
    CustomReportWidgetModel, CustomReportWidgetModel, QWhereClause> {
  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CustomReportWidgetModelQueryFilter on QueryBuilder<
    CustomReportWidgetModel, CustomReportWidgetModel, QFilterCondition> {
  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> categoryFilterIdsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryFilterIds',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> categoryFilterIdsElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryFilterIds',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> categoryFilterIdsElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryFilterIds',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> categoryFilterIdsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryFilterIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> categoryFilterIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'categoryFilterIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> categoryFilterIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'categoryFilterIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> categoryFilterIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'categoryFilterIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> categoryFilterIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'categoryFilterIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> categoryFilterIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'categoryFilterIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> categoryFilterIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'categoryFilterIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
          QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
          QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> showSubcategoriesEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'showSubcategories',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> sortOrderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> sortOrderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> sortOrderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sortOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> sortOrderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sortOrder',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> transactionTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'transactionType',
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> transactionTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'transactionType',
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> transactionTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> transactionTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> transactionTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> transactionTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transactionType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> transactionTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> transactionTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
          QAfterFilterCondition>
      transactionTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
          QAfterFilterCondition>
      transactionTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'transactionType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> transactionTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transactionType',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel,
      QAfterFilterCondition> transactionTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'transactionType',
        value: '',
      ));
    });
  }
}

extension CustomReportWidgetModelQueryObject on QueryBuilder<
    CustomReportWidgetModel, CustomReportWidgetModel, QFilterCondition> {}

extension CustomReportWidgetModelQueryLinks on QueryBuilder<
    CustomReportWidgetModel, CustomReportWidgetModel, QFilterCondition> {}

extension CustomReportWidgetModelQuerySortBy
    on QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QSortBy> {
  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      sortByShowSubcategories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubcategories', Sort.asc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      sortByShowSubcategoriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubcategories', Sort.desc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      sortBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      sortBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      sortByTransactionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.asc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      sortByTransactionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.desc);
    });
  }
}

extension CustomReportWidgetModelQuerySortThenBy on QueryBuilder<
    CustomReportWidgetModel, CustomReportWidgetModel, QSortThenBy> {
  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      thenByShowSubcategories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubcategories', Sort.asc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      thenByShowSubcategoriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubcategories', Sort.desc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      thenBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      thenBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      thenByTransactionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.asc);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QAfterSortBy>
      thenByTransactionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.desc);
    });
  }
}

extension CustomReportWidgetModelQueryWhereDistinct on QueryBuilder<
    CustomReportWidgetModel, CustomReportWidgetModel, QDistinct> {
  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QDistinct>
      distinctByCategoryFilterIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryFilterIds');
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QDistinct>
      distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QDistinct>
      distinctByShowSubcategories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'showSubcategories');
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QDistinct>
      distinctBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sortOrder');
    });
  }

  QueryBuilder<CustomReportWidgetModel, CustomReportWidgetModel, QDistinct>
      distinctByTransactionType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transactionType',
          caseSensitive: caseSensitive);
    });
  }
}

extension CustomReportWidgetModelQueryProperty on QueryBuilder<
    CustomReportWidgetModel, CustomReportWidgetModel, QQueryProperty> {
  QueryBuilder<CustomReportWidgetModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CustomReportWidgetModel, List<int>, QQueryOperations>
      categoryFilterIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryFilterIds');
    });
  }

  QueryBuilder<CustomReportWidgetModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CustomReportWidgetModel, String, QQueryOperations>
      nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<CustomReportWidgetModel, bool, QQueryOperations>
      showSubcategoriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'showSubcategories');
    });
  }

  QueryBuilder<CustomReportWidgetModel, int, QQueryOperations>
      sortOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sortOrder');
    });
  }

  QueryBuilder<CustomReportWidgetModel, String?, QQueryOperations>
      transactionTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transactionType');
    });
  }
}
