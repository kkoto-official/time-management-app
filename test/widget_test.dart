import 'package:flutter_test/flutter_test.dart';
import 'package:time_management_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TimeManagementApp());
    await tester.pump();
    expect(find.text('今日の記録'), findsOneWidget);
  });
}
