import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:magic_widget/src/magic_style.dart';

/// The animated inputs fed to the magic sparkles shader for one frame,
/// combined with the static [style].
@immutable
class MagicEffectFrame {
  /// Creates the inputs of one shader frame.
  const MagicEffectFrame({
    required this.progress,
    required this.time,
    required this.sparkleFade,
    required this.revealDirection,
    required this.style,
  });

  /// Reveal progress, from 0 (hidden) to 1 (fully revealed).
  final double progress;

  /// Elapsed time in seconds; drives the twinkling and the drift.
  final double time;

  /// Global opacity envelope of the sparkles, from 0 to 1.
  final double sparkleFade;

  /// Unit vector of the reveal sweep.
  final Offset revealDirection;

  /// Visual configuration of the effect.
  final MagicStyle style;
}

/// Applies the magic sparkles shader onto the captured child image.
class MagicEffectPainter {
  /// Creates a painter around a compiled [shader] instance.
  const MagicEffectPainter(this.shader);

  /// The fragment shader compiled from `shaders/magic_sparkles.frag`.
  final ui.FragmentShader shader;

  /// Paints one frame of the effect over the sampled [image] of the child.
  ///
  /// The uniforms are written in the exact order they are declared in the
  /// shader source.
  void paint(ui.Image image, Size size, Canvas canvas, MagicEffectFrame frame) {
    final MagicStyle style = frame.style;
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
    setFloat(style.sparkleDensity);
    setFloat(style.sparkleSize);
    setFloat(style.twinkleSpeed);
    setFloat(style.sparkleDrift);
    setVec2(style.driftDirection.vector);
    setFloat(style.armStrength);
    setFloat(style.sparkleLayers.toDouble());
    setFloat(style.glowWidth);
    setFloat(style.glowIntensity);
    setFloat(style.waveWobble);
    setFloat(style.edgeSoftness);
    setVec2(frame.revealDirection);
    setColor(style.glowColor);
    style.shaderPalette.forEach(setColor);
    shader.setImageSampler(0, image);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }
}
