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
    required this.sparkleSize,
    required this.twinkleSpeed,
    required this.driftAmount,
    required this.driftDirection,
    required this.armStrength,
    required this.sparkleLayers,
    required this.glowWidth,
    required this.glowIntensity,
    required this.waveWobble,
    required this.edgeSoftness,
    required this.revealDirection,
    required this.glowColor,
    required this.sparkleColors,
  }) : assert(sparkleColors.length == 4, 'Exactly 4 sparkle colors required');

  /// Reveal progress, from 0 (hidden) to 1 (fully revealed).
  final double progress;

  /// Elapsed time in seconds, drives the twinkling and the drift.
  final double time;

  /// Global opacity envelope of the sparkles, from 0 to 1.
  final double sparkleFade;

  /// Probability that a grid cell hosts a sparkle, from 0 to 1.
  final double sparkleDensity;

  /// Scale multiplier applied to every sparkle.
  final double sparkleSize;

  /// Multiplier of the twinkling speed.
  final double twinkleSpeed;

  /// Strength of the sparkle drift; 0 keeps sparkles static.
  final double driftAmount;

  /// Unit vector of the drift movement.
  final Offset driftDirection;

  /// Star arms strength: 0 is a round halo, 1 a pronounced star.
  final double armStrength;

  /// Number of sparkle layers, from 1 to 3.
  final int sparkleLayers;

  /// Width multiplier of the glow band travelling with the front.
  final double glowWidth;

  /// Brightness multiplier of the glow band.
  final double glowIntensity;

  /// Amplitude multiplier of the wavy reveal front.
  final double waveWobble;

  /// Softness multiplier of the reveal edge.
  final double edgeSoftness;

  /// Unit vector of the reveal sweep.
  final Offset revealDirection;

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
    void setVec2(Offset value) {
      setFloat(value.dx);
      setFloat(value.dy);
    }

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
    setFloat(frame.sparkleSize);
    setFloat(frame.twinkleSpeed);
    setFloat(frame.driftAmount);
    setVec2(frame.driftDirection);
    setFloat(frame.armStrength);
    setFloat(frame.sparkleLayers.toDouble());
    setFloat(frame.glowWidth);
    setFloat(frame.glowIntensity);
    setFloat(frame.waveWobble);
    setFloat(frame.edgeSoftness);
    setVec2(frame.revealDirection);
    setColor(frame.glowColor);
    frame.sparkleColors.forEach(setColor);
    shader.setImageSampler(0, image);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }
}
