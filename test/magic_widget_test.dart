import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_widget/magic_widget.dart';

Widget buildTestApp(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('MagicStyle', () {
    test('copyWith replaces only the given fields', () {
      const inputStyle = MagicStyle();
      final actualStyle = inputStyle.copyWith(sparkleSize: 2, waveWobble: 0);
      expect(actualStyle.sparkleSize, 2);
      expect(actualStyle.waveWobble, 0);
      expect(actualStyle.sparkleDensity, inputStyle.sparkleDensity);
      expect(actualStyle.glowColor, inputStyle.glowColor);
    });

    test('supports value equality', () {
      const inputStyle = MagicStyle(sparkleSize: 1.5);
      expect(inputStyle, const MagicStyle(sparkleSize: 1.5));
      expect(inputStyle.hashCode, const MagicStyle(sparkleSize: 1.5).hashCode);
      expect(inputStyle, isNot(const MagicStyle()));
    });

    test('shaderPalette cycles short palettes to four colors', () {
      const inputStyle = MagicStyle(
        sparkleColors: [Color(0xFF000001), Color(0xFF000002)],
      );
      expect(inputStyle.shaderPalette, const [
        Color(0xFF000001),
        Color(0xFF000002),
        Color(0xFF000001),
        Color(0xFF000002),
      ]);
    });
  });

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

    testWidgets('controller drives play, reset and status',
        (WidgetTester tester) async {
      final controller = MagicWidgetController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        buildTestApp(
          MagicWidget(
            controller: controller,
            autoPlay: false,
            duration: const Duration(milliseconds: 300),
            sparkleDuration: const Duration(milliseconds: 200),
            child: const Text('MAGIC'),
          ),
        ),
      );
      expect(controller.isAttached, isTrue);
      expect(controller.status.value, MagicStatus.hidden);
      controller.play();
      await tester.pump();
      expect(controller.status.value, MagicStatus.revealing);
      await tester.pump(const Duration(milliseconds: 600));
      expect(controller.status.value, MagicStatus.completed);
      controller.reset();
      await tester.pump();
      expect(controller.status.value, MagicStatus.hidden);
      expect(find.text('MAGIC'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
            style: const MagicStyle(sparkleDrift: 1),
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
  });
}
