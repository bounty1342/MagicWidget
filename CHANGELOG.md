# Changelog

## 0.1.0

- Initial release.
- `MagicWidget`: shader-powered magic sweep reveal with traveling glow and
  twinkling multicolored sparkles, for any child widget.
- `MagicWidgetController` with `play()`, `reset()` and an observable
  `ValueListenable<MagicStatus>` status.
- Immutable `MagicStyle` (with `copyWith`) grouping the full visual
  customization: sparkle size, density, twinkle speed, drift movement and
  direction, star shape, layer count, glow color/width/intensity, wave wobble
  and edge softness. Reveal direction, easing curve and loop mode live on the
  widget.
- Two sparkle shapes (`MagicSparkleShape`): soft glowing stars or pixel
  perfect pixel-art stars exploding from their center.
- Two color modes (`MagicSparkleColorMode`): random palette pick or a smooth
  horizontal gradient through the palette.
- Four wave styles (`MagicWaveStyle`): glow band, tunable anamorphic lens
  flare (streak, ring, ghosts), transparent reveal, or no wave at all with
  sparkles over the whole widget.
- Radial mode: `MagicRevealDirection.centerOut` and
  `MagicDriftDirection.centerOut` for center-to-border explosion sweeps and
  drifts.
- Graceful degradation when the shader cannot load: the child is shown
  without any effect.
- Example playground app for iOS, Android and Web with live controls for every
  parameter.
