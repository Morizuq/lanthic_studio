import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanthic_studio/main.dart';

void main() {
  testWidgets('LanthicStudioApp smoke test launches with empty state view', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LanthicStudioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lanthic Studio'), findsWidgets);
    expect(find.text('Open Skills Engine Project'), findsOneWidget);
    expect(find.text('Load Sample Project'), findsOneWidget);
  });
}
