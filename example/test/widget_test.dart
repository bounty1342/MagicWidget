import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_widget/magic_widget.dart';
import 'package:magic_widget_example/main.dart';

void main() {
  testWidgets('playground shows the MAGIC preview and the control panel',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MagicExampleApp());
    await tester.pump();
    expect(find.byType(MagicWidget), findsOneWidget);
    expect(find.text('MAGIC'), findsNWidgets(2));
    expect(find.text('Sparkles'), findsOneWidget);
    final Finder scrollable = find.byType(Scrollable).last;
    for (final String label in ['Wave', 'Timing', 'Loop']) {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: scrollable,
      );
      expect(find.text(label), findsOneWidget);
    }
    await tester.pump(const Duration(seconds: 5));
  });
}
