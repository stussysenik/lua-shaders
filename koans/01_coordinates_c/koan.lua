--- Koan: Moving the Origin
--- Chapter 1: Coordinates & UV Space
---
--- By default, (0,0) is at the bottom-left corner.
--- For many effects (circles, rotations, radial patterns),
--- we want (0,0) at the center of the screen.
return {
    title = "Moving the Origin",
    chapter = "coordinates",
    order = 3,
    difficulty = "beginner",

    lesson = [[
Builds on: 01 (UV normalization), 01b (aspect ratio).

Why: Most interesting effects -- circles, rings, spirals -- radiate
from a center point. But UV (0,0) is at the corner. One subtraction
moves the origin to the center of the screen.

What you see: concentric rings radiating from the screen center.
What's really happening: subtract 0.5 from UV. Now center = (0,0).
length(uv) gives distance from center. That single number
drives the entire pattern.

This is the second space transformation: translating the origin.
Combined with aspect correction, you now have a perfect radial
coordinate system.

Unlocks: distance fields (chapter 3), polar coordinates (chapter 4),
and every radial/circular effect.]],

    hints = {
        "One subtraction: uv = uv - 0.5 shifts range from 0->1 to -0.5->+0.5",
        "length(uv) = distance from center. That's how rings work.",
    },

    concepts = { "origin translation", "centered coordinates", "radial distance" },
}
