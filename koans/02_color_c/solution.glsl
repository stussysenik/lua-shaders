// Koan 02c: Inigo's Rainbow — Solution

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    uv = uv - 0.5;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;

    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.0, 0.33, 0.67);

    float dist = length(uv);
    float t = dist * 2.0 - time * 0.5;
    vec3 col = a + b * cos(6.28318 * (c * t + d));
    return vec4(col, 1.0);
}
