return {
    title = "The Hue Wheel",
    chapter = "color",
    order = 4,
    difficulty = "intermediate",

    lesson = [[
RGB mixes colors by brightness. HSV separates them:
H = hue (which color: 0=red, 0.33=green, 0.67=blue)
S = saturation (0=gray, 1=vivid)
V = value (0=dark, 1=bright)

To convert: use the hue to pick 3 ramp values,
scale by saturation, and multiply by value.
The formula is just math — no lookup tables needed.]],

    hints = {
        "fract(h + vec3(0, 2, 1) / 3.0) offsets RGB phases",
        "clamp and mix to create the ramp for each channel",
    },

    concepts = { "HSV color space", "hue", "saturation", "color conversion" },
}
