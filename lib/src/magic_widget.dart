import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:magic_widget/src/magic_effect_painter.dart';
import 'package:magic_widget/src/magic_widget_controller.dart';

/// Default sparkle palette, matching the colors of the original GIF.
const List<Color> kDefaultSparkleColors = <Color>[
  Color(0xFF7CFC52),
  Color(0xFF4DE3FF),
  Color(0xFFFFE94D),
  Color(0xFFFF5DDB),
];

/// Default glow color of the reveal front (warm yellow).
const Color kDefaultGlowColor = Color(0xCCFFC94D);

/// Direction of the reveal sweep.
enum MagicRevealDirection {
  leftToRight(Offset(1, 0)),
  rightToLeft(Offset(-1, 0)),
  topToBottom(Offset(0, 1)),
  bottomToTop(Offset(0, -1));

  const MagicRevealDirection(this.vector);

  /// Unit vector passed to the shader.
  final Offset vector;
}

/// Direction in which the sparkles slowly drift.
enum MagicDriftDirection {
  up(Offset(0, -1)),
  down(Offset(0, 1)),
  left(Offset(-1, 0)),
  right(Offset(1, 0));

  const MagicDriftDirection(this.vector);

  /// Unit vector passed to the shader.
  final Offset vector;
}

/// Reveals [child] with a magical left-to-right sweep: a warm glow travels
/// across the widget while twinkling multicolored sparkles pop behind it,
/// just like the classic "MAGIC" GIF.
///
/// The effect is rendered with a fragment shader and works on iOS, Android
/// and Web (CanvasKit / Skwasm renderers).
class MagicWidget extends StatefulWidget {
  const MagicWidget({
    required this.child,
    super.key,
    this.controller,
    this.duration = const Duration(milliseconds: 1800),
    this.sparkleDuration = const Duration(milliseconds: 2600),
    this.autoPlay = true,
    this.loop = false,
    this.curve = Curves.linear,
    this.sparkleColors = kDefaultSparkleColors,
    this.glowColor = kDefaultGlowColor,
    this.sparkleDensity = 0.35,
    this.sparkleSize = 1.0,
    this.twinkleSpeed = 1.0,
    this.sparkleDrift = 0.0,
    this.driftDirection = MagicDriftDirection.up,
    this.armStrength = 0.5,
    this.sparkleLayers = 2,
    this.glowWidth = 1.0,
    this.glowIntensity = 1.0,
    this.waveWobble = 1.0,
    this.edgeSoftness = 1.0,
    this.revealDirection = MagicRevealDirection.leftToRight,
    this.sparklePadding = EdgeInsets.zero,
    this.onCompleted,
  }) : assert(
          sparkleLayers >= 1 && sparkleLayers <= 3,
          'sparkleLayers must be between 1 and 3',
        );

  /// The widget revealed by the magic sweep.
  final Widget child;

  /// Optional controller to replay or reset the effect imperatively.
  final MagicWidgetController? controller;

  /// Duration of the left-to-right reveal sweep.
  final Duration duration;

  /// How long the sparkles keep twinkling after the reveal completes.
  final Duration sparkleDuration;

  /// Whether the reveal starts as soon as the widget is mounted.
  final bool autoPlay;

  /// Whether the animation restarts automatically once finished.
  final bool loop;

  /// Easing curve applied to the reveal progress.
  final Curve curve;

  /// Sparkle palette. The shader uses four colors; shorter lists are cycled.
  final List<Color> sparkleColors;

  /// Color of the glow band travelling with the reveal front. Its opacity
  /// controls the glow intensity.
  final Color glowColor;

  /// Probability that a sparkle spawns in a given area, from 0 to 1.
  final double sparkleDensity;

  /// Scale multiplier applied to every sparkle. 1 is the default size.
  final double sparkleSize;

  /// Multiplier of the twinkling speed. 1 is the default speed.
  final double twinkleSpeed;

  /// Strength of the sparkle drift movement. 0 keeps sparkles static.
  final double sparkleDrift;

  /// Direction in which the sparkles drift when [sparkleDrift] > 0.
  final MagicDriftDirection driftDirection;

  /// Star arms strength: 0 renders round halos, 1 pronounced star shapes.
  final double armStrength;

  /// Number of sparkle layers (1 to 3); more layers add depth.
  final int sparkleLayers;

  /// Width multiplier of the glow band. 1 is the default width.
  final double glowWidth;

  /// Brightness multiplier of the glow band. 1 is the default intensity.
  final double glowIntensity;

  /// Amplitude multiplier of the wavy reveal front. 0 is a straight edge.
  final double waveWobble;

  /// Softness multiplier of the reveal edge. Higher is blurrier.
  final double edgeSoftness;

  /// Direction of the reveal sweep.
  final MagicRevealDirection revealDirection;

  /// Extra space around [child] so sparkles can fly beyond its bounds.
  /// Note that this padding participates in layout.
  final EdgeInsetsGeometry sparklePadding;

  /// Called once the child is fully revealed (sparkles may still twinkle).
  final VoidCallback? onCompleted;

  @override
  State<MagicWidget> createState() => _MagicWidgetState();
}

enum _MagicPhase { hidden, playing, done }

