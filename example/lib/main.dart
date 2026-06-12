import 'package:flutter/foundation.dart';
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
  MagicStyle _style = const MagicStyle();
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

  void _updateStyle(MagicStyle style) => setState(() => _style = style);

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
          SizedBox(
            height: 240,
            child: Center(
              child: GestureDetector(
                onTap: _controller.play,
                child: MagicWidget(
                  controller: _controller,
                  style: _style,
                  duration: Duration(milliseconds: _durationMs.round()),
                  sparkleDuration:
                      Duration(milliseconds: _sparkleDurationMs.round()),
                  loop: _isLooping,
                  curve: kCurveChoices[_curveName]!,
                  revealDirection: _revealDirection,
                  sparklePadding:
                      const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
                  child: const _MagicText(),
                ),
              ),
            ),
          ),
          _StatusBanner(status: _controller.status),
          const Divider(height: 1),
          Expanded(
            child: _ControlPanel(
              style: _style,
              onStyleChanged: _updateStyle,
              revealDirection: _revealDirection,
              onRevealDirectionChanged: (MagicRevealDirection d) =>
                  setState(() => _revealDirection = d),
              durationMs: _durationMs,
              onDurationChanged: (double v) => setState(() => _durationMs = v),
              sparkleDurationMs: _sparkleDurationMs,
              onSparkleDurationChanged: (double v) =>
                  setState(() => _sparkleDurationMs = v),
              curveName: _curveName,
              onCurveChanged: (String name) =>
                  setState(() => _curveName = name),
              isLooping: _isLooping,
              onLoopChanged: _setLoop,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final ValueListenable<MagicStatus> status;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MagicStatus>(
      valueListenable: status,
      builder: (BuildContext context, MagicStatus value, _) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          'Status: ${value.name}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.style,
    required this.onStyleChanged,
    required this.revealDirection,
    required this.onRevealDirectionChanged,
    required this.durationMs,
    required this.onDurationChanged,
    required this.sparkleDurationMs,
    required this.onSparkleDurationChanged,
    required this.curveName,
    required this.onCurveChanged,
    required this.isLooping,
    required this.onLoopChanged,
  });

  final MagicStyle style;
  final ValueChanged<MagicStyle> onStyleChanged;
  final MagicRevealDirection revealDirection;
  final ValueChanged<MagicRevealDirection> onRevealDirectionChanged;
  final double durationMs;
  final ValueChanged<double> onDurationChanged;
  final double sparkleDurationMs;
  final ValueChanged<double> onSparkleDurationChanged;
  final String curveName;
  final ValueChanged<String> onCurveChanged;
  final bool isLooping;
  final ValueChanged<bool> onLoopChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const _SectionHeader('Sparkles'),
        _SliderTile(
          label: 'Size',
          value: style.sparkleSize,
          min: 0.3,
          max: 2.5,
          onChanged: (double v) =>
              onStyleChanged(style.copyWith(sparkleSize: v)),
        ),
        _SliderTile(
          label: 'Density',
          value: style.sparkleDensity,
          min: 0.05,
          max: 1,
          onChanged: (double v) =>
              onStyleChanged(style.copyWith(sparkleDensity: v)),
        ),
        _SliderTile(
          label: 'Twinkle speed',
          value: style.twinkleSpeed,
          min: 0.2,
          max: 3,
          onChanged: (double v) =>
              onStyleChanged(style.copyWith(twinkleSpeed: v)),
        ),
        _SliderTile(
          label: 'Drift',
          value: style.sparkleDrift,
          min: 0,
          max: 2,
          onChanged: (double v) =>
              onStyleChanged(style.copyWith(sparkleDrift: v)),
        ),
        _DropdownTile<MagicDriftDirection>(
          label: 'Drift direction',
          value: style.driftDirection,
          values: MagicDriftDirection.values,
          nameOf: (MagicDriftDirection d) => d.name,
          onChanged: (MagicDriftDirection d) =>
              onStyleChanged(style.copyWith(driftDirection: d)),
        ),
        _SliderTile(
          label: 'Star arms',
          value: style.armStrength,
          min: 0,
          max: 1,
          onChanged: (double v) =>
              onStyleChanged(style.copyWith(armStrength: v)),
        ),
        _DropdownTile<int>(
          label: 'Layers',
          value: style.sparkleLayers,
          values: const [1, 2, 3],
          nameOf: (int v) => '$v',
          onChanged: (int v) =>
              onStyleChanged(style.copyWith(sparkleLayers: v)),
        ),
        const _SectionHeader('Wave'),
        _ColorSwatchTile(
          label: 'Glow color',
          value: style.glowColor,
          choices: kGlowChoices,
          onChanged: (Color c) => onStyleChanged(style.copyWith(glowColor: c)),
        ),
        _SliderTile(
          label: 'Glow width',
          value: style.glowWidth,
          min: 0.2,
          max: 3,
          onChanged: (double v) => onStyleChanged(style.copyWith(glowWidth: v)),
        ),
        _SliderTile(
          label: 'Glow intensity',
          value: style.glowIntensity,
          min: 0,
          max: 2.5,
          onChanged: (double v) =>
              onStyleChanged(style.copyWith(glowIntensity: v)),
        ),
        _SliderTile(
          label: 'Wave wobble',
          value: style.waveWobble,
          min: 0,
          max: 3,
          onChanged: (double v) =>
              onStyleChanged(style.copyWith(waveWobble: v)),
        ),
        _SliderTile(
          label: 'Edge softness',
          value: style.edgeSoftness,
          min: 0.2,
          max: 3,
          onChanged: (double v) =>
              onStyleChanged(style.copyWith(edgeSoftness: v)),
        ),
        _DropdownTile<MagicRevealDirection>(
          label: 'Reveal direction',
          value: revealDirection,
          values: MagicRevealDirection.values,
          nameOf: (MagicRevealDirection d) => d.name,
          onChanged: onRevealDirectionChanged,
        ),
        const _SectionHeader('Timing'),
        _SliderTile(
          label: 'Duration (ms)',
          value: durationMs,
          min: 400,
          max: 4000,
          decimals: 0,
          onChanged: onDurationChanged,
        ),
        _SliderTile(
          label: 'Sparkle time (ms)',
          value: sparkleDurationMs,
          min: 0,
          max: 5000,
          decimals: 0,
          onChanged: onSparkleDurationChanged,
        ),
        _DropdownTile<String>(
          label: 'Curve',
          value: curveName,
          values: kCurveChoices.keys.toList(),
          nameOf: (String name) => name,
          onChanged: onCurveChanged,
        ),
        SwitchListTile(
          title: const Text('Loop'),
          contentPadding: EdgeInsets.zero,
          value: isLooping,
          onChanged: onLoopChanged,
        ),
      ],
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
