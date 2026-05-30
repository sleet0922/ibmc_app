import 'package:flutter_test/flutter_test.dart';

import 'package:ibmc_app/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const IBMCApp());
    expect(find.text('iBMC'), findsOneWidget);
    expect(find.text('服务器管理控制台'), findsOneWidget);
  });
}