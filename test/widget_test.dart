import 'package:flutter_test/flutter_test.dart';
import 'package:budget_buddy/main.dart';

void main() {
  testWidgets('Budget Buddy smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BudgetBuddyApp());
    expect(find.byType(BudgetBuddyApp), findsOneWidget);
  });
}
