return {
    title = "Moving the Origin",
    chapter = "coordinates",
    order = 3,
    difficulty = "beginner",

    lesson = [[
By default, UV (0,0) is at the corner. But most interesting
effects need the origin at the center. Subtracting 0.5 from
UV coordinates shifts the range from 0→1 to -0.5→+0.5.

Now the center of the screen is (0,0) and distance from
center gives you radial patterns.]],

    hints = {
        "Subtract 0.5 from both x and y to center",
        "abs() gives you distance from the center axis",
    },

    concepts = { "origin translation", "centered coordinates", "radial distance" },
}
