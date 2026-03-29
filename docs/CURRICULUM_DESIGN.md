# Curriculum Design Guide

Pedagogical patterns extracted from senior-level teaching approaches (Karpathy, The Senior Dev) applied to shader koans.

## Core Principle: Chained Mental Models

Every concept must connect back to previous ones. Never teach in isolation.

```
UV coordinates → aspect ratio correction → centering → distance fields
    ↓                                                        ↓
color mixing → smoothstep → SDF edge rendering        → noise
    ↓                ↓                                    ↓
cosine palettes → animation (time) → wave interference → FBM
                        ↓
                  polar coords → spirals → fractals → raymarching
```

Each koan's `lesson` text should explicitly reference which prior koan(s) it builds on. The learner should never wonder "why am I learning this?" — the chain answers that.

## Pattern 1: X-Ray Vision

Train learners to see the math behind the visual.

A beginner sees a plasma effect. A shader developer sees:
- `sin()` waves at different frequencies
- Color palette mapping via cosine formula
- Time-based animation shifting phase

Every koan should have a **"What you see vs. what's really happening"** moment in the lesson text. The gap between perception and math IS the learning.

### Application to koan.lua:

```lua
lesson = [[
What you see: a pulsing, colorful ring.
What's really happening: distance from center → smoothstep edge →
cosine palette → time-animated phase shift.

Four operations. That's it. The GPU runs this formula
for every pixel, 60 times per second.]]
```

## Pattern 2: Essential State (Minimum Viable Math)

From "15 Frontend Concepts": senior devs condense UI to essential state — the minimum data to render everything else.

Apply the same to shaders: **what is the minimum math to produce this visual?**

Each koan should strip the effect down to its irreducible core. If you remove any line, the effect breaks. This teaches learners to think in terms of mathematical primitives, not memorized recipes.

### Application to hints:

```lua
hints = {
    "This effect uses only 3 math operations. What are they?",
    "Everything derives from the distance to center. Start there.",
}
```

## Pattern 3: Systems Thinking Over Memorization

From "15 Frontend Concepts": "Think in systems, components, and relationships rather than memorizing."

Don't teach `smoothstep(0.3, 0.31, d)` as a magic incantation. Teach it as:
- `d` = distance field (a concept from koan 03)
- `smoothstep` = soft edge (a concept from koan 02b)
- `0.3, 0.31` = edge position and width (connect to anti-aliasing)

### Application to concepts array:

Each koan's `concepts` should reference concepts from PREVIOUS koans to make the chain explicit:

```lua
concepts = {
    "smooth union",          -- new concept
    "SDF (from 03a)",        -- prior reference
    "smoothstep (from 02b)", -- prior reference
}
```

## Pattern 4: Pattern Over Implementation

From "15 Frontend Concepts": seniors focus on patterns (reducer, observer), not libraries (Redux, Zustand).

For shaders: teach the PATTERN, not the GLSL syntax.

| Pattern | What it teaches | Examples |
|---------|----------------|----------|
| Distance field | Geometry as a scalar function | Circles, boxes, unions, smooth blending |
| Domain repetition | Infinite from finite via `fract()` | Tiling, fractals, infinite corridors |
| Color mapping | Scalar → color via formula | Cosine palettes, HSV, heatmaps |
| Space transformation | Change coords before computing | Polar, scaling, rotation, centering |
| Ray stepping | Traverse space by distance queries | Raymarching, shadows, AO |

Each chapter teaches ONE pattern. Koans within the chapter show variations. The learner masters the pattern, not the specific shader.

## Pattern 5: Progressive Complexity Tiers

From "Frontend Architecture Patterns": evolution from simple → complex with explicit trade-offs at each level.

```
Tier 1 — Foundation (Ch 1-2)
  "I understand what UV coordinates and colors are"
  No time, no animation, pure spatial math

Tier 2 — Motion (Ch 3-4)
  "I can make things move and have shape"
  SDFs + time = animated geometry

Tier 3 — Organic (Ch 5-6)
  "I can create natural-looking textures and patterns"
  Noise + fractals = organic, infinite complexity

Tier 4 — 3D (Ch 7)
  "I can render a 3D scene from a pixel shader"
  Raymarching = the final synthesis of all prior patterns
```

Each tier EXPLICITLY builds on ALL prior tiers. Tier 4 uses distance fields (Tier 2), noise (Tier 3), and coordinate transforms (Tier 1).

## Pattern 6: The "Why Does This Exist?" Framework

Every technique exists because it solves a specific visual problem. Lead with the problem, not the solution.

| Don't say | Say instead |
|-----------|-------------|
| "Let's learn about smoothstep" | "Hard edges look ugly on screens. How do we make them soft?" |
| "Now we'll do noise functions" | "Nature isn't smooth. How do we fake organic randomness with math?" |
| "Time to learn raymarching" | "What if you could render 3D without any vertices or meshes?" |

### Application to koan titles and lessons:

Titles should be evocative questions or provocative statements, not topic labels:
- "The Stretch Problem" (not "Aspect Ratio")
- "The Smooth Knife" (not "Smoothstep Function")
- "Inigo's Rainbow" (not "Cosine Color Palettes")
- "Nature Doesn't Tile" (not "Noise Functions")

## Pattern 7: Back-of-Envelope Thinking

From "Frontend System Design": break huge numbers into concrete, graspable quantities.

Apply to shaders: help learners reason about GPU computation.

```
Screen: 1080 x 1920 = 2,073,600 pixels
FPS: 60
= 124,416,000 shader executions per second

Your 5-line effect() function runs 124 MILLION times per second.
That's why GPUs exist.
```

Include this kind of scale reasoning in lesson text to create awe and respect for the GPU.

## Pattern 8: Visual Proof, Not Trust

From "Frontend System Design": always measure with core web vitals, don't trust "it feels fast."

For shaders: the visual output IS the proof. Every koan's `solution.glsl` produces a visual that is unambiguously correct or incorrect. There's no "close enough" — the math either works or it doesn't.

The IG presentation should show both the broken/blank state AND the working solution to create contrast. Before/after is more powerful than just "after."

## Applying to the Curriculum

### Chapter structure (updated):

Each chapter folder should contain a `README.md`:

```markdown
# Chapter N: [Pattern Name]

## The Problem
[What visual problem does this pattern solve?]

## The Pattern
[One sentence: what is the core idea?]

## Prior Knowledge
[Which previous chapters/koans this builds on]

## Koans in This Chapter
1. [Koan title] — introduces the core idea
2. [Koan title] — first variation
3. [Koan title] — combines with prior concept
4. [Koan title] — pushes to the edge
```

### Koan difficulty tags (refined):

- **beginner** — Uses only concepts from current + one prior chapter
- **intermediate** — Combines concepts from 2+ prior chapters
- **advanced** — Requires synthesizing 3+ chapters into one effect
- **capstone** — Combines ALL prior chapters (one per tier)
