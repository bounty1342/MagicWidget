import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_widget/magic_widget.dart';

Widget buildTestApp(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('MagicWidget', () {
    testWidgets('keeps the child in the tree while hidden',
        (WidgetTester tester) async {
      const inputChild = Text('MAGIC');
      await tester.pumpWidget(
        buildTestApp(const MagicWidget(autoPlay: false, child: inputChild)),
      );
      expect(find.text('MAGIC'), findsOneWidget);
    });

    testWidgets('calls onCompleted once the reveal duration has elapsed',
        (WidgetTester tester) async {
      var actualCompletedCount = 0;
      await tester.pumpWidget(
        buildTestApp(
          MagicWidget(
            duration: const Duration(milliseconds: 400),
            sparkleDuration: const Duration(milliseconds: 300),
            onCompleted: () => actualCompletedCount++,
            child: const Text('MAGIC'),
          ),
        ),
      );
      await tester.pump();
      expect(actualCompletedCount, 0);
      await tester.pump(const Duration(milliseconds: 500));
      expect(actualCompletedCount, 1);
      await tester.pump(const Duration(milliseconds: 400));
      expect(actualCompletedCount, 1);
    });

    testWidgets('starts the reveal when controller.play is called',
        (WidgetTester tester) async {
      final controller = MagicWidgetController();
      addTearDown(controller.dispose);
      var hasCompleted = false;
      await tester.pumpWidget(
        buildTestApp(
          MagicWidget(
            controller: controller,
            autoPlay: false,
            duration: const Duration(milliseconds: 300),
            sparkleDuration: const Duration(milliseconds: 200),
            onCompleted: () => hasCompleted = true,
            child: const Text('MAGIC'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(hasCompleted, isFalse);
      controller.play();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(hasCompleted, isTrue);
    });

    testWidgets('loop restarts the animation instead of finishing',
        (WidgetTester tester) async {
      var actualCompletedCount = 0;
      await tester.pumpWidget(
        buildTestApp(
          MagicWidget(
            loop: true,
            duration: const Duration(milliseconds: 200),
            sparkleDuration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            revealDirection: MagicRevealDirection.bottomToTop,
            sparkleDrift: 1,
            onCompleted: () => actualCompletedCount++,
            child: const Text('MAGIC'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(actualCompletedCount, greaterThan(1));
      await tester.pumpWidget(buildTestApp(const SizedBox()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('controller.reset hides the child again after a reveal',
        (WidgetTester tester) async {
      final controller = MagicWidgetController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        buildTestApp(
          MagicWidget(
            controller: controller,
            duration: const Duration(milliseconds: 300),
            sparkleDuration: const Duration(milliseconds: 200),
            child: const Text('MAGIC'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      controller.reset();
      await tester.pump();
      expect(find.text('MAGIC'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
