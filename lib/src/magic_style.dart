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

/// The rendering style of every sparkle.
enum MagicSparkleShape {
  /// Soft glowing four-pointed stars, the original look.
  glow,

  /// Crisp pixel-art stars, a pixel perfect replica of the GIF sparkle:
  /// hard square pixels forming a rounded diamond that explodes outwards
  /// from its center in discrete steps, with a white-hot center pixel.
  pixel,
}

/// How sparkles pick their color from [MagicStyle.sparkleColors].
enum MagicSparkleColorMode {
  /// Each sparkle picks one random color of the palette, the original look.
  palette,

  /// Sparkle colors blend smoothly through the palette along the horizontal
  /// position, forming a gradient across the widget like the GIF.
  gradient,
}

/// The dressing drawn on the reveal wave as it travels across the child.
enum MagicWaveStyle {
  /// A warm glowing band, the original look.
  glow,

  /// An anamorphic lens flare: a white-hot core with long streaks, a halo
  /// ring and palette-tinted ghost circles, like the flare of the GIF.
  lensFlare,

  /// No dressing at all: the wave reveals the child transparently.
  transparent,

  /// No wave at all: the child stays fully visible and the sparkles appear
  /// over the whole widget from the start.
  none,
}

/// Direction in which the sparkles slowly drift.
enum MagicDriftDirection {
  /// Sparkles float upwards.
  up(Offset(0, -1)),

  /// Sparkles fall downwards.
  down(Offset(0, 1)),

  /// Sparkles drift to the left.
  left(Offset(-1, 0)),

  /// Sparkles drift to the right.
  right(Offset(1, 0)),

  /// Sparkles explode outwards from the center, faster when further out.
  centerOut(Offset.zero);

  const MagicDriftDirection(this.vector);

  /// Unit vector passed to the shader; [Offset.zero] selects the radial
  /// center-to-border drift.
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
    this.sparkleShape = MagicSparkleShape.glow,
    this.sparkleColorMode = MagicSparkleColorMode.palette,
    this.sparkleLayers = 2,
    this.glowColor = kDefaultGlowColor,
    this.glowWidth = 1.0,
    this.glowIntensity = 1.0,
    this.waveStyle = MagicWaveStyle.glow,
    this.flareStreak = 1.0,
    this.flareRing = 1.0,
    this.flareGhosts = 3,
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
        assert(flareStreak > 0, 'flareStreak must be greater than 0'),
        assert(flareRing >= 0, 'flareRing must not be negative'),
        assert(
          flareGhosts >= 0 && flareGhosts <= 3,
          'flareGhosts must be between 0 and 3',
        ),
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
  /// stars. Has no effect with [MagicSparkleShape.pixel].
  final double armStrength;

  /// Rendering style of the sparkles: soft [MagicSparkleShape.glow] stars or
  /// crisp pixel-art [MagicSparkleShape.pixel] stars matching the GIF.
  final MagicSparkleShape sparkleShape;

  /// How sparkles pick their color: a random [MagicSparkleColorMode.palette]
  /// entry per sparkle, or a smooth [MagicSparkleColorMode.gradient] through
  /// the palette along the horizontal position.
  final MagicSparkleColorMode sparkleColorMode;

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

  /// Dressing of the reveal wave: a [MagicWaveStyle.glow] band, a
  /// [MagicWaveStyle.lensFlare], [MagicWaveStyle.transparent] to hide the
  /// dressing, or [MagicWaveStyle.none] to disable the wave entirely.
  /// [glowColor], [glowWidth] and [glowIntensity] also drive the flare.
  final MagicWaveStyle waveStyle;

  /// Length multiplier of the main lens flare streak.
  ///
  /// Only used with [MagicWaveStyle.lensFlare].
  final double flareStreak;

  /// Strength multiplier of the lens flare halo ring, 0 to hide it.
  ///
  /// Only used with [MagicWaveStyle.lensFlare].
  final double flareRing;

  /// Number of lens flare ghost circles, from 0 to 3.
  ///
  /// Only used with [MagicWaveStyle.lensFlare].
  final int flareGhosts;

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
    MagicSparkleShape? sparkleShape,
    MagicSparkleColorMode? sparkleColorMode,
    int? sparkleLayers,
    Color? glowColor,
    double? glowWidth,
    double? glowIntensity,
    MagicWaveStyle? waveStyle,
    double? flareStreak,
    double? flareRing,
    int? flareGhosts,
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
      sparkleShape: sparkleShape ?? this.sparkleShape,
      sparkleColorMode: sparkleColorMode ?? this.sparkleColorMode,
      sparkleLayers: sparkleLayers ?? this.sparkleLayers,
      glowColor: glowColor ?? this.glowColor,
      glowWidth: glowWidth ?? this.glowWidth,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      waveStyle: waveStyle ?? this.waveStyle,
      flareStreak: flareStreak ?? this.flareStreak,
      flareRing: flareRing ?? this.flareRing,
      flareGhosts: flareGhosts ?? this.flareGhosts,
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
        other.sparkleShape == sparkleShape &&
        other.sparkleColorMode == sparkleColorMode &&
        other.sparkleLayers == sparkleLayers &&
        other.glowColor == glowColor &&
        other.glowWidth == glowWidth &&
        other.glowIntensity == glowIntensity &&
        other.waveStyle == waveStyle &&
        other.flareStreak == flareStreak &&
        other.flareRing == flareRing &&
        other.flareGhosts == flareGhosts &&
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
        sparkleShape,
        sparkleColorMode,
        sparkleLayers,
        glowColor,
        glowWidth,
        glowIntensity,
        waveStyle,
        flareStreak,
        flareRing,
        flareGhosts,
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
      ..add(
        EnumProperty<MagicSparkleShape>(
          'sparkleShape',
          sparkleShape,
          defaultValue: MagicSparkleShape.glow,
        ),
      )
      ..add(
        EnumProperty<MagicSparkleColorMode>(
          'sparkleColorMode',
          sparkleColorMode,
          defaultValue: MagicSparkleColorMode.palette,
        ),
      )
      ..add(IntProperty('sparkleLayers', sparkleLayers, defaultValue: 2))
      ..add(
        ColorProperty('glowColor', glowColor, defaultValue: kDefaultGlowColor),
      )
      ..add(DoubleProperty('glowWidth', glowWidth, defaultValue: 1.0))
      ..add(DoubleProperty('glowIntensity', glowIntensity, defaultValue: 1.0))
      ..add(
        EnumProperty<MagicWaveStyle>(
          'waveStyle',
          waveStyle,
          defaultValue: MagicWaveStyle.glow,
        ),
      )
      ..add(DoubleProperty('flareStreak', flareStreak, defaultValue: 1.0))
      ..add(DoubleProperty('flareRing', flareRing, defaultValue: 1.0))
      ..add(IntProperty('flareGhosts', flareGhosts, defaultValue: 3))
      ..add(DoubleProperty('waveWobble', waveWobble, defaultValue: 1.0))
      ..add(DoubleProperty('edgeSoftness', edgeSoftness, defaultValue: 1.0));
  }
}
