import 'package:flutter/material.dart';
import 'package:magic_widget/magic_widget.dart';

void main() => runApp(const MagicExampleApp());

class MagicExampleApp extends StatelessWidget {
  const MagicExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MagicWidget Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFFFA726),
        scaffoldBackgroundColor: const Color(0xFF14101F),
      ),
      home: const _DemoPage(),
    );
  }
}

class _DemoPage extends StatefulWidget {
  const _DemoPage();

  @override
  State<_DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<_DemoPage> {
  final MagicWidgetController _textController = MagicWidgetController();
  final MagicWidgetController _cardController = MagicWidgetController();

  @override
  void dispose() {
    _textController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MagicWidget'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _textController.play,
                child: MagicWidget(
                  controller: _textController,
                  sparklePadding: const EdgeInsets.all(56),
                  child: const _MagicText(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _textController.play,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Replay'),
              ),
              const SizedBox(height: 48),
              Text(
                'Works with any widget',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              MagicWidget(
                controller: _cardController,
                autoPlay: false,
                duration: const Duration(milliseconds: 1200),
                sparklePadding: const EdgeInsets.all(32),
                child: const _DemoCard(),
              ),
              OutlinedButton.icon(
                onPressed: _cardController.play,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Reveal the card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MagicText extends StatelessWidget {
  const _MagicText();

  static const TextStyle _baseStyle = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w900,
    letterSpacing: 4,
    height: 1,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          'MAGIC',
          style: _baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 10
              ..color = const Color(0xFF6D3410),
          ),
        ),
        Text(
          'MAGIC',
          style: _baseStyle.copyWith(color: const Color(0xFFFFB433)),
        ),
      ],
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2A2140),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets, size: 40, color: Color(0xFFFFB433)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Magic unicorn',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Any widget can be revealed',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
