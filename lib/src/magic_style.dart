import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Default sparkle palette, matching the colors of the original GIF.
const List<Color> kDefaultSparkleColors = <Color>[
  Color(0xFF7CFC52),
  Color(0xFF4DE3FF),
  Color(0xFFFFE94D),
  Color(0xFFFF5DDB),
];

/// Default glow color of the reveal front (warm yellow).
const Color kDefaultGlowColor = Color(0xCCFFC94D);

/// Direction in which the sparkles slowly drift.
enum MagicDriftDirection {
  /// Sparkles float upwards.
  up(Offset(0, -1)),

  /// Sparkles fall downwards.
  down(Offset(0, 1)),

  /// Sparkles drift to the left.
  left(Offset(-1, 0)),

  /// Sparkles drift to the right.
  right(Offset(1, 0));

  const MagicDriftDirection(this.vector);

  /// Unit vector passed to the shader.
  final Offset vector;
}

/// The visual configuration of a `MagicWidget` effect.
///
/// All values have sensible defaults reproducing the original GIF. Create
/// variations with [copyWith]:
///
/// ```dart
/// const MagicStyle().copyWith(sparkleSize: 1.6, waveWobble: 2)
/// ```
@immutable
class MagicStyle with Diagnosticable {
  /// Creates a magic effect style.
  ///
  /// Multiplier values ([sparkleSize], [twinkleSpeed], [glowWidth],
  /// [glowIntensity], [waveWobble], [edgeSoftness]) default to 1, which is
  /// the reference look; [sparkleDrift] defaults to 0 (static sparkles).
  const MagicStyle({
    this.sparkleColors = kDefaultSparkleColors,
    this.sparkleDensity = 0.35,
    this.sparkleSize = 1.0,
    this.twinkleSpeed = 1.0,
    this.sparkleDrift = 0.0,
    this.driftDirection = MagicDriftDirection.up,
    this.armStrength = 0.5,
    this.sparkleLayers = 2,
    this.glowColor = kDefaultGlowColor,
    this.glowWidth = 1.0,
    this.glowIntensity = 1.0,
    this.waveWobble = 1.0,
    this.edgeSoftness = 1.0,
  })  : assert(
          sparkleDensity >= 0 && sparkleDensity <= 1,
          'sparkleDensity must be between 0 and 1',
        ),
        assert(sparkleSize > 0, 'sparkleSize must be greater than 0'),
        assert(twinkleSpeed > 0, 'twinkleSpeed must be greater than 0'),
        assert(sparkleDrift >= 0, 'sparkleDrift must not be negative'),
        assert(
          armStrength >= 0 && armStrength <= 1,
          'armStrength must be between 0 and 1',
        ),
        assert(
          sparkleLayers >= 1 && sparkleLayers <= 3,
          'sparkleLayers must be between 1 and 3',
        ),
        assert(glowWidth > 0, 'glowWidth must be greater than 0'),
        assert(glowIntensity >= 0, 'glowIntensity must not be negative'),
        assert(waveWobble >= 0, 'waveWobble must not be negative'),
        assert(edgeSoftness > 0, 'edgeSoftness must be greater than 0');

  /// Sparkle palette.
  ///
  /// The shader uses four colors; shorter lists are cycled and longer lists
  /// are truncated. Must not be empty.
  final List<Color> sparkleColors;

  /// Probability that a sparkle spawns in a given area, from 0 to 1.
  final double sparkleDensity;

  /// Scale multiplier applied to every sparkle.
  final double sparkleSize;

  /// Multiplier of the twinkling speed.
  final double twinkleSpeed;

  /// Strength of the sparkle drift movement.
  ///
  /// At 0 (the default) sparkles stay in place; higher values make them
  /// float along [driftDirection].
  final double sparkleDrift;

  /// Direction in which the sparkles drift when [sparkleDrift] > 0.
  final MagicDriftDirection driftDirection;

  /// Star arms strength.
  ///
  /// At 0 sparkles render as round halos; at 1 as pronounced four-pointed
  /// stars.
  final double armStrength;

  /// Number of sparkle layers, from 1 to 3. More layers add depth.
  final int sparkleLayers;

  /// Color of the glow band travelling with the reveal front.
  ///
  /// The opacity channel sets the base intensity of the glow, further
  /// multiplied by [glowIntensity].
  final Color glowColor;

  /// Width multiplier of the glow band.
  final double glowWidth;

