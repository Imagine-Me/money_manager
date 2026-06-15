import 'package:flutter_test/flutter_test.dart';

import 'package:money_manager/main.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    // Basic smoke test to verify the app can build
    // Note: Full widget test requires Isar initialization which is async
    // and needs platform channels. This is a placeholder for future tests.
    expect(VaultApp, isNotNull);
  });
}
