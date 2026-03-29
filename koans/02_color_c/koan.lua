return {
    title = "Inigo's Rainbow",
    chapter = "color",
    order = 3,
    difficulty = "intermediate",

    lesson = [[
Inigo Quilez discovered that beautiful color palettes can be
generated with a single formula:

  color(t) = a + b * cos(2π * (c*t + d))

Where a, b, c, d are vec3 parameters. By tweaking these four
vectors, you get infinite palettes. One formula to rule them all.]],

    hints = {
        "a = offset, b = amplitude, c = frequency, d = phase",
        "Try a=0.5, b=0.5, c=1.0, d=vec3(0.0, 0.33, 0.67) for rainbow",
    },

    concepts = { "cosine palettes", "Inigo Quilez", "parametric color", "periodic functions" },
}
