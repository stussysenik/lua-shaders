# Lua Shader Koans — Design Spec

## Problem

Learning GPU shaders is intimidating: GLSL syntax, GPU pipeline concepts, and heavy math converge into a steep barrier-of-entry. Existing resources are either too academic (textbooks) or too scattered (random Shadertoy examples). There's no progressive, Karpathy-style learning path that teaches shader math through hands-on puzzles while producing visually stunning, shareable content.

## Solution

A LÖVE (Love2D) project that teaches graphics shaders through progressive koans — fill-in-the-blank GLSL puzzles with Karpathy-style teaching moments. Each koan produces a visual that doubles as an Instagram-ready animated story (9:16, 15-60 seconds, GIF/MP4 export).

## Architecture: Modular Monolith

Single LÖVE project with clean internal module boundaries. Contributors add koans without touching engine code.

```
lua-shaders/
├── conf.lua                    -- LÖVE config (window, modules)
├── main.lua                    -- entry point, mode router
│
├── lib/                        -- Core modules (stable API)
│   ├── koan_runner.lua         -- loads/validates/runs koans
│   ├── shader_loader.lua       -- GLSL loading + blank detection
│   ├── presenter.lua           -- 9:16 canvas, text overlay, transitions
│   ├── recorder.lua            -- frame capture → PNG sequence
│   └── exporter.lua            -- ffmpeg wrapper → GIF/MP4
│
├── koans/                      -- Content (contributor zone)
│   ├── index.lua               -- curriculum order + metadata
│   ├── 01_coordinates/
│   │   ├── koan.lua            -- title, hints, lesson, difficulty
│   │   ├── shader.glsl         -- shader with ??? blanks
│   │   ├── solution.glsl       -- completed shader
│   │   └── present.lua         -- presentation config (timing, text)
│   ├── 02_color_mixing/
│   ├── 03_shapes_sdf/
│   ├── 04_waves_motion/
│   ├── 05_noise/
│   ├── 06_fractals/
│   └── 07_raymarching/
│
├── themes/                     -- presentation themes
│   └── instagram.lua           -- 1080×1920, fonts, overlay style
│
├── export/                     -- output directory (gitignored)
│
└── docs/
    ├── CONTRIBUTING.md
    └── KOAN_FORMAT.md
```

### Design Principles

- **SRP**: each `lib/` module does one thing with a clear interface
- **Modular**: koans are pure data (GLSL + Lua config), engine and presentation are separate, composed at `main.lua`
- **Reusable**: presenter/recorder pipeline works with any koan; new themes = one file
- **No dead code**: start lean, add only what's used

### Run Modes

- `love . --learn` — interactive koan runner (fill blanks, get feedback)
- `love . --present 01_coordinates` — presentation mode (9:16, record, export)
- `love . --present all` — batch export all koans

## Koan Format

Each koan is a folder with 4 files:

### koan.lua — Metadata & Teaching

```lua
return {
  title = "The Canvas is a Map",
  chapter = "coordinates",
  order = 1,
  difficulty = "beginner",

  lesson = [[
    Every pixel has an address. In shader land,
    we normalize these to 0.0–1.0. The bottom-left
    is (0,0), the top-right is (1,1).
    This is your UV coordinate system.
  ]],

  hints = {
    "What if x position = red, y position = green?",
    "screen_coords / screen_size gives you 0→1",
  },

  concepts = { "normalization", "coordinate systems", "UV mapping" },
}
```

### shader.glsl — The Puzzle

```glsl
// Koan: The Canvas is a Map
// Fill in the ??? to paint a UV gradient

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = ???;
    return vec4(uv.x, uv.y, 0.0, 1.0);
}
```

Blanks are marked with `???`. The `shader_loader` detects these to determine koan completeness.

### solution.glsl — The Answer

```glsl
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    return vec4(uv.x, uv.y, 0.0, 1.0);
}
```

Used for: (1) validating learner solutions by visual comparison, (2) powering presentation mode.

### present.lua — Presentation Timeline

```lua
return {
  duration = 20,  -- seconds
  fps = 30,

  timeline = {
    { at = 0,  show = "title" },
    { at = 3,  show = "lesson" },
    { at = 8,  show = "code" },
    { at = 14, show = "solution" },
    { at = 18, show = "concepts" },
  },

  shader_params = {
    -- animate uniforms for visual interest during presentation
  },
}
```

## Module Specifications

### lib/koan_runner.lua

- Loads koan folders from `koans/` by reading `index.lua` for ordering
- Validates koan structure (all 4 files present, required fields in `koan.lua`)
- In learn mode: loads `shader.glsl`, detects `???` blanks. Learner edits the `.glsl` file in their text editor; the runner watches for file changes and hot-reloads
- Compiles shader and reports GLSL errors with human-readable messages
- Compares learner output to solution output (visual diff or exact match)

### lib/shader_loader.lua

- Reads `.glsl` files and prepends LÖVE shader boilerplate
- Detects `???` blank markers and tracks their positions
- Compiles GLSL via `love.graphics.newShader()` with error wrapping
- Provides `time` uniform automatically (seconds since start)

### lib/presenter.lua

- Creates off-screen canvas at theme resolution (1080×1920 for Instagram)
- Runs `solution.glsl` as a full-screen quad on the canvas
- Reads `present.lua` timeline and manages overlay state
- Renders text overlays: title, lesson text, code snippet, concept tags
- Handles fade-in/out transitions between timeline events
- Passes `time` uniform to shader for animation

