#version 460 core

// Magic sweep reveal effect, inspired by the classic SNL "MAGIC" GIF:
// the child is revealed behind a warm glowing front, surrounded by
// twinkling multicolored sparkles.

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uProgress;
uniform float uTime;
uniform float uSparkleFade;
uniform float uDensity;
uniform float uSparkleSize;
uniform float uTwinkleSpeed;
uniform float uDriftAmount;
uniform vec2 uDriftDir;
uniform float uArmStrength;
uniform float uSparkleShape;
uniform float uColorMode;
uniform float uLayers;
uniform float uGlowWidth;
uniform float uGlowIntensity;
uniform float uWaveStyle;
uniform float uFlareStreak;
uniform float uFlareRing;
uniform float uFlareGhosts;
uniform float uWobbleAmp;
uniform float uEdgeSoftness;
uniform vec2 uRevealDir;
uniform vec4 uGlowColor;
uniform vec4 uColor0;
uniform vec4 uColor1;
uniform vec4 uColor2;
uniform vec4 uColor3;
uniform sampler2D uChild;

out vec4 fragColor;

const float kFrontTilt = 0.12;
const float kFrontStart = -0.20;
const float kFrontEnd = 1.30;

float hash12(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.xx + p3.yz) * p3.zy);
}

// A zero reveal vector selects the radial (center to border) sweep.
float isRadial() {
  return step(dot(uRevealDir, uRevealDir), 0.5);
}

// Coordinate along the sweep axis (0..1) for any reveal direction. In the
// radial mode it is the normalized distance from the center (1 at corners).
float axisCoord(vec2 uv) {
  if (isRadial() > 0.5) {
    return length(uv - 0.5) * 1.4142;
  }
  return dot(uv - 0.5, uRevealDir) + 0.5;
}

// Coordinate perpendicular to the sweep axis (0..1). In the radial mode it
// is the angle around the center, in turns.
float perpCoord(vec2 uv) {
  if (isRadial() > 0.5) {
    vec2 d = uv - 0.5;
    return atan(d.y, d.x) * 0.15915 + 0.5;
  }
  return dot(uv - 0.5, vec2(-uRevealDir.y, uRevealDir.x)) + 0.5;
}

// The front tilt only applies to linear sweeps; a radial front stays round.
float frontTilt() {
  return kFrontTilt * (1.0 - isRadial());
}

// Signed coordinate of the reveal front, tilted and wobbly so the edge is
// organic instead of a straight line.
float sweepCoord(vec2 uv) {
  float p = perpCoord(uv);
  float wobble;
  if (isRadial() > 0.5) {
    // Whole-cycle angular frequencies so the wobble has no seam.
    float a = p * 6.2831;
    wobble = (sin(a * 3.0 + uTime * 2.0) * 0.02 + sin(a * 7.0 + 1.7) * 0.012) * uWobbleAmp;
  } else {
    wobble = (sin(p * 9.0 + uTime * 2.0) * 0.02 + sin(p * 23.0 + 1.7) * 0.012) * uWobbleAmp;
  }
  return axisCoord(uv) + (p - 0.5) * frontTilt() + wobble;
}

vec3 paletteColor(float selector) {
  float pick = floor(selector * 4.0);
  if (pick < 1.0) {
    return uColor0.rgb;
  }
  if (pick < 2.0) {
    return uColor1.rgb;
  }
  if (pick < 3.0) {
    return uColor2.rgb;
  }
  return uColor3.rgb;
}

// Smooth 4-stop gradient through the palette, used when uColorMode == 1.
vec3 gradientColor(float t) {
  float x = clamp(t, 0.0, 1.0) * 3.0;
  if (x < 1.0) {
    return mix(uColor0.rgb, uColor1.rgb, x);
  }
  if (x < 2.0) {
    return mix(uColor1.rgb, uColor2.rgb, x - 1.0);
  }
  return mix(uColor2.rgb, uColor3.rgb, x - 2.0);
}

// Pixel-art sparkle, a faithful blocky version of the GIF star: hard square
// pixels forming a rounded diamond that explodes outwards from its center in
// discrete steps as the level rises, with axis tips and a white-hot center.
// Returns (brightness, isCenter).
vec2 pixelStar(vec2 d, float pixelSize, float level) {
  vec2 cellPx = floor(d / pixelSize + 0.5);
  float ax = abs(cellPx.x);
  float ay = abs(cellPx.y);
  float dist = ax + ay;
  float radius = floor(level * 2.999);
  float armLength = radius + step(0.35, level);
  if (ax < 0.5 && ay < 0.5) {
    return vec2(1.0, 1.0);
  }
  if (dist < radius + 0.5) {
    return vec2(0.9, 0.0);
  }
  if ((ax < 0.5 || ay < 0.5) && dist < armLength + 0.5) {
    return vec2(0.75, 0.0);
  }
  return vec2(0.0, 0.0);
}

