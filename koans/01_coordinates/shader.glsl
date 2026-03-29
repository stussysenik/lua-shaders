// Koan 01: The Canvas is a Map
//
// Every pixel has a screen position (screen_coords).
// The screen has a total size (love_ScreenSize.xy).
//
// To normalize the position to 0.0–1.0, divide position by size.
// Then map x → red and y → green to visualize the coordinate system.
//
// Fill in the ??? to compute the UV coordinates.

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = ???;
    return vec4(uv.x, uv.y, 0.0, 1.0);
}
