// Koan 02a: Colors Are Numbers — Solution

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    vec3 red = vec3(1.0, 0.2, 0.1);
    vec3 blue = vec3(0.1, 0.2, 1.0);
    float t = uv.x + 0.1 * sin(uv.y * 10.0 + time * 2.0);
    vec3 col = mix(red, blue, t);
    return vec4(col, 1.0);
}
