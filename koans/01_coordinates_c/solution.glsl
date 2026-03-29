// Koan 01c: Moving the Origin — Solution

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    uv = uv - 0.5;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;
    float d = length(uv);
    float rings = sin(d * 20.0 - time * 3.0) * 0.5 + 0.5;
    return vec4(rings * 0.3, rings * 0.6, rings, 1.0);
}
