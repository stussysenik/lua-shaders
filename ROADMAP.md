# Roadmap

## Vision

A complete, staff-level computer graphics education delivered through
progressive shader koans — from "what is a pixel" to raymarched 3D scenes.
Every koan doubles as an Instagram-ready visual showcase.

---

## Phase 1: Foundation (current)

**Status: complete**

The engine, presentation pipeline, and first 2 chapters.

- [x] LOVE engine with learn/demo/present modes
- [x] Hot-reload shader editing workflow
- [x] Instagram story export (GIF + MP4)
- [x] Chapter 1: Coordinates & UV Space (4 koans)
- [x] Chapter 2: Color Mixing & Palettes (4 koans)
- [x] Pedagogical framework (8 teaching patterns)

## Phase 2: Core Shader Techniques

**Status: next up**

The meat of shader programming. These chapters teach the patterns that
produce 90% of visual effects you see on Shadertoy.

### Chapter 3: Signed Distance Fields (5 koans)
*Geometry is a scalar function. Distance = shape.*

- [ ] Circle SDF — `length(p) - radius`
- [ ] Box SDF — axis-aligned distance
- [ ] Combining shapes — union, intersection, subtraction
- [ ] Smooth blending — `smin()` for organic joins
- [ ] Rings and outlines — `abs()` on distance

### Chapter 4: Waves & Motion (4 koans)
*Time enters the shader. Everything oscillates.*

- [ ] Sine wave animation — time as input
- [ ] Wave interference — overlapping frequencies
- [ ] Polar coordinates — atan2 and radial patterns
- [ ] Spiral patterns — polar + time

### Chapter 5: Noise & Randomness (4 koans)
*Nature isn't smooth. Fake organic with math.*

- [ ] Hash functions — pseudo-random from coordinates
- [ ] Value noise — smooth random terrain
- [ ] Perlin noise — gradient-based smoothness
- [ ] FBM — fractal brownian motion, layered octaves

## Phase 3: Advanced Techniques

**Status: planned**

Where it gets mind-blowing. Fractals and raymarching are the
"staff-level" capstone — they synthesize everything from phases 1-2.

### Chapter 6: Fractals & Repetition (4 koans)
*Infinite complexity from simple rules.*

- [ ] Tiling with fract() — infinite grids
- [ ] Mandelbrot set — complex iteration
- [ ] Julia sets — parameter space exploration
- [ ] Domain repetition — infinite 3D worlds

### Chapter 7: Raymarching & 3D (5 koans)
*The final boss. 3D scenes from a pixel shader.*

- [ ] Ray setup — camera, direction, marching loop
- [ ] Sphere marching — step along the ray
- [ ] Lighting & normals — gradient estimation, Phong
- [ ] 3D SDF scenes — compose a full scene
- [ ] Capstone — combine EVERYTHING into one shader

## Phase 4: Polish & Distribution

**Status: future**

- [ ] Custom monospace font (JetBrains Mono) for code overlays
- [ ] Batch export: `love . --present all`
- [ ] Web viewer (GLSL -> WebGL transpilation)
- [ ] YouTube Shorts theme variant
- [ ] TikTok vertical theme variant
- [ ] README with embedded GIF previews of each koan
- [ ] Open-source release with CONTRIBUTING.md
- [ ] Landing page for the project

## Phase 5: Beyond Shaders

**Status: dream**

- [ ] Compute shaders (LOVE 12.x)
- [ ] Reaction-diffusion systems
- [ ] Fluid simulation
- [ ] Particle systems via shader feedback
- [ ] Audio-reactive shaders (FFT input)
- [ ] Integration with bboy-analytics — render motion capture data as shader visualizations

---

## Connections

```
bboy-analytics                    lua-shaders
  3D joint data ──────────────> shader visualization
  musicality scoring ─────────> audio-reactive effects
  motion capture pipeline ────> real-time GPU rendering
```

Both projects share the philosophy: **make complex math tangible through
interactive, visual exploration.** bboy-analytics captures the data;
lua-shaders renders it beautiful.
