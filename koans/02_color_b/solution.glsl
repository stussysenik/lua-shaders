// Koan 02b: The Smooth Knife — Solution

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    float edge = 0.5 + 0.3 * sin(time);
    float gradient = smoothstep(edge - 0.1, edge + 0.1, uv.x);
    vec3 col = mix(vec3(0.9, 0.2, 0.3), vec3(0.2, 0.3, 0.9), gradient);
    return vec4(col, 1.0);
}
