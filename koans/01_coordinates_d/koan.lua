--- Koan: Zooming In
--- Chapter 1: Coordinates & UV Space
---
--- Once you have centered UV coordinates, you can scale them
--- to zoom in or out, and add offsets to pan around.
--- This is coordinate remapping -- the foundation of every fractal.
return {
    title = "Zooming In",
    chapter = "coordinates",
    order = 4,
    difficulty = "beginner",

    lesson = [[
Builds on: 01 (UV), 01b (aspect), 01c (centering).

Why: What if you want infinite repetition from finite code?
Multiply UV by a number to zoom. Apply fract() to repeat the
0->1 range infinitely. Two operations = infinite tiled worlds.

What you see: a 4x4 grid of repeating UV gradients.
What's really happening: fract(uv * 4.0). The fract() function
returns only the decimal part (fract(2.7) = 0.7), so the 0->1
range repeats 4 times across the screen.

This is your third space transformation: domain repetition.
You're not drawing 16 tiles -- you're drawing ONE tile and
letting the math repeat it infinitely.

Unlocks: tiling patterns, Mandelbrot zoom, infinite corridors,
and every fractal effect (chapter 6).]],

    hints = {
        "Two operations: multiply to scale, fract() to repeat",
        "fract(uv * 4.0) creates a 4x4 tiled grid",
    },

    concepts = { "domain repetition", "scaling", "fract()", "space transformation (from 01b, 01c)" },
}
