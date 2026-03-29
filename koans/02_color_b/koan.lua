return {
    title = "The Smooth Knife",
    chapter = "color",
    order = 2,
    difficulty = "beginner",

    lesson = [[
smoothstep(edge0, edge1, x) is the shader swiss army knife.
It returns 0 when x < edge0, 1 when x > edge1, and a smooth
S-curve in between. No jagged edges, just butter.

Use it for: soft borders, smooth transitions, anti-aliasing,
color ramps, masks — almost everything.]],

    hints = {
        "smoothstep(0.4, 0.6, uv.x) creates a soft edge at x=0.5",
        "Try smoothstep on distance to create a soft circle",
    },

    concepts = { "smoothstep", "interpolation", "anti-aliasing", "S-curve" },
}
