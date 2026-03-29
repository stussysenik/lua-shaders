return {
    title = "The Stretch Problem",
    chapter = "coordinates",
    order = 2,
    difficulty = "beginner",

    lesson = [[
When the screen isn't square, UV coordinates stretch.
A circle becomes an oval. To fix this, multiply the
x-coordinate by the aspect ratio (width / height).

This gives you a coordinate system where 1 unit
in x equals 1 unit in y — no distortion.]],

    hints = {
        "aspect ratio = width / height",
        "Multiply uv.x by the aspect ratio after centering",
    },

    concepts = { "aspect ratio", "distortion correction", "proportional coordinates" },
}
