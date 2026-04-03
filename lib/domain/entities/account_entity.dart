import 'package:flutter/material.dart';
import '../../core/constants/indian_banks.dart';

class AccountEntity {
  const AccountEntity({
    required this.id,
    required this.name,
    this.bankCode,
    required this.balance,
    required this.colorValue,
    this.isPrimary = false,
  });

  final int id;
  final String name;
  final String? bankCode;
  final double balance;
  final int colorValue;
  final bool isPrimary;

  Color get color => Color(colorValue);

  IndianBank? get bank =>
      bankCode != null ? IndianBanks.findByCode(bankCode!) : null;

  AccountEntity copyWith({
    int? id,
    String? name,
    Object? bankCode = _sentinel,
    double? balance,
    int? colorValue,
    bool? isPrimary,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      bankCode: bankCode == _sentinel ? this.bankCode : bankCode as String?,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AccountEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

const _sentinel = Object();
