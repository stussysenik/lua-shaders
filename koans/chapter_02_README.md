# Chapter 2: Color Mixing & Palettes

## The Problem
Shaders output vec4 RGBA colors, but how do you go from a scalar value
(like distance or position) to a beautiful color? Hard-coded palettes
are ugly and inflexible.

## The Pattern
**Color Mapping**: scalar input -> color output via mathematical functions.
mix() for linear, smoothstep() for soft edges, cosine for palettes,
HSV for intuitive control.

## Prior Knowledge
Chapter 1 (UV coordinates provide the scalar inputs to color formulas).

## Koans
1. **Colors Are Numbers** -- RGB as vec3, mix() for linear blending
2. **The Smooth Knife** -- smoothstep() for anti-aliased soft edges
3. **Inigo's Rainbow** -- one cosine formula for infinite palettes
4. **The Hue Wheel** -- HSV color-space transformation

## GPU Scale
A cosine palette evaluation (koan 3) is ~10 floating-point operations
per pixel. At 2M pixels x 60fps = 1.2 billion FLOPs/second. A modern
GPU does 10+ TFLOPS. Your palette uses 0.01% of the GPU's capacity.
