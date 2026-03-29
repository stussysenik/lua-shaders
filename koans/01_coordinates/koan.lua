--- Koan: The Canvas is a Map
--- Chapter 1: Coordinates & UV Space
---
--- Every pixel on the screen has a position. In shader land, we normalize
--- these positions to the range 0.0-1.0 so our math works at any resolution.
--- This normalized position is called a UV coordinate.
return {
    title = "The Canvas is a Map",
    chapter = "coordinates",
    order = 1,
    difficulty = "beginner",

    lesson = [[
Why: Shaders run at ANY resolution. Normalizing pixel positions
to 0.0-1.0 makes your math portable -- same code, any screen.

What you see: a smooth red-green gradient filling the screen.
What's really happening: one division. Pixel position / screen
size. The x-coordinate becomes red, y becomes green. That's it.

Every pixel has an address. Divide by screen size and you get
UV coordinates: a 0->1 grid where (0,0) is bottom-left and
(1,1) is top-right. This is the foundation of every shader.

Unlocks: aspect ratio correction, centering, distance fields,
and every effect in this entire course.]],

    hints = {
        "This effect is ONE operation: screen_coords / love_ScreenSize.xy",
        "Map x -> red, y -> green to visualize the coordinate system",
    },

    concepts = { "normalization", "coordinate systems", "UV mapping" },
}
