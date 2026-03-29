// Koan 02d: The Hue Wheel
//
// Convert HSV to RGB using math:
//   hue → which color (0→1 wraps around the wheel)
//   sat → how vivid (0 = gray)
//   val → how bright (0 = black)
//
// The formula:
//   k = fract(h + vec3(0, 2, 1) / 3.0) * 6.0 - 3.0
//   rgb = val * mix(vec3(1), clamp(abs(k) - 1.0, 0.0, 1.0), sat)
//
// Fill in the blank to create a hue wheel using the angle from center.

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy - 0.5;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;

    float angle = atan(uv.y, uv.x);
    float hue = ???;
    float sat = 1.0;
    float val = 1.0;

    vec3 k = fract(hue + vec3(0.0, 2.0, 1.0) / 3.0) * 6.0 - 3.0;
    vec3 rgb = val * mix(vec3(1.0), clamp(abs(k) - 1.0, 0.0, 1.0), sat);
    return vec4(rgb, 1.0);
}
