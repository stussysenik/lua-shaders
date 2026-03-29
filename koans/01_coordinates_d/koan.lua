return {
    title = "Zooming In",
    chapter = "coordinates",
    order = 4,
    difficulty = "beginner",

    lesson = [[
Multiplying UV coordinates by a number zooms the view.
Multiply by 2.0 → zoom out (see more). Multiply by 0.5 → zoom in.
Adding a vec2 offset pans the camera.

This is coordinate remapping: transforming UV space before
computing your effect. Every fractal viewer uses this.]],

    hints = {
        "Multiply uv by a scale factor to zoom",
        "fract() repeats a pattern — try fract(uv * 4.0)",
    },

    concepts = { "coordinate remapping", "scaling", "tiling", "fract()" },
}
