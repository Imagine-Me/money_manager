import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/domain/entities/category_entity.dart';

class TransactionEntity {
  final int id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String note;
  final CategoryEntity? category;
  final int? accountId;
  final int? toAccountId;

  const TransactionEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.note,
    this.category,
    this.accountId,
    this.toAccountId,
  });

  bool get isBurn => type == TransactionType.burn;
  bool get isStore => type == TransactionType.store;
  bool get isTransfer => type == TransactionType.transfer;
  bool get isIncome => type == TransactionType.income;

  TransactionEntity copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    TransactionType? type,
    String? note,
    CategoryEntity? category,
    Object? accountId = _sentinel,
    Object? toAccountId = _sentinel,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
      category: category ?? this.category,
      accountId:
          accountId == _sentinel ? this.accountId : accountId as int?,
      toAccountId:
          toAccountId == _sentinel ? this.toAccountId : toAccountId as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const _sentinel = Object();