// Anamorphic lens flare traveling with the reveal front: a white-hot core,
// a long streak along the sweep axis, a cross streak, a faint halo ring and
// a few palette-tinted ghost circles mirrored through the widget center.
vec3 lensFlare(vec2 uv, float front) {
  // In the radial sweep the flare sits at the center with horizontal
  // streaks; ghosts then drift with the front so the explosion still moves.
  vec2 streakDir = isRadial() > 0.5 ? vec2(1.0, 0.0) : uRevealDir;
  vec2 centerUv = vec2(0.5) + (front - 0.5) * uRevealDir;
  float minDim = min(uSize.x, uSize.y);
  vec2 n = (uv - centerUv) * uSize / (minDim * 0.6 * max(uGlowWidth, 0.05));
  float streakScale = max(uFlareStreak, 0.05);
  float along = dot(n, streakDir) / streakScale;
  float perp = dot(n, vec2(-streakDir.y, streakDir.x));
  float r = length(n);
  float core = exp(-r * r * 9.0) * 1.4;
  float streakMain = exp(-abs(perp) * 22.0 - abs(along) * 1.6) * 0.9;
  float streakCross = exp(-abs(along * streakScale) * 22.0 - abs(perp) * 4.0 / streakScale) * 0.45;
  float ring = exp(-pow((r - 0.55) * 9.0, 2.0)) * 0.18 * uFlareRing;
  vec3 flare = uGlowColor.rgb * (core + streakMain + streakCross)
      + vec3(1.0) * core * 0.5
      + mix(uGlowColor.rgb, vec3(1.0), 0.4) * ring;
  vec2 toCenter = vec2(0.5) - centerUv + streakDir * (front - 0.5) * isRadial();
  for (int i = 1; i <= 3; ++i) {
    vec2 ghostUv = centerUv + toCenter * (float(i) * 0.7);
    vec2 g = (uv - ghostUv) * uSize / (minDim * 0.5);
    float ghost = exp(-dot(g, g) * (18.0 + float(i) * 14.0)) * (0.24 - float(i) * 0.05);
    ghost *= step(float(i), uFlareGhosts + 0.5);
    vec3 ghostColor = i == 1 ? uColor0.rgb : (i == 2 ? uColor1.rgb : uColor2.rgb);
    flare += ghostColor * ghost;
  }
  return flare;
}

