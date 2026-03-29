// Koan 02c: Inigo's Rainbow
//
// The cosine palette formula:
//   color(t) = a + b * cos(6.28318 * (c * t + d))
//
// a = offset (brightness center)
// b = amplitude (color range)
// c = frequency (how many color cycles)
// d = phase (shifts each RGB channel)
//
// Fill in ??? to implement the cosine palette.
// Try: a=0.5, b=0.5, c=1.0, d=vec3(0.0, 0.33, 0.67)

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;

    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.0, 0.33, 0.67);

    float t = uv.x;
    vec3 col = ???;
    return vec4(col, 1.0);
}