class _MagicWidgetState extends State<MagicWidget>
    with SingleTickerProviderStateMixin {
  // When the package is consumed by an app the shader is bundled under the
  // `packages/` prefix; in the package's own tests it is bundled bare.
  static const List<String> _shaderAssetKeys = <String>[
    'packages/magic_widget/shaders/magic_sparkles.frag',
    'shaders/magic_sparkles.frag',
  ];
  static ui.FragmentProgram? _cachedProgram;
  late final Ticker _ticker;
  MagicEffectPainter? _painter;
  _MagicPhase _phase = _MagicPhase.hidden;
  double _elapsedSeconds = 0;
  bool _hasNotifiedCompletion = false;

  double get _revealSeconds =>
      widget.duration.inMilliseconds / Duration.millisecondsPerSecond;

  double get _totalSeconds =>
      _revealSeconds +
      widget.sparkleDuration.inMilliseconds / Duration.millisecondsPerSecond;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
    widget.controller?.addListener(_handleControllerCommand);
    _loadShader();
    if (widget.autoPlay) {
      _phase = _MagicPhase.playing;
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(MagicWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerCommand);
      widget.controller?.addListener(_handleControllerCommand);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerCommand);
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _loadShader() async {
    final ui.FragmentProgram? cached = _cachedProgram;
    if (cached != null) {
      _painter = MagicEffectPainter(cached.fragmentShader());
      return;
    }
    final ui.FragmentProgram? program = await _loadProgram();
    if (program == null || !mounted) {
      return;
    }
    setState(() => _painter = MagicEffectPainter(program.fragmentShader()));
  }

  static Future<ui.FragmentProgram?> _loadProgram() async {
    Object? lastError;
    StackTrace? lastStackTrace;
    for (final String assetKey in _shaderAssetKeys) {
      try {
        final ui.FragmentProgram program =
            await ui.FragmentProgram.fromAsset(assetKey);
        _cachedProgram = program;
        return program;
      } catch (e, stackTrace) {
        lastError = e;
        lastStackTrace = stackTrace;
      }
    }
    FlutterError.reportError(
      FlutterErrorDetails(exception: lastError!, stack: lastStackTrace),
    );
    return null;
  }

  void _handleControllerCommand() {
    final MagicCommand? command = widget.controller?.pendingCommand;
    if (command == null) {
      return;
    }
    widget.controller?.consumeCommand();
    switch (command) {
      case MagicCommand.play:
        _play();
      case MagicCommand.reset:
        _reset();
    }
  }

  void _play() {
    _ticker.stop();
    setState(() {
      _phase = _MagicPhase.playing;
      _elapsedSeconds = 0;
      _hasNotifiedCompletion = false;
    });
    _ticker.start();
  }

  void _reset() {
    _ticker.stop();
    setState(() {
      _phase = _MagicPhase.hidden;
      _elapsedSeconds = 0;
      _hasNotifiedCompletion = false;
    });
  }

  void _handleTick(Duration elapsed) {
    setState(() {
      _elapsedSeconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    });
    if (!_hasNotifiedCompletion && _elapsedSeconds >= _revealSeconds) {
      _hasNotifiedCompletion = true;
      widget.onCompleted?.call();
    }
    if (_elapsedSeconds >= _totalSeconds) {
      if (widget.loop) {
        _play();
        return;
      }
      _ticker.stop();
      setState(() => _phase = _MagicPhase.done);
    }
  }

  MagicEffectFrame _buildFrame() {
    final double linearProgress = _phase == _MagicPhase.hidden
        ? 0
        : (_elapsedSeconds / _revealSeconds).clamp(0.0, 1.0);
    final double fadeStart = _totalSeconds - 0.8;
    final double sparkleFade = _phase != _MagicPhase.playing
        ? 0
        : 1 -
            ((_elapsedSeconds - fadeStart) / (_totalSeconds - fadeStart))
                .clamp(0.0, 1.0);
    return MagicEffectFrame(
      progress: widget.curve.transform(linearProgress),
      time: _elapsedSeconds,
      sparkleFade: sparkleFade,
      sparkleDensity: widget.sparkleDensity.clamp(0.0, 1.0),
      sparkleSize: widget.sparkleSize,
      twinkleSpeed: widget.twinkleSpeed,
      driftAmount: widget.sparkleDrift,
      driftDirection: widget.driftDirection.vector,
      armStrength: widget.armStrength.clamp(0.0, 1.0),
      sparkleLayers: widget.sparkleLayers,
      glowWidth: widget.glowWidth,
      glowIntensity: widget.glowIntensity,
      waveWobble: widget.waveWobble,
      edgeSoftness: widget.edgeSoftness,
      revealDirection: widget.revealDirection.vector,
      glowColor: widget.glowColor,
      sparkleColors: _normalizedPalette(),
    );
  }

  List<Color> _normalizedPalette() => List<Color>.generate(
        4,
        (int i) => widget.sparkleColors[i % widget.sparkleColors.length],
      );

  @override
  Widget build(BuildContext context) {
    final Widget paddedChild = Padding(
      padding: widget.sparklePadding,
      child: widget.child,
    );
    if (_phase == _MagicPhase.done) {
      return paddedChild;
    }
    final MagicEffectPainter? painter = _painter;
    if (painter == null) {
      return Visibility(
        visible: false,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: paddedChild,
      );
    }
    return AnimatedSampler(
      (ui.Image image, Size size, Canvas canvas) =>
          painter.paint(image, size, canvas, _buildFrame()),
      child: paddedChild,
    );
  }
}