// One layer of procedural sparkles laid out on a jittered grid. Each cell may
// host a star that pops shortly after the sweep front passes it, then keeps
// twinkling. The whole layer drifts along uDriftDir over time; a zero drift
// vector makes the layer explode radially from the center instead.
vec3 sparkleLayer(vec2 fragPx, float cellSize, float front, float seed) {
  float layerRate = 0.55 + 0.45 * fract(seed * 0.731);
  float radialDrift = step(dot(uDriftDir, uDriftDir), 0.5);
  vec2 widgetCenter = uSize * 0.5;
  vec2 samplePx;
  vec2 drift = vec2(0.0);
  float scale = 1.0;
  if (radialDrift > 0.5) {
    // Expanding field: sparkles fly away from the center, faster when
    // further out, like an explosion.
    scale = 1.0 + uTime * uDriftAmount * 0.35 * layerRate;
    samplePx = widgetCenter + (fragPx - widgetCenter) / scale;
  } else {
    drift = uDriftDir * uTime * uDriftAmount * cellSize * layerRate;
    samplePx = fragPx - drift;
  }
  vec2 cell = floor(samplePx / cellSize);
  float exists = step(1.0 - uDensity, hash12(cell * 1.71 + seed + 13.0));
  if (exists < 0.5) {
    return vec3(0.0);
  }
  vec2 jitter = hash22(cell + seed);
  float phase = jitter.x * 6.2831;
  float speed = (5.0 + jitter.y * 8.0) * uTwinkleSpeed;
  vec2 wiggle = vec2(sin(uTime * 1.7 + phase), cos(uTime * 2.3 + phase)) * cellSize * 0.06 * uDriftAmount;
  vec2 center = (cell + 0.15 + 0.7 * jitter) * cellSize + wiggle;
  vec2 screenCenter = radialDrift > 0.5
      ? widgetCenter + (center - widgetCenter) * scale
      : center + drift;
  vec2 centerUv = screenCenter / uSize;
  float centerCoord = axisCoord(centerUv) + (perpCoord(centerUv) - 0.5) * frontTilt();
  float delay = hash12(cell + 5.0 + seed) * 0.30;
  float appear = smoothstep(centerCoord + delay, centerCoord + delay + 0.10, front);
  float twinkle = pow(0.5 + 0.5 * sin(uTime * speed + phase), 3.0);
  // Extra burst while the front is right on top of the sparkle.
  float burst = exp(-pow((centerCoord - front) / 0.08, 2.0)) * 1.5;
  if (uWaveStyle > 2.5) {
    // No wave: sparkles cover the whole widget from the start.
    appear = 1.0;
    burst = 0.0;
  }
  if (appear <= 0.0) {
    return vec3(0.0);
  }
  vec2 d = samplePx - center;
  float baseRadius = cellSize * (0.10 + 0.18 * jitter.y) * uSparkleSize;
  // Gradient mode blends the palette horizontally, like the GIF.
  vec3 color = uColorMode > 0.5
      ? gradientColor(centerUv.x)
      : paletteColor(hash12(cell + 9.0 + seed));
  if (uSparkleShape > 0.5) {
    // Pixel-art star: explodes from the center when the front passes, then
    // settles into discrete twinkling steps. Without a wave the twinkle
    // alone drives the full size range.
    float pixelSize = max(baseRadius * 0.6, 1.0);
    float twinkleWeight = uWaveStyle > 2.5 ? 0.9 : 0.55;
    float level = clamp(burst * 0.9 + twinkle * twinkleWeight, 0.0, 1.0);
    vec2 lit = pixelStar(d, pixelSize, level);
    vec3 shade = mix(color, vec3(1.0), lit.y * 0.85);
    return shade * lit.x * appear * (0.75 + 0.25 * twinkle + burst * 0.5);
  }
  float radius = baseRadius * (0.55 + 0.45 * twinkle);
  float core = exp(-dot(d, d) / (radius * radius));
  float arms = exp(-(abs(d.x) + abs(d.y) * 7.0) / radius)
      + exp(-(abs(d.y) + abs(d.x) * 7.0) / radius);
  float star = core + uArmStrength * arms;
  return color * star * appear * (0.35 + 0.65 * twinkle + burst);
}

void main() {
  vec2 fragPx = FlutterFragCoord().xy;
  vec2 uv = fragPx / uSize;
  float coord = sweepCoord(uv);
  float front = mix(kFrontStart, kFrontEnd, uProgress);
  float softness = max(uEdgeSoftness, 0.05);
  float mask = 1.0 - smoothstep(front - 0.06 * softness, front + 0.02 * softness, coord);
  if (uWaveStyle > 2.5) {
    // No wave at all: the child stays fully visible, only sparkles play.
    mask = 1.0;
  }
  vec4 color = texture(uChild, uv) * mask;
  // Wave dressing, gated out at both ends of the sweep.
  float glowGate = smoothstep(0.0, 0.03, uProgress) * (1.0 - smoothstep(0.85, 1.0, uProgress));
  if (uWaveStyle < 0.5) {
    // Warm glow band travelling with the front.
    float band = exp(-pow((coord - front) / (0.07 * max(uGlowWidth, 0.05)), 2.0));
    float glow = clamp(band * glowGate * uGlowColor.a * uGlowIntensity, 0.0, 1.0);
    color.rgb += uGlowColor.rgb * glow;
    color.a = clamp(color.a + glow, 0.0, 1.0);
  } else if (uWaveStyle < 1.5) {
    // Lens flare travelling with the front.
    vec3 flare = lensFlare(uv, front) * glowGate * uGlowColor.a * uGlowIntensity;
    color.rgb += flare;
    color.a = clamp(color.a + max(flare.r, max(flare.g, flare.b)), 0.0, 1.0);
  }
  // uWaveStyle == 2: transparent, the front reveals without any dressing.
  // uWaveStyle == 3: none, no reveal and no dressing (handled above).
  // Up to three sparkle layers at different scales for depth.
  float minDim = min(uSize.x, uSize.y);
  vec3 sparkles = sparkleLayer(fragPx, max(minDim / 12.0, 9.0), front, 0.0);
  if (uLayers > 1.5) {
    sparkles += sparkleLayer(fragPx, max(minDim / 20.0, 6.0), front, 4.7);
  }
  if (uLayers > 2.5) {
    sparkles += sparkleLayer(fragPx, max(minDim / 28.0, 4.0), front, 9.3);
  }
  sparkles *= uSparkleFade;
  color.rgb += sparkles;
  color.a = clamp(color.a + max(sparkles.r, max(sparkles.g, sparkles.b)), 0.0, 1.0);
  fragColor = color;
}
