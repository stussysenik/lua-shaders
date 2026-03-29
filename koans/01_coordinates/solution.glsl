// Koan 01: The Canvas is a Map — Solution
//
// Dividing screen_coords by love_ScreenSize.xy normalizes
// pixel positions to the 0→1 range. This is UV mapping:
// the foundation of every shader effect.

extern number time;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    return vec4(uv.x, uv.y, 0.5 + 0.5 * sin(time * 2.0), 1.0);
}
