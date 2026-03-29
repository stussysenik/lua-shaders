--- Koan: Inigo's Rainbow
--- Chapter 2: Color Mixing & Palettes
---
--- Inigo Quilez discovered one formula that generates infinite
--- beautiful color palettes from just 4 vec3 parameters.
return {
    title = "Inigo's Rainbow",
    chapter = "color",
    order = 3,
    difficulty = "intermediate",

    lesson = [[
Builds on: 02a (color as numbers), 02b (smooth transitions).

Why: Hard-coded color palettes are ugly and limited. Inigo Quilez
discovered one formula that generates infinite beautiful palettes:

  color(t) = a + b * cos(2*pi * (c*t + d))

Four vec3 parameters. One cosine. Infinite palettes. This is the
scalar-to-color mapping pattern at its most powerful.

What you see: shimmering rainbow rings radiating from center.
What's really happening: distance from center (a scalar from Ch.1)
feeds into the cosine formula. Each RGB channel oscillates at a
different phase (d), creating smooth color transitions.

a = brightness center, b = color range, c = frequency, d = phase
offset per channel. Tweak d and the entire palette shifts.

Unlocks: procedural coloring for any effect -- noise landscapes,
fractal visualizations, heat maps. One formula, infinite beauty.]],

    hints = {
        "One formula: a + b * cos(6.28318 * (c * t + d))",
        "d = vec3(0.0, 0.33, 0.67) offsets RGB phases for rainbow",
    },

    concepts = { "cosine palettes", "parametric color", "Inigo Quilez", "scalar-to-color mapping (from 02a)" },
}
