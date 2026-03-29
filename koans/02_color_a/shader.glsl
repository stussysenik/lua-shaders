// Koan 02a: Colors Are Numbers
//
// Create a horizontal gradient from red to blue
// using the x-coordinate to blend between them.
//
// mix(a, b, t) returns a when t=0, b when t=1.
// Fill in the ??? to blend from red to blue across the screen.

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    vec3 red = vec3(1.0, 0.0, 0.0);
    vec3 blue = vec3(0.0, 0.0, 1.0);
    vec3 col = mix(red, blue, ???);
    return vec4(col, 1.0);
}
