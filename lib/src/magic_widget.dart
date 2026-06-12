import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:magic_widget/src/magic_effect_painter.dart';
import 'package:magic_widget/src/magic_style.dart';

/// Direction of the reveal sweep.
enum MagicRevealDirection {
  /// The child is revealed from the left edge to the right edge.
  leftToRight(Offset(1, 0)),

  /// The child is revealed from the right edge to the left edge.
  rightToLeft(Offset(-1, 0)),

  /// The child is revealed from the top edge to the bottom edge.
  topToBottom(Offset(0, 1)),

  /// The child is revealed from the bottom edge to the top edge.
  bottomToTop(Offset(0, -1));

  const MagicRevealDirection(this.vector);

  /// Unit vector passed to the shader.
  final Offset vector;
}

/// The lifecycle of a [MagicWidget] animation.
enum MagicStatus {
  /// The child is hidden and the animation has not started.
  hidden,

  /// The reveal sweep or the trailing sparkles are running.
  revealing,

  /// The child is fully revealed and the animation has finished.
  completed,
}

/// Starts and rewinds a [MagicWidget] from outside its subtree.
///
/// A controller may be attached to at most one [MagicWidget] at a time.
/// Listen to [status] to react to animation lifecycle changes:
///
/// ```dart
/// final controller = MagicWidgetController();
///
/// MagicWidget(
///   controller: controller,
///   autoPlay: false,
///   child: const Text('MAGIC'),
/// );
///
/// // Elsewhere:
/// controller.play();
/// ```
///
/// Call [dispose] when the controller is no longer needed.
class MagicWidgetController {
  _MagicWidgetState? _state;
  final ValueNotifier<MagicStatus> _status =
      ValueNotifier<MagicStatus>(MagicStatus.hidden);

  /// The current animation status of the attached widget.
  ValueListenable<MagicStatus> get status => _status;

  /// Whether this controller is attached to a [MagicWidget].
  bool get isAttached => _state != null;

  /// Starts or restarts the magic reveal.
  void play() {
    assert(isAttached, 'MagicWidgetController is not attached to a widget');
    _state?._play();
  }

  /// Hides the child and rewinds the effect.
  void reset() {
    assert(isAttached, 'MagicWidgetController is not attached to a widget');
    _state?._reset();
  }

  /// Releases the resources held by this controller.
  void dispose() => _status.dispose();

  void _attach(_MagicWidgetState state) {
    assert(
      _state == null,
      'MagicWidgetController is already attached to a widget',
    );
    _state = state;
  }

  void _detach(_MagicWidgetState state) {
    if (_state == state) {
      _state = null;
    }
  }
}

/// Reveals [child] with a magical sweep: a warm glow travels across the
/// widget while twinkling multicolored sparkles pop behind it, just like
/// the classic "MAGIC" GIF.
///
/// The effect is rendered with a fragment shader and works on iOS, Android
/// and Web (CanvasKit / Skwasm renderers). The look is configured with a
/// [MagicStyle]; timing and playback are configured on the widget itself:
///
/// ```dart
/// MagicWidget(
///   style: const MagicStyle(sparkleDrift: 0.8),
///   sparklePadding: const EdgeInsets.all(56),
///   child: const Text('MAGIC'),
/// )
/// ```
///
/// If the shader fails to load, the error is reported to [FlutterError] and
/// the child is shown without any effect.
class MagicWidget extends StatefulWidget {
  /// Creates a magic reveal around [child].
  const MagicWidget({
    super.key,
    this.controller,
    this.style = const MagicStyle(),
    this.duration = const Duration(milliseconds: 1800),
    this.sparkleDuration = const Duration(milliseconds: 2600),
    this.autoPlay = true,
    this.loop = false,
    this.curve = Curves.linear,
    this.revealDirection = MagicRevealDirection.leftToRight,
    this.sparklePadding = EdgeInsets.zero,
    this.onCompleted,
    required this.child,
  });

  /// Optional controller to replay or reset the effect imperatively.
  final MagicWidgetController? controller;

  /// Visual configuration of the sparkles and the glow wave.
  final MagicStyle style;

  /// Duration of the reveal sweep.
  final Duration duration;

  /// How long the sparkles keep twinkling after the reveal completes.
  final Duration sparkleDuration;

  /// Whether the reveal starts as soon as the widget is mounted.
  final bool autoPlay;

  /// Whether the animation restarts automatically once finished.
  final bool loop;

  /// Easing curve applied to the reveal progress.
  final Curve curve;

  /// Direction of the reveal sweep.
  final MagicRevealDirection revealDirection;

  /// Extra space around [child] so sparkles can fly beyond its bounds.
  ///
  /// This padding participates in layout.
  final EdgeInsetsGeometry sparklePadding;

  /// Called every time the child becomes fully revealed.
  ///
  /// Sparkles may keep twinkling after this callback fires.
  final VoidCallback? onCompleted;

  /// The widget revealed by the magic sweep.
  final Widget child;

  @override
  State<MagicWidget> createState() => _MagicWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<MagicStyle>('style', style))
      ..add(DiagnosticsProperty<Duration>('duration', duration))
      ..add(DiagnosticsProperty<Duration>('sparkleDuration', sparkleDuration))
      ..add(FlagProperty('autoPlay', value: autoPlay, ifFalse: 'manual start'))
      ..add(FlagProperty('loop', value: loop, ifTrue: 'looping'))
      ..add(
        EnumProperty<MagicRevealDirection>(
          'revealDirection',
          revealDirection,
          defaultValue: MagicRevealDirection.leftToRight,
        ),
      );
  }
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
  bool _hasShaderFailed = false;
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
    widget.controller?._attach(this);
    _loadShader();
    if (widget.autoPlay) {
      _phase = _MagicPhase.playing;
      _setStatus(MagicStatus.revealing);
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(MagicWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _ticker.dispose();
    super.dispose();
  }

  void _setStatus(MagicStatus status) {
    final MagicWidgetController? controller = widget.controller;
    if (controller != null && controller._status.value != status) {
      controller._status.value = status;
    }
  }

  Future<void> _loadShader() async {
    final ui.FragmentProgram? cached = _cachedProgram;
    if (cached != null) {
      _painter = MagicEffectPainter(cached.fragmentShader());
      return;
    }
    final ui.FragmentProgram? program = await _loadProgram();
    if (!mounted) {
      return;
    }
    setState(() {
      if (program == null) {
        _hasShaderFailed = true;
      } else {
        _painter = MagicEffectPainter(program.fragmentShader());
      }
    });
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
      FlutterErrorDetails(
        exception: lastError!,
        stack: lastStackTrace,
        library: 'magic_widget',
        context: ErrorDescription('while loading the magic sparkles shader'),
      ),
    );
    return null;
  }

  void _play() {
    _ticker.stop();
    setState(() {
      _phase = _MagicPhase.playing;
      _elapsedSeconds = 0;
      _hasNotifiedCompletion = false;
    });
    _setStatus(MagicStatus.revealing);
    _ticker.start();
  }

  void _reset() {
    _ticker.stop();
    setState(() {
      _phase = _MagicPhase.hidden;
      _elapsedSeconds = 0;
      _hasNotifiedCompletion = false;
    });
    _setStatus(MagicStatus.hidden);
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
      _setStatus(MagicStatus.completed);
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
      revealDirection: widget.revealDirection.vector,
      style: widget.style,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget paddedChild = Padding(
      padding: widget.sparklePadding,
      child: widget.child,
    );
    if (_phase == _MagicPhase.done || _hasShaderFailed) {
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
