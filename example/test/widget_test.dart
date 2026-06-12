import 'package:flutter_test/flutter_test.dart';
import 'package:magic_widget/magic_widget.dart';
import 'package:magic_widget_example/main.dart';

void main() {
  testWidgets('demo page shows the MAGIC reveal and the card demo',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MagicExampleApp());
    await tester.pump();
    expect(find.byType(MagicWidget), findsNWidgets(2));
    expect(find.text('MAGIC'), findsNWidgets(2));
    expect(find.text('Replay'), findsOneWidget);
    expect(find.text('Reveal the card'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
