import 'package:flutter_test/flutter_test.dart';

import 'package:ibmc_app/main.dart';

void main() {
  testWidgets('App renders connection screen', (WidgetTester tester) async {
    await tester.pumpWidget(const IBMCApp());
    expect(find.text('iBMC 服务器管理'), findsOneWidget);
    expect(find.text('服务器连接'), findsOneWidget);
  });
}