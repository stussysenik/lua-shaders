--- Koan: Colors Are Numbers
--- Chapter 2: Color Mixing & Palettes
---
--- In shaders, colors aren't picked from a palette -- they're computed.
--- RGB channels are just numbers 0->1 that you manipulate with arithmetic.
return {
    title = "Colors Are Numbers",
    chapter = "color",
    order = 1,
    difficulty = "beginner",

    lesson = [[
Builds on: Chapter 1 (UV coordinates as input).

Why: In shaders, colors aren't picked from a palette -- they're
computed. RGB channels are just numbers 0->1. Add, multiply, mix
them with arithmetic. This is color mapping: scalar in, color out.

What you see: a smooth gradient from red to blue across the screen.
What's really happening: uv.x (a number 0->1 from chapter 1)
feeds into mix(red, blue, uv.x). One function blends two colors
using a scalar input. That's the entire effect.

mix(a, b, t) is linear interpolation: returns a when t=0, b when
t=1, and blends smoothly in between. Every gradient you've ever
seen is just mix() with a spatial input.

Unlocks: smoothstep (soft edges), cosine palettes (infinite
color schemes), and every visual effect that involves color.]],

    hints = {
        "One function: mix(red, blue, uv.x) blends based on x-position",
        "mix(a, b, 0.5) gives you the exact midpoint between a and b",
    },

    concepts = { "color mapping", "linear interpolation", "RGB vectors", "UV as input (from Ch.1)" },
}
