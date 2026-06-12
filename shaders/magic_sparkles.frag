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
uniform float uLayers;
uniform float uGlowWidth;
uniform float uGlowIntensity;
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

// Coordinate along the sweep axis (0..1) for any reveal direction.
float axisCoord(vec2 uv) {
  return dot(uv - 0.5, uRevealDir) + 0.5;
}

// Coordinate perpendicular to the sweep axis (0..1).
float perpCoord(vec2 uv) {
  return dot(uv - 0.5, vec2(-uRevealDir.y, uRevealDir.x)) + 0.5;
}

// Signed coordinate of the reveal front, tilted and wobbly so the edge is
// organic instead of a straight line.
float sweepCoord(vec2 uv) {
  float p = perpCoord(uv);
  float wobble = (sin(p * 9.0 + uTime * 2.0) * 0.02 + sin(p * 23.0 + 1.7) * 0.012) * uWobbleAmp;
  return axisCoord(uv) + (p - 0.5) * kFrontTilt + wobble;
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

// One layer of procedural sparkles laid out on a jittered grid. Each cell may
// host a star that pops shortly after the sweep front passes it, then keeps
// twinkling. The whole layer drifts along uDriftDir over time.
vec3 sparkleLayer(vec2 fragPx, float cellSize, float front, float seed) {
  vec2 drift = uDriftDir * uTime * uDriftAmount * cellSize * (0.55 + 0.45 * fract(seed * 0.731));
  vec2 samplePx = fragPx - drift;
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
  vec2 centerUv = (center + drift) / uSize;
  float centerCoord = axisCoord(centerUv) + (perpCoord(centerUv) - 0.5) * kFrontTilt;
  float delay = hash12(cell + 5.0 + seed) * 0.30;
  float appear = smoothstep(centerCoord + delay, centerCoord + delay + 0.10, front);
  if (appear <= 0.0) {
    return vec3(0.0);
  }
  float twinkle = pow(0.5 + 0.5 * sin(uTime * speed + phase), 3.0);
  // Extra burst while the front is right on top of the sparkle.
  float burst = exp(-pow((centerCoord - front) / 0.08, 2.0)) * 1.5;
  vec2 d = samplePx - center;
  float radius = cellSize * (0.10 + 0.18 * jitter.y) * (0.55 + 0.45 * twinkle) * uSparkleSize;
  float core = exp(-dot(d, d) / (radius * radius));
  float arms = exp(-(abs(d.x) + abs(d.y) * 7.0) / radius)
      + exp(-(abs(d.y) + abs(d.x) * 7.0) / radius);
  float star = core + uArmStrength * arms;
  vec3 color = paletteColor(hash12(cell + 9.0 + seed));
  return color * star * appear * (0.35 + 0.65 * twinkle + burst);
}

void main() {
  vec2 fragPx = FlutterFragCoord().xy;
  vec2 uv = fragPx / uSize;
  float coord = sweepCoord(uv);
  float front = mix(kFrontStart, kFrontEnd, uProgress);
  float softness = max(uEdgeSoftness, 0.05);
  float mask = 1.0 - smoothstep(front - 0.06 * softness, front + 0.02 * softness, coord);
  vec4 color = texture(uChild, uv) * mask;
  // Warm glow band that travels with the front, gated out at both ends.
  float band = exp(-pow((coord - front) / (0.07 * max(uGlowWidth, 0.05)), 2.0));
  float glowGate = smoothstep(0.0, 0.03, uProgress) * (1.0 - smoothstep(0.85, 1.0, uProgress));
  float glow = clamp(band * glowGate * uGlowColor.a * uGlowIntensity, 0.0, 1.0);
  color.rgb += uGlowColor.rgb * glow;
  color.a = clamp(color.a + glow, 0.0, 1.0);
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
