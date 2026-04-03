import 'package:isar/isar.dart';

part 'account_model.g.dart';

@collection
class AccountModel {
  Id id = Isar.autoIncrement;
  late String name;
  String? bankCode;
  late double balance;
  late int colorValue;
  bool isPrimary = false;
}
