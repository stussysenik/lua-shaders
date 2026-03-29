--- Koan: The Smooth Knife
--- Chapter 2: Color Mixing & Palettes
---
--- smoothstep() is the single most useful function in shader programming.
--- It creates perfectly smooth, anti-aliased transitions between regions.
return {
    title = "The Smooth Knife",
    chapter = "color",
    order = 2,
    difficulty = "beginner",

    lesson = [[
Builds on: 02a (color mapping with mix).

Why: Hard edges look aliased -- jagged, pixelated, ugly. One
function creates perfectly smooth transitions: smoothstep.
It's the single most useful function in shader programming.

What you see: a soft-edged boundary between black and white.
What's really happening: smoothstep(edge0, edge1, x) computes
a cubic S-curve. Below edge0 -> 0. Above edge1 -> 1. Between ->
a smooth, anti-aliased ramp. No jagged pixels.

Think of smoothstep as a "soft knife" that cuts space into
regions with perfectly smooth boundaries. Hard step = jagged.
Smooth step = butter.

Unlocks: SDF edge rendering (chapter 3), anti-aliased shapes,
soft masks, glow effects, and smooth color ramps.]],

    hints = {
        "One function: smoothstep(0.4, 0.6, uv.x) = soft edge at x=0.5",
        "The width between edge0 and edge1 controls blur amount",
    },

    concepts = { "smoothstep", "anti-aliasing", "S-curve interpolation", "mix (from 02a)" },
}
