# lua-shaders

**Karpathy-style koans for GPU shader programming.**

Learn graphics math from first principles — UV coordinates to raymarching —
through progressive fill-in-the-blank GLSL puzzles. Each koan produces a
visual that exports as an Instagram-ready animated story.

```
    koans/01_coordinates/shader.glsl

    vec4 effect(...) {
        vec2 uv = ???;              <-- you fill this in
        return vec4(uv.x, uv.y, 0.0, 1.0);
    }
```

> Visual companion to [bboy-analytics](https://github.com/stussysenik/bboy-analytics) —
> same philosophy of making complex math tangible through interactive exploration.
> Where bboy-analytics quantifies dance through 3D joint physics, lua-shaders teaches
> the GPU math that renders those visuals.

---

## How It Works

```
You edit shader.glsl          LOVE hot-reloads           GPU renders
 ┌─────────────────┐    ┌──────────────────┐    ┌──────────────────┐
 │ vec2 uv = ???;  │ -> │ detect change    │ -> │ 124M pixels/sec  │
 │                 │    │ recompile GLSL   │    │ instant feedback  │
 │ (your editor)   │    │ show result      │    │ (visual proof)   │
 └─────────────────┘    └──────────────────┘    └──────────────────┘
```

Each koan is a folder with 4 files:

| File | Purpose |
|------|---------|
| `koan.lua` | Lesson text, hints, concepts — the teaching |
| `shader.glsl` | The puzzle — GLSL with `???` blanks to fill |
| `solution.glsl` | The answer — powers demo mode and IG export |
| `present.lua` | Timeline config for Instagram story recording |

## Quick Start

```bash
# Install
brew install love          # LOVE 11.5 (Lua game framework)
brew install ffmpeg         # For GIF/MP4 export

# Learn — solve koans by editing shader files
love .

# Demo — browse all solutions with live visuals
love . --demo

# Export — record a koan as Instagram story (1080x1920)
love . --present 01_coordinates
```

## Curriculum

The curriculum follows **chained mental models** — each concept builds on the last.
Every lesson includes X-ray vision ("what you see vs. what's really happening"),
forward references ("this unlocks..."), and minimum-viable-math hints.

### Chapter 1: Coordinates & UV Space
*Pattern: Space Transformation — change the space, not the drawing*

| # | Koan | Core Idea | Operations |
|---|------|-----------|------------|
| 01 | The Canvas is a Map | Normalize pixels to 0-1 | 1 division |
| 02 | The Stretch Problem | Correct aspect ratio | 1 multiply |
| 03 | Moving the Origin | Center for radial math | 1 subtraction |
| 04 | Zooming In | Infinite tiling via fract() | 2 ops |

### Chapter 2: Color Mixing & Palettes
*Pattern: Color Mapping — scalar input, color output*

| # | Koan | Core Idea | Operations |
|---|------|-----------|------------|
| 05 | Colors Are Numbers | RGB as vec3, mix() | 1 function |
| 06 | The Smooth Knife | smoothstep() for soft edges | 1 function |
| 07 | Inigo's Rainbow | Cosine palettes (infinite color) | 1 formula |
| 08 | The Hue Wheel | HSV color-space transformation | angle + ramp |

### Chapters 3-7 (Planned)

| Ch | Topic | Pattern | Key Concepts |
|----|-------|---------|-------------|
| 3 | Signed Distance Fields | Geometry as scalar functions | circle, box, union, smooth blend |
| 4 | Waves & Motion | Time as input | sin/cos, polar coords, spirals |
| 5 | Noise & Randomness | Organic from math | hash, Perlin, FBM |
| 6 | Fractals & Repetition | Infinite from finite | Mandelbrot, Julia, domain rep |
| 7 | Raymarching & 3D | The final synthesis | ray setup, marching, lighting |

## Presentation Pipeline

Every koan exports as an Instagram-ready animated story:

```
solution.glsl + present.lua
  -> Presenter (1080x1920 canvas + text overlays)
  -> Recorder (PNG frames at 30fps)
  -> Exporter (ffmpeg -> GIF + MP4)
  -> export/01_coordinates.{gif,mp4}
```

## Architecture

```
lua-shaders/
  conf.lua              LOVE config (540x960 dev window, 9:16)
  main.lua              Entry point + mode router
  lib/
    shader_loader.lua   Read .glsl, compile, detect blanks, uniforms
    koan_runner.lua     Learn mode: hot-reload, hints, navigation
    presenter.lua       9:16 canvas, timeline overlays, transitions
    recorder.lua        Fixed-timestep PNG frame capture
    exporter.lua        ffmpeg GIF + MP4 pipeline
  koans/
    index.lua           Curriculum ordering
    01_coordinates/     4 files per koan (see above)
    ...
  themes/
    instagram.lua       1080x1920 layout, fonts, overlay styles
```

## Pedagogical Design

Based on patterns from senior-level teaching (Karpathy, The Senior Dev):

1. **Chained Mental Models** — every concept references prior koans
2. **X-Ray Vision** — "what you see vs. what's really happening"
3. **Essential State** — minimum viable math per effect
4. **Systems Thinking** — forward refs ("this unlocks chapter 3")
5. **Pattern Over Implementation** — teach the pattern, not the syntax
6. **Progressive Tiers** — Foundation -> Motion -> Organic -> 3D
7. **Problem-First** — lead with the visual problem, not the solution
8. **GPU Scale** — "your 5-line function runs 124M times per second"

See [docs/CURRICULUM_DESIGN.md](docs/CURRICULUM_DESIGN.md) for the full guide.

## Tech Stack

| Tool | Version | Purpose |
|------|---------|---------|
| LOVE | 11.5 | Lua game framework with GLSL shaders |
| ffmpeg | 8.x | Frame sequence -> GIF/MP4 export |
| LuaJIT | 5.1 | LOVE's embedded runtime |

No package manager. No build step. No dependencies beyond LOVE and ffmpeg.

## Related

- [bboy-analytics](https://github.com/stussysenik/bboy-analytics) — Quantitative breakdance battle analytics. Musicality scoring via 3D joint velocity x audio beat cross-correlation. lua-shaders teaches the rendering math; bboy-analytics applies it to motion capture.

---

*Built with obsessive attention to barrier-of-entry reduction.*
