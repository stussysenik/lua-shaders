// Koan 02b: The Smooth Knife
//
// Use smoothstep to create a soft-edged split:
// black on the left, white on the right, smooth transition in between.
//
// smoothstep(edge0, edge1, x):
//   x < edge0 → 0.0
//   x > edge1 → 1.0
//   between → smooth curve
//
// Fill in the ??? to create a smooth edge at x = 0.5

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    float gradient = ???;
    return vec4(vec3(gradient), 1.0);
}
