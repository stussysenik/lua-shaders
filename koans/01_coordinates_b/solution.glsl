// Koan 01b: The Stretch Problem — Solution

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    uv = uv - 0.5;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;
    float d = length(uv);
    float pulse = 0.3 + 0.02 * sin(time * 3.0);
    float circle = smoothstep(pulse, pulse - 0.01, d);
    return vec4(vec3(circle), 1.0);
}
