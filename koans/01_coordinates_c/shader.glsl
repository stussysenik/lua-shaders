// Koan 01c: Moving the Origin
//
// Shift the origin from bottom-left to screen center.
// Then use the distance from center to create a radial gradient.
//
// Fill in the blank to center the coordinates.

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    uv = ???;
    float d = length(uv);
    return vec4(d, d, d, 1.0);
}
