// Koan 01d: Zooming In — Solution

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    float tiles = 4.0 + 2.0 * sin(time * 0.5);
    uv = fract(uv * tiles);
    return vec4(uv.x, uv.y, 0.5 + 0.3 * sin(time), 1.0);
}
