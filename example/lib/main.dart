import 'package:flutter/material.dart';
import 'package:magic_widget/magic_widget.dart';

void main() => runApp(const MagicExampleApp());

const Map<String, Curve> kCurveChoices = <String, Curve>{
  'linear': Curves.linear,
  'easeInOut': Curves.easeInOut,
  'easeOutCubic': Curves.easeOutCubic,
  'easeInCubic': Curves.easeInCubic,
  'elasticOut': Curves.elasticOut,
};

const List<Color> kGlowChoices = <Color>[
  Color(0xCCFFC94D),
  Color(0xCCFFFFFF),
  Color(0xCCFF5DDB),
  Color(0xCC4DE3FF),
  Color(0xCC7CFC52),
  Color(0xCCB388FF),
];

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
  final MagicWidgetController _controller = MagicWidgetController();
  double _sparkleSize = 1;
  double _sparkleDensity = 0.35;
  double _twinkleSpeed = 1;
  double _sparkleDrift = 0;
  MagicDriftDirection _driftDirection = MagicDriftDirection.up;
  double _armStrength = 0.5;
  int _sparkleLayers = 2;
  Color _glowColor = kDefaultGlowColor;
  double _glowWidth = 1;
  double _glowIntensity = 1;
  double _waveWobble = 1;
  double _edgeSoftness = 1;
  MagicRevealDirection _revealDirection = MagicRevealDirection.leftToRight;
  double _durationMs = 1800;
  double _sparkleDurationMs = 2600;
  String _curveName = 'linear';
  bool _isLooping = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setLoop(bool value) {
    setState(() => _isLooping = value);
    if (value) {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MagicWidget playground'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Replay',
            onPressed: _controller.play,
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Reset (hide)',
            onPressed: _controller.reset,
            icon: const Icon(Icons.replay),
          ),
        ],
      ),
      body: Column(
        children: [
          _PreviewArea(
            controller: _controller,
            settingsBuilder: _buildMagicWidget,
          ),
          const Divider(height: 1),
          Expanded(child: _buildControls()),
        ],
      ),
    );
  }

  Widget _buildMagicWidget() {
    return MagicWidget(
      controller: _controller,
      duration: Duration(milliseconds: _durationMs.round()),
      sparkleDuration: Duration(milliseconds: _sparkleDurationMs.round()),
      loop: _isLooping,
      curve: kCurveChoices[_curveName]!,
      sparkleDensity: _sparkleDensity,
      sparkleSize: _sparkleSize,
      twinkleSpeed: _twinkleSpeed,
      sparkleDrift: _sparkleDrift,
      driftDirection: _driftDirection,
      armStrength: _armStrength,
      sparkleLayers: _sparkleLayers,
      glowColor: _glowColor,
      glowWidth: _glowWidth,
      glowIntensity: _glowIntensity,
      waveWobble: _waveWobble,
      edgeSoftness: _edgeSoftness,
      revealDirection: _revealDirection,
      sparklePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
      child: const _MagicText(),
    );
  }

  Widget _buildControls() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const _SectionHeader('Sparkles'),
        _SliderTile(
          label: 'Size',
          value: _sparkleSize,
          min: 0.3,
          max: 2.5,
          onChanged: (double v) => setState(() => _sparkleSize = v),
        ),
        _SliderTile(
          label: 'Density',
          value: _sparkleDensity,
          min: 0.05,
          max: 1,
          onChanged: (double v) => setState(() => _sparkleDensity = v),
        ),
        _SliderTile(
          label: 'Twinkle speed',
          value: _twinkleSpeed,
          min: 0.2,
          max: 3,
          onChanged: (double v) => setState(() => _twinkleSpeed = v),
        ),
        _SliderTile(
          label: 'Drift',
          value: _sparkleDrift,
          min: 0,
          max: 2,
          onChanged: (double v) => setState(() => _sparkleDrift = v),
        ),
        _DropdownTile<MagicDriftDirection>(
          label: 'Drift direction',
          value: _driftDirection,
          values: MagicDriftDirection.values,
          nameOf: (MagicDriftDirection d) => d.name,
          onChanged: (MagicDriftDirection d) =>
              setState(() => _driftDirection = d),
        ),
        _SliderTile(
          label: 'Star arms',
          value: _armStrength,
          min: 0,
          max: 1,
          onChanged: (double v) => setState(() => _armStrength = v),
        ),
        _DropdownTile<int>(
          label: 'Layers',
          value: _sparkleLayers,
          values: const [1, 2, 3],
          nameOf: (int v) => '$v',
          onChanged: (int v) => setState(() => _sparkleLayers = v),
        ),
        const _SectionHeader('Wave'),
        _ColorSwatchTile(
          label: 'Glow color',
          value: _glowColor,
          choices: kGlowChoices,
          onChanged: (Color c) => setState(() => _glowColor = c),
        ),
        _SliderTile(
          label: 'Glow width',
          value: _glowWidth,
          min: 0.2,
          max: 3,
          onChanged: (double v) => setState(() => _glowWidth = v),
        ),
        _SliderTile(
          label: 'Glow intensity',
          value: _glowIntensity,
          min: 0,
          max: 2.5,
          onChanged: (double v) => setState(() => _glowIntensity = v),
        ),
        _SliderTile(
          label: 'Wave wobble',
          value: _waveWobble,
          min: 0,
          max: 3,
          onChanged: (double v) => setState(() => _waveWobble = v),
        ),
        _SliderTile(
          label: 'Edge softness',
          value: _edgeSoftness,
          min: 0.2,
          max: 3,
          onChanged: (double v) => setState(() => _edgeSoftness = v),
        ),
        _DropdownTile<MagicRevealDirection>(
          label: 'Reveal direction',
          value: _revealDirection,
          values: MagicRevealDirection.values,
          nameOf: (MagicRevealDirection d) => d.name,
          onChanged: (MagicRevealDirection d) =>
              setState(() => _revealDirection = d),
        ),
        const _SectionHeader('Timing'),
        _SliderTile(
          label: 'Duration (ms)',
          value: _durationMs,
          min: 400,
          max: 4000,
          decimals: 0,
          onChanged: (double v) => setState(() => _durationMs = v),
        ),
        _SliderTile(
          label: 'Sparkle time (ms)',
          value: _sparkleDurationMs,
          min: 0,
          max: 5000,
          decimals: 0,
          onChanged: (double v) => setState(() => _sparkleDurationMs = v),
        ),
        _DropdownTile<String>(
          label: 'Curve',
          value: _curveName,
          values: kCurveChoices.keys.toList(),
          nameOf: (String name) => name,
          onChanged: (String name) => setState(() => _curveName = name),
        ),
        SwitchListTile(
          title: const Text('Loop'),
          contentPadding: EdgeInsets.zero,
          value: _isLooping,
          onChanged: _setLoop,
        ),
      ],
    );
  }
}

