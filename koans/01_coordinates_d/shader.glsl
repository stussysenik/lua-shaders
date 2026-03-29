// Koan 01d: Zooming In
//
// Use coordinate remapping to create a tiled pattern.
// fract() returns the fractional part: fract(2.7) = 0.7
// Applied to UVs, it repeats the 0→1 range.
//
// Fill in the blank to tile the UV gradient into a 4x4 grid.

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    uv = ???;
    return vec4(uv.x, uv.y, 0.5, 1.0);
}
