--- Koan: The Hue Wheel
--- Chapter 2: Color Mixing & Palettes
---
--- HSV separates color into Hue, Saturation, and Value --
--- independent controls that RGB can't offer.
return {
    title = "The Hue Wheel",
    chapter = "color",
    order = 4,
    difficulty = "intermediate",

    lesson = [[
Builds on: 02a (RGB as numbers), 02b (smoothstep), 02c (cosine palettes).

Why: RGB mixes brightness into color. Want pure red darker? You
lose the red. HSV separates the concerns: Hue = which color,
Saturation = how vivid, Value = how bright. Independent controls.

What you see: a smooth color wheel -- all hues arranged in a circle.
What's really happening: atan(y, x) computes the angle from center
(a concept from chapter 1's centered coordinates). Angle -> hue.
Then a 3-channel ramp via fract() (from 01d) and clamp() converts
hue to RGB. Distance from center -> saturation.

HSV is a color-space transformation -- the same idea as the
coordinate-space transformations in chapter 1, but applied to
color instead of position.

Unlocks: intuitive color control, hue rotation effects, and
color-space manipulation for artistic shader work.]],

    hints = {
        "Angle from center = hue. Normalize: angle / (2*pi) + 0.5",
        "The RGB ramp uses fract() to offset each channel by 1/3",
    },

    concepts = { "HSV color space", "color-space transformation", "atan2 (polar coords)", "fract (from 01d)" },
}
