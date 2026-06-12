# MagicWidget

An over-engineered way to say *ta-da*: MagicWidget reveals any Flutter widget
behind a magical sweep — a warm glowing front (or a full anamorphic lens
flare) travels across the child while twinkling multicolored sparkles pop,
drift and explode around it, faithfully recreating the classic
["MAGIC" GIF](https://media2.giphy.com/media/v1.Y2lkPWZjZGU1NDk1eDU1ZXNpMm5tNThmcDU1Z3B1OXAzcmRrYmdlZjF3azhieWd1bXZnOCZlcD12MV9naWZzX3NlYXJjaCZjdD1n/9r75ILTJtiDACKOKoY/giphy.gif)
down to its pixel-art stars and horizontal color gradient.

Yes, it has five reveal directions, four wave styles, two sparkle shapes,
three flare controls and a radial explosion mode. No, you don't need all of
them. You'll use them anyway.

The whole effect is rendered with a single fragment shader, so it is fast and
works on **iOS**, **Android** and **Web** (CanvasKit / Skwasm renderers).

## Installation

```sh
flutter pub add magic_widget
```

Or add it to your `pubspec.yaml` manually:

```yaml
dependencies:
  magic_widget: ^0.1.0
```

Requires Flutter `>=3.27.0` and Dart `^3.6.0`.

## Features

- Reveal **any widget**, not just text: the child is captured as a texture and
  fed to the shader.
- Organic wavy reveal front with a warm traveling glow.
- Procedural twinkling sparkles in a configurable 4-color palette.
- Two sparkle shapes: soft glowing stars, or pixel perfect pixel-art stars
  that explode from their center like the GIF, plus an optional horizontal
  gradient color mode.
- Four wave styles: the warm glow band, a tunable anamorphic lens flare, a
  transparent wave, or no wave at all (sparkles only).
- Five reveal directions: the 4 linear sweeps plus a center-to-border
  explosion.
- Immutable `MagicStyle` with `copyWith` for the full visual configuration.
- `autoPlay`, `loop`, or imperative control with `MagicWidgetController`
  (`play()` / `reset()`) and an observable `ValueListenable<MagicStatus>`.
- `onCompleted` callback when the child is fully revealed.
- Graceful degradation: if the shader fails to load, the child is shown
  without any effect and the error is reported to `FlutterError`.

## Usage

```dart
import 'package:magic_widget/magic_widget.dart';

MagicWidget(
  sparklePadding: const EdgeInsets.all(56),
  child: const Text(
    'MAGIC',
    style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900),
  ),
)
```

Customize the look with a `MagicStyle`:

```dart
MagicWidget(
  style: const MagicStyle(
    sparkleSize: 1.6,
    sparkleDrift: 0.8,
    driftDirection: MagicDriftDirection.up,
    sparkleShape: MagicSparkleShape.pixel,
    sparkleColorMode: MagicSparkleColorMode.gradient,
    glowColor: Color(0xCCB388FF),
  ),
  revealDirection: MagicRevealDirection.bottomToTop,
  curve: Curves.easeInOut,
  child: const MyCard(),
)
```

Imperative control and status observation:

```dart
final controller = MagicWidgetController();

MagicWidget(
  controller: controller,
  autoPlay: false,
  onCompleted: () => debugPrint('Ta-da!'),
  child: const MyCard(),
)

// Later:
controller.play();  // start or replay the reveal
controller.reset(); // hide the child again

// React to lifecycle changes (hidden, revealing, completed):
ValueListenableBuilder<MagicStatus>(
  valueListenable: controller.status,
  builder: (context, status, _) => Text(status.name),
)

// Dispose with the owning State:
controller.dispose();
```

### `MagicWidget` parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `child` | required | Widget revealed by the sweep. |
| `style` | `MagicStyle()` | Visual configuration (see below). |
| `controller` | `null` | Replay / reset the effect imperatively. |
| `duration` | 1800 ms | Duration of the reveal sweep. |
| `sparkleDuration` | 2600 ms | How long sparkles keep twinkling afterwards. |
| `autoPlay` | `true` | Start as soon as the widget is mounted. |
| `loop` | `false` | Restart the animation automatically once finished. |
| `curve` | `Curves.linear` | Easing curve applied to the reveal progress. |
| `revealDirection` | `leftToRight` | Sweep direction (`MagicRevealDirection`): 4 linear directions plus `centerOut`, an explosion from the center to the borders. |
| `sparklePadding` | `EdgeInsets.zero` | Extra space so sparkles fly beyond the child. |
| `onCompleted` | `null` | Called when the child is fully revealed. |

### `MagicStyle` properties

| Property | Default | Description |
| --- | --- | --- |
| `sparkleColors` | green, cyan, yellow, magenta | Sparkle palette (4 colors, shorter lists are cycled). |
| `sparkleDensity` | `0.35` | Probability of a sparkle per grid cell (0 to 1). |
| `sparkleSize` | `1.0` | Scale multiplier of every sparkle. |
| `twinkleSpeed` | `1.0` | Multiplier of the twinkling speed. |
| `sparkleDrift` | `0.0` | Strength of the sparkle drift movement (0 = static). |
| `driftDirection` | `up` | Drift direction (`MagicDriftDirection`): up, down, left, right, or `centerOut` for a radial explosion. |
| `sparkleShape` | `glow` | Sparkle rendering (`MagicSparkleShape`): soft `glow` stars or pixel perfect `pixel` art stars exploding from their center like the GIF. |
| `sparkleColorMode` | `palette` | Color picking (`MagicSparkleColorMode`): random `palette` entry per sparkle, or a smooth horizontal `gradient` through the palette. |
| `armStrength` | `0.5` | Star arms strength: 0 = round halo, 1 = pronounced star (`glow` shape only). |
| `sparkleLayers` | `2` | Number of sparkle layers (1 to 3) for depth. |
| `glowColor` | warm yellow | Color and base intensity (alpha) of the front glow. |
| `glowWidth` | `1.0` | Width multiplier of the glow band. |
| `glowIntensity` | `1.0` | Brightness multiplier of the glow band. |
| `waveStyle` | `glow` | Wave dressing (`MagicWaveStyle`): `glow` band, anamorphic `lensFlare`, `transparent` (reveal without dressing), or `none` (no wave, sparkles cover the whole widget from the start). |
| `flareStreak` | `1.0` | Length multiplier of the lens flare streak (`lensFlare` only). |
| `flareRing` | `1.0` | Strength of the lens flare halo ring, 0 hides it (`lensFlare` only). |
| `flareGhosts` | `3` | Number of lens flare ghost circles, 0 to 3 (`lensFlare` only). |
| `waveWobble` | `1.0` | Amplitude of the wavy reveal front (0 = straight edge). |
| `edgeSoftness` | `1.0` | Softness of the reveal edge (higher = blurrier). |

## Example

Try the playground live in your browser:
**[bounty1342.github.io/MagicWidget](https://bounty1342.github.io/MagicWidget/)**
(deployed automatically from `main` by GitHub Actions).

A full playground app (iOS / Android / Web) lives in [`example/`](example/),
with live sliders and selectors for every parameter above, plus a card demo
where you pick an image from your device and type your own text:

```sh
cd example
flutter run -d chrome   # or any iOS / Android device
```

## Platform notes

- Fragment shaders require the CanvasKit or Skwasm web renderer, which is the
  default since Flutter 3.22. The legacy HTML renderer is not supported.
- The effect uses `AnimatedSampler` from
  [flutter_shaders](https://pub.dev/packages/flutter_shaders), so platform
  views inside `child` cannot be captured.

## License

[MIT](LICENSE)
