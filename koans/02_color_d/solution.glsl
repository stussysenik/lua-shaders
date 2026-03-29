// Koan 02d: The Hue Wheel — Solution

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy - 0.5;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;

    float angle = atan(uv.y, uv.x);
    float hue = angle / 6.28318 + 0.5 + time * 0.1;
    float dist = length(uv);
    float sat = smoothstep(0.0, 0.3, dist);
    float val = 1.0 - smoothstep(0.35, 0.4, dist);

    vec3 k = fract(hue + vec3(0.0, 2.0, 1.0) / 3.0) * 6.0 - 3.0;
    vec3 rgb = val * mix(vec3(1.0), clamp(abs(k) - 1.0, 0.0, 1.0), sat);
    return vec4(rgb, 1.0);
}