  /// Brightness multiplier of the glow band.
  final double glowIntensity;

  /// Amplitude multiplier of the wavy reveal front. At 0 the edge is
  /// straight.
  final double waveWobble;

  /// Softness multiplier of the reveal edge. Higher values blur the edge.
  final double edgeSoftness;

  /// Creates a copy of this style with the given fields replaced.
  MagicStyle copyWith({
    List<Color>? sparkleColors,
    double? sparkleDensity,
    double? sparkleSize,
    double? twinkleSpeed,
    double? sparkleDrift,
    MagicDriftDirection? driftDirection,
    double? armStrength,
    int? sparkleLayers,
    Color? glowColor,
    double? glowWidth,
    double? glowIntensity,
    double? waveWobble,
    double? edgeSoftness,
  }) {
    return MagicStyle(
      sparkleColors: sparkleColors ?? this.sparkleColors,
      sparkleDensity: sparkleDensity ?? this.sparkleDensity,
      sparkleSize: sparkleSize ?? this.sparkleSize,
      twinkleSpeed: twinkleSpeed ?? this.twinkleSpeed,
      sparkleDrift: sparkleDrift ?? this.sparkleDrift,
      driftDirection: driftDirection ?? this.driftDirection,
      armStrength: armStrength ?? this.armStrength,
      sparkleLayers: sparkleLayers ?? this.sparkleLayers,
      glowColor: glowColor ?? this.glowColor,
      glowWidth: glowWidth ?? this.glowWidth,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      waveWobble: waveWobble ?? this.waveWobble,
      edgeSoftness: edgeSoftness ?? this.edgeSoftness,
    );
  }

  /// The four colors actually sent to the shader, cycling [sparkleColors]
  /// when it holds fewer than four entries.
  List<Color> get shaderPalette {
    assert(sparkleColors.isNotEmpty, 'sparkleColors must not be empty');
    final List<Color> source =
        sparkleColors.isEmpty ? kDefaultSparkleColors : sparkleColors;
    return List<Color>.generate(4, (int i) => source[i % source.length]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MagicStyle &&
        listEquals(other.sparkleColors, sparkleColors) &&
        other.sparkleDensity == sparkleDensity &&
        other.sparkleSize == sparkleSize &&
        other.twinkleSpeed == twinkleSpeed &&
        other.sparkleDrift == sparkleDrift &&
        other.driftDirection == driftDirection &&
        other.armStrength == armStrength &&
        other.sparkleLayers == sparkleLayers &&
        other.glowColor == glowColor &&
        other.glowWidth == glowWidth &&
        other.glowIntensity == glowIntensity &&
        other.waveWobble == waveWobble &&
        other.edgeSoftness == edgeSoftness;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(sparkleColors),
        sparkleDensity,
        sparkleSize,
        twinkleSpeed,
        sparkleDrift,
        driftDirection,
        armStrength,
        sparkleLayers,
        glowColor,
        glowWidth,
        glowIntensity,
        waveWobble,
        edgeSoftness,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Color>('sparkleColors', sparkleColors))
      ..add(
        DoubleProperty('sparkleDensity', sparkleDensity, defaultValue: 0.35),
      )
      ..add(DoubleProperty('sparkleSize', sparkleSize, defaultValue: 1.0))
      ..add(DoubleProperty('twinkleSpeed', twinkleSpeed, defaultValue: 1.0))
      ..add(DoubleProperty('sparkleDrift', sparkleDrift, defaultValue: 0.0))
      ..add(
        EnumProperty<MagicDriftDirection>(
          'driftDirection',
          driftDirection,
          defaultValue: MagicDriftDirection.up,
        ),
      )
      ..add(DoubleProperty('armStrength', armStrength, defaultValue: 0.5))
      ..add(IntProperty('sparkleLayers', sparkleLayers, defaultValue: 2))
      ..add(
        ColorProperty('glowColor', glowColor, defaultValue: kDefaultGlowColor),
      )
      ..add(DoubleProperty('glowWidth', glowWidth, defaultValue: 1.0))
      ..add(DoubleProperty('glowIntensity', glowIntensity, defaultValue: 1.0))
      ..add(DoubleProperty('waveWobble', waveWobble, defaultValue: 1.0))
      ..add(DoubleProperty('edgeSoftness', edgeSoftness, defaultValue: 1.0));
  }
}
