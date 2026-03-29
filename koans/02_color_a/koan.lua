return {
    title = "Colors Are Numbers",
    chapter = "color",
    order = 1,
    difficulty = "beginner",

    lesson = [[
In shaders, colors are vec3 or vec4 — just numbers.
Red is (1, 0, 0). Green is (0, 1, 0). Blue is (0, 0, 1).
You can add, multiply, and mix colors with arithmetic.

vec3(0.5) means (0.5, 0.5, 0.5) — a medium gray.
Multiplying a color by 0.5 makes it half as bright.]],

    hints = {
        "Try vec3(1.0, 0.0, 0.0) for pure red",
        "Use uv.x to interpolate between two colors",
    },

    concepts = { "RGB vectors", "color arithmetic", "brightness" },
}
