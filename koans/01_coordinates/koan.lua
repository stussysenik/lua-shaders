--- Koan: The Canvas is a Map
--- Chapter 1: Coordinates & UV Space
---
--- Every pixel on the screen has a position. In shader land, we normalize
--- these positions to the range 0.0–1.0 so our math works at any resolution.
--- This normalized position is called a UV coordinate.
return {
    title = "The Canvas is a Map",
    chapter = "coordinates",
    order = 1,
    difficulty = "beginner",

    lesson = [[
Every pixel has an address. In shader land, we normalize
these to 0.0–1.0. The bottom-left is (0,0), the top-right
is (1,1). This is your UV coordinate system.

To get UV coordinates, divide the pixel's screen position
by the total screen size. The result: a smooth gradient
where x-position becomes red and y-position becomes green.]],

    hints = {
        "What if x position = red, y position = green?",
        "screen_coords / love_ScreenSize.xy gives you 0→1",
    },

    concepts = { "normalization", "coordinate systems", "UV mapping" },
}
