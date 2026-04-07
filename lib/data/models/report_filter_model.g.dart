// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_filter_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetReportFilterModelCollection on Isar {
  IsarCollection<ReportFilterModel> get reportFilterModels => this.collection();
}

const ReportFilterModelSchema = CollectionSchema(
  name: r'ReportFilterModel',
  id: -68009103555882177,
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
    r'period': PropertySchema(
      id: 3,
      name: r'period',
      type: IsarType.string,
    ),
    r'showSubcategories': PropertySchema(
      id: 4,
      name: r'showSubcategories',
      type: IsarType.bool,
    ),
    r'typeTab': PropertySchema(
      id: 5,
      name: r'typeTab',
      type: IsarType.string,
    )
  },
  estimateSize: _reportFilterModelEstimateSize,
  serialize: _reportFilterModelSerialize,
  deserialize: _reportFilterModelDeserialize,
  deserializeProp: _reportFilterModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _reportFilterModelGetId,
  getLinks: _reportFilterModelGetLinks,
  attach: _reportFilterModelAttach,
  version: '3.1.0+1',
);

int _reportFilterModelEstimateSize(
  ReportFilterModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.categoryFilterIds.length * 8;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.period.length * 3;
  bytesCount += 3 + object.typeTab.length * 3;
  return bytesCount;
}

void _reportFilterModelSerialize(
  ReportFilterModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLongList(offsets[0], object.categoryFilterIds);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.name);
  writer.writeString(offsets[3], object.period);
  writer.writeBool(offsets[4], object.showSubcategories);
  writer.writeString(offsets[5], object.typeTab);
}

ReportFilterModel _reportFilterModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ReportFilterModel();
  object.categoryFilterIds = reader.readLongList(offsets[0]) ?? [];
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.name = reader.readString(offsets[2]);
  object.period = reader.readString(offsets[3]);
  object.showSubcategories = reader.readBool(offsets[4]);
  object.typeTab = reader.readString(offsets[5]);
  return object;
}

P _reportFilterModelDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _reportFilterModelGetId(ReportFilterModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _reportFilterModelGetLinks(
    ReportFilterModel object) {
  return [];
}

void _reportFilterModelAttach(
    IsarCollection<dynamic> col, Id id, ReportFilterModel object) {
  object.id = id;
}

extension ReportFilterModelQueryWhereSort
    on QueryBuilder<ReportFilterModel, ReportFilterModel, QWhere> {
  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ReportFilterModelQueryWhere
    on QueryBuilder<ReportFilterModel, ReportFilterModel, QWhereClause> {
  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterWhereClause>
      idBetween(
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

extension ReportFilterModelQueryFilter
    on QueryBuilder<ReportFilterModel, ReportFilterModel, QFilterCondition> {
  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      categoryFilterIdsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryFilterIds',
        value: value,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      categoryFilterIdsElementGreaterThan(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      categoryFilterIdsElementLessThan(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      categoryFilterIdsElementBetween(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      categoryFilterIdsLengthEqualTo(int length) {
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      categoryFilterIdsIsEmpty() {
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      categoryFilterIdsIsNotEmpty() {
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      categoryFilterIdsLengthLessThan(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      categoryFilterIdsLengthGreaterThan(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      categoryFilterIdsLengthBetween(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      createdAtGreaterThan(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      createdAtLessThan(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      createdAtBetween(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      nameEqualTo(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      nameGreaterThan(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      nameLessThan(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      nameBetween(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      nameStartsWith(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      nameEndsWith(
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

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      periodEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'period',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      periodGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'period',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      periodLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'period',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      periodBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'period',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      periodStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'period',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      periodEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'period',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      periodContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'period',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      periodMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'period',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      periodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'period',
        value: '',
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      periodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'period',
        value: '',
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      showSubcategoriesEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'showSubcategories',
        value: value,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      typeTabEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typeTab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      typeTabGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'typeTab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      typeTabLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'typeTab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      typeTabBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'typeTab',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      typeTabStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'typeTab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      typeTabEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'typeTab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      typeTabContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'typeTab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      typeTabMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'typeTab',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      typeTabIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typeTab',
        value: '',
      ));
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterFilterCondition>
      typeTabIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'typeTab',
        value: '',
      ));
    });
  }
}

extension ReportFilterModelQueryObject
    on QueryBuilder<ReportFilterModel, ReportFilterModel, QFilterCondition> {}

extension ReportFilterModelQueryLinks
    on QueryBuilder<ReportFilterModel, ReportFilterModel, QFilterCondition> {}

extension ReportFilterModelQuerySortBy
    on QueryBuilder<ReportFilterModel, ReportFilterModel, QSortBy> {
  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      sortByPeriod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'period', Sort.asc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      sortByPeriodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'period', Sort.desc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      sortByShowSubcategories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubcategories', Sort.asc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      sortByShowSubcategoriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubcategories', Sort.desc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      sortByTypeTab() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeTab', Sort.asc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      sortByTypeTabDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeTab', Sort.desc);
    });
  }
}

extension ReportFilterModelQuerySortThenBy
    on QueryBuilder<ReportFilterModel, ReportFilterModel, QSortThenBy> {
  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      thenByPeriod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'period', Sort.asc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      thenByPeriodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'period', Sort.desc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      thenByShowSubcategories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubcategories', Sort.asc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      thenByShowSubcategoriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubcategories', Sort.desc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      thenByTypeTab() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeTab', Sort.asc);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QAfterSortBy>
      thenByTypeTabDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeTab', Sort.desc);
    });
  }
}

extension ReportFilterModelQueryWhereDistinct
    on QueryBuilder<ReportFilterModel, ReportFilterModel, QDistinct> {
  QueryBuilder<ReportFilterModel, ReportFilterModel, QDistinct>
      distinctByCategoryFilterIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryFilterIds');
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QDistinct>
      distinctByPeriod({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'period', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QDistinct>
      distinctByShowSubcategories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'showSubcategories');
    });
  }

  QueryBuilder<ReportFilterModel, ReportFilterModel, QDistinct>
      distinctByTypeTab({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'typeTab', caseSensitive: caseSensitive);
    });
  }
}

extension ReportFilterModelQueryProperty
    on QueryBuilder<ReportFilterModel, ReportFilterModel, QQueryProperty> {
  QueryBuilder<ReportFilterModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ReportFilterModel, List<int>, QQueryOperations>
      categoryFilterIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryFilterIds');
    });
  }

  QueryBuilder<ReportFilterModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ReportFilterModel, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<ReportFilterModel, String, QQueryOperations> periodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'period');
    });
  }

  QueryBuilder<ReportFilterModel, bool, QQueryOperations>
      showSubcategoriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'showSubcategories');
    });
  }

  QueryBuilder<ReportFilterModel, String, QQueryOperations> typeTabProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'typeTab');
    });
  }
}
