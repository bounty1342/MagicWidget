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
- Graceful degradation when the shader cannot load: the child is shown
  without any effect.
- Example playground app for iOS, Android and Web with live controls for every
  parameter.
