import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Parameters fed to the magic sparkles fragment shader for one frame.
@immutable
class MagicEffectFrame {
  const MagicEffectFrame({
    required this.progress,
    required this.time,
    required this.sparkleFade,
    required this.sparkleDensity,
    required this.glowColor,
    required this.sparkleColors,
  }) : assert(sparkleColors.length == 4, 'Exactly 4 sparkle colors required');

  /// Reveal progress, from 0 (hidden) to 1 (fully revealed).
  final double progress;

  /// Elapsed time in seconds, drives the twinkling.
  final double time;

  /// Global opacity envelope of the sparkles, from 0 to 1.
  final double sparkleFade;

  /// Probability that a grid cell hosts a sparkle, from 0 to 1.
  final double sparkleDensity;

  /// Color of the glow band travelling with the reveal front.
  final Color glowColor;

  /// Palette of exactly four sparkle colors.
  final List<Color> sparkleColors;
}

/// Applies the magic sparkles shader onto the captured child image.
class MagicEffectPainter {
  const MagicEffectPainter(this.shader);

  /// The fragment shader compiled from `shaders/magic_sparkles.frag`.
  final ui.FragmentShader shader;

  /// Paints one frame of the effect over the sampled [image] of the child.
  void paint(ui.Image image, Size size, Canvas canvas, MagicEffectFrame frame) {
    var index = 0;
    void setFloat(double value) => shader.setFloat(index++, value);
    void setColor(Color color) {
      setFloat(color.r);
      setFloat(color.g);
      setFloat(color.b);
      setFloat(color.a);
    }

    setFloat(size.width);
    setFloat(size.height);
    setFloat(frame.progress);
    setFloat(frame.time);
    setFloat(frame.sparkleFade);
    setFloat(frame.sparkleDensity);
    setColor(frame.glowColor);
    frame.sparkleColors.forEach(setColor);
    shader.setImageSampler(0, image);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }
}