### lib/recorder.lua

- Captures presenter canvas to PNG each frame via `canvas:newImageData():encode("png")`
- Fixed timestep rendering (decoupled from wall clock) for consistent output
- Writes frames to `export/frames/<koan_name>/frame_NNNN.png`
- Reports progress (frame count, estimated time remaining)

### lib/exporter.lua

- Calls ffmpeg via `os.execute()` after recording completes
- GIF: `ffmpeg -framerate 30 -i frame_%04d.png -vf "palettegen" + paletteuse` for optimized palette
- MP4: `ffmpeg -framerate 30 -i frame_%04d.png -c:v libx264 -pix_fmt yuv420p` for IG compatibility
- Cleans up frame PNGs after successful export
- Outputs to `export/<koan_name>.gif` and `export/<koan_name>.mp4`

### themes/instagram.lua

```lua
return {
  width = 1080,
  height = 1920,
  name = "instagram",

  fonts = {
    title = { family = "default", size = 72, weight = "bold" },
    lesson = { family = "default", size = 36 },
    code = { family = "monospace", size = 28 },
    tag = { family = "default", size = 24 },
  },

  layout = {
    title_y = 0.04,       -- 4% from top
    lesson_y = 0.15,
    code_y = 0.65,        -- lower third
    concepts_y = 0.88,
    branding_y = 0.95,
  },

  overlay = {
    code_bg = { 0, 0, 0, 0.7 },
    code_radius = 12,
    tag_bg = { 1, 1, 1, 0.1 },
    tag_radius = 20,
  },

  branding = "lua-shaders",
}
```

## Curriculum

### Chapter 01: Coordinates & UV Space
- **01a** UV gradient — normalize pixel position to color
- **01b** Aspect ratio — correct for non-square canvases
- **01c** Centering — remap origin to screen center
- **01d** Coordinate remapping — scale and translate UV space

### Chapter 02: Color Mixing & Palettes
- **02a** RGB as vec3 — colors are just numbers
- **02b** mix() and smoothstep() — blending functions
- **02c** Cosine palettes — Inigo Quilez's palette formula
- **02d** HSV conversion — hue wheels from math

### Chapter 03: Shapes with Signed Distance Fields
- **03a** Circle SDF — distance from center
- **03b** Box SDF — axis-aligned distance
- **03c** Combining shapes — union, intersection, subtraction
- **03d** Smooth blending — smooth minimum for organic shapes
- **03e** Ring and outline — abs() on distance fields

### Chapter 04: Waves & Motion
- **04a** Sine wave animation — time as input
- **04b** Wave interference — overlapping frequencies
- **04c** Polar coordinates — atan2 and radial patterns
- **04d** Spiral patterns — polar + time

### Chapter 05: Noise & Randomness
- **05a** Hash function — pseudo-random from coordinates
- **05b** Value noise — smooth random terrain
- **05c** Perlin noise — gradient-based smoothness
- **05d** FBM — fractal brownian motion, layered octaves

### Chapter 06: Fractals & Repetition
- **06a** Tiling with fract() — infinite grids
- **06b** Mandelbrot set — complex iteration
- **06c** Julia sets — parameter space exploration
- **06d** Domain repetition — infinite 3D worlds

### Chapter 07: Raymarching & 3D
- **07a** Ray setup — camera, direction, marching loop
- **07b** Sphere marching — step along the ray
- **07c** Lighting & normals — gradient estimation, Phong
- **07d** 3D SDF scenes — compose a full scene
- **07e** Capstone — combine everything into one shader

**Total: ~29 koans across 7 chapters.**

## Presentation Pipeline

### Flow

```
solution.glsl + present.lua
    → Presenter (1080×1920 canvas, text overlays, transitions)
    → Recorder (PNG frame sequence, fixed timestep)
    → Exporter (ffmpeg → GIF + MP4)
    → export/<koan_name>.{gif,mp4}
```

### Instagram Story Layout

- **Top**: koan number + title (bold, large)
- **Middle**: shader runs as animated full-screen background
- **Lower third**: code snippet overlay (dark glass background, monospace)
- **Bottom**: concept tags as pills + subtle branding

### Export Specs

- Resolution: 1080×1920 (9:16)
- Duration: 15-60 seconds (per koan's `present.lua`)
- Frame rate: 30fps
- GIF: palette-optimized, max 15MB for IG
- MP4: H.264, yuv420p for IG Reels compatibility

## Dependencies

- **LÖVE 11.x+** — runtime (`brew install love`)
- **ffmpeg** — export (`brew install ffmpeg`)
- **Lua 5.1** (LÖVE's embedded LuaJIT) — koan configs

No other dependencies. No package manager. No build step.

## Verification Plan

1. **Install LÖVE**: `brew install love`
2. **Run first koan in learn mode**: `love . --learn` — verify shader loads, `???` detected, learner can edit
3. **Run first koan in present mode**: `love . --present 01_coordinates` — verify 9:16 canvas, overlay renders, frames captured
4. **Export GIF**: verify ffmpeg produces a valid GIF in `export/`
5. **Visual check**: open the GIF — does it look Instagram-ready? Shader animating, text readable, timing correct?
6. **Add a new koan**: create a folder with 4 files, verify it appears in the curriculum without engine changes