class _PreviewArea extends StatelessWidget {
  const _PreviewArea({
    required this.controller,
    required this.settingsBuilder,
  });

  final MagicWidgetController controller;
  final Widget Function() settingsBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Center(
        child: GestureDetector(
          onTap: controller.play,
          child: settingsBuilder(),
        ),
      ),
    );
  }
}

class _MagicText extends StatelessWidget {
  const _MagicText();

  static const TextStyle _baseStyle = TextStyle(
    fontSize: 64,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFFFFB433),
            ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.decimals = 2,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int decimals;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 140, child: Text(label)),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(
          width: 52,
          child: Text(
            value.toStringAsFixed(decimals),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  const _DropdownTile({
    required this.label,
    required this.value,
    required this.values,
    required this.nameOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) nameOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label)),
          Expanded(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: [
                for (final T item in values)
                  DropdownMenuItem<T>(value: item, child: Text(nameOf(item))),
              ],
              onChanged: (T? item) {
                if (item != null) {
                  onChanged(item);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatchTile extends StatelessWidget {
  const _ColorSwatchTile({
    required this.label,
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final String label;
  final Color value;
  final List<Color> choices;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label)),
          for (final Color color in choices)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(color),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: value == color ? Colors.white : Colors.white24,
                      width: value == color ? 2.5 : 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
