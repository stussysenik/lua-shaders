--- Koan: The Stretch Problem
--- Chapter 1: Coordinates & UV Space
---
--- Raw UV coordinates stretch when the window isn't square.
--- To get perfect circles and undistorted shapes, we need
--- to correct for the aspect ratio.
return {
    title = "The Stretch Problem",
    chapter = "coordinates",
    order = 2,
    difficulty = "beginner",

    lesson = [[
Builds on: 01 (UV normalization).

Why: Raw UV coordinates assume a square screen. On a 9:16 phone,
a circle becomes an oval. One multiplication fixes this forever.

What you see: a perfect circle on a non-square screen.
What's really happening: after centering, multiply x by the
aspect ratio (width/height). Now 1 unit in x = 1 unit in y.

This is your first space transformation: you're not changing
what you draw, you're changing the coordinate system it lives in.

Unlocks: undistorted distance fields (chapter 3), correct
circles, and every radial effect.]],

    hints = {
        "One multiplication: uv.x *= love_ScreenSize.x / love_ScreenSize.y",
        "Center first (subtract 0.5), THEN correct aspect ratio",
    },

    concepts = { "aspect ratio", "space transformation", "distortion correction" },
}
