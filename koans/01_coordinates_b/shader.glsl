// Koan 01b: The Stretch Problem
//
// UV coordinates stretch on non-square screens.
// To fix: center the coords (-0.5 to +0.5), then
// multiply x by aspect ratio (width/height).
//
// Fill in the ??? to correct the aspect ratio.

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    uv = uv - 0.5;
    uv.x *= ???;
    float d = length(uv);
    float circle = smoothstep(0.3, 0.29, d);
    return vec4(vec3(circle), 1.0);
}
