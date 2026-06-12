# MagicWidget

Reveal any Flutter widget with a magical left-to-right sweep: a warm glowing
front travels across the child while twinkling multicolored sparkles pop and
shimmer behind it — just like the classic
["MAGIC" GIF](https://media2.giphy.com/media/v1.Y2lkPWZjZGU1NDk1eDU1ZXNpMm5tNThmcDU1Z3B1OXAzcmRrYmdlZjF3azhieWd1bXZnOCZlcD12MV9naWZzX3NlYXJjaCZjdD1n/9r75ILTJtiDACKOKoY/giphy.gif).

The whole effect is rendered with a single fragment shader, so it is fast and
works on **iOS**, **Android** and **Web** (CanvasKit / Skwasm renderers).

## Features

- Reveal **any widget**, not just text: the child is captured as a texture and
  fed to the shader.
- Organic wavy reveal front with a warm traveling glow.
- Procedural twinkling sparkles in a configurable 4-color palette.
- `autoPlay` or imperative control with `MagicWidgetController`
  (`play()` / `reset()`).
- `onCompleted` callback when the child is fully revealed.

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

Imperative control:

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
```

### Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `child` | required | Widget revealed by the sweep. |
| `controller` | `null` | Replay / reset the effect imperatively. |
| `duration` | 1800 ms | Duration of the reveal sweep. |
| `sparkleDuration` | 2600 ms | How long sparkles keep twinkling afterwards. |
| `autoPlay` | `true` | Start as soon as the widget is mounted. |
| `loop` | `false` | Restart the animation automatically once finished. |
| `curve` | `Curves.linear` | Easing curve applied to the reveal progress. |
| `revealDirection` | `leftToRight` | Sweep direction (`MagicRevealDirection`: 4 directions). |
| `sparkleColors` | green, cyan, yellow, magenta | Sparkle palette (4 colors, shorter lists are cycled). |
| `sparkleDensity` | `0.35` | Probability of a sparkle per grid cell (0 to 1). |
| `sparkleSize` | `1.0` | Scale multiplier of every sparkle. |
| `twinkleSpeed` | `1.0` | Multiplier of the twinkling speed. |
| `sparkleDrift` | `0.0` | Strength of the sparkle drift movement (0 = static). |
| `driftDirection` | `up` | Drift direction (`MagicDriftDirection`: up, down, left, right). |
| `armStrength` | `0.5` | Star arms strength: 0 = round halo, 1 = pronounced star. |
| `sparkleLayers` | `2` | Number of sparkle layers (1 to 3) for depth. |
| `glowColor` | warm yellow | Color and base intensity (alpha) of the front glow. |
| `glowWidth` | `1.0` | Width multiplier of the glow band. |
| `glowIntensity` | `1.0` | Brightness multiplier of the glow band. |
| `waveWobble` | `1.0` | Amplitude of the wavy reveal front (0 = straight edge). |
| `edgeSoftness` | `1.0` | Softness of the reveal edge (higher = blurrier). |
| `sparklePadding` | `EdgeInsets.zero` | Extra space so sparkles fly beyond the child. |
| `onCompleted` | `null` | Called when the child is fully revealed. |

## Example

A full playground app (iOS / Android / Web) lives in [`example/`](example/),
with live sliders and selectors for every parameter above:

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
