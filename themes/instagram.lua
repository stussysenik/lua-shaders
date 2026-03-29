--- Instagram Story theme: 1080×1920 (9:16 vertical)
--- Defines layout positions, font sizes, and overlay styles
--- for the presentation pipeline.
return {
    width = 1080,
    height = 1920,
    name = "instagram",

    fonts = {
        koan_number = 24,
        title = 64,
        lesson = 32,
        code = 26,
        tag = 22,
        branding = 18,
    },

    --- Layout positions as fractions of canvas height.
    --- Multiply by theme.height to get pixel position.
    layout = {
        padding_x = 48,
        koan_number_y = 0.04,
        title_y = 0.06,
        lesson_y = 0.16,
        code_y = 0.62,
        concepts_y = 0.88,
        branding_y = 0.95,
    },

    overlay = {
        code_bg = { 0, 0, 0, 0.7 },
        code_padding = 24,
        code_radius = 12,
        tag_bg = { 1, 1, 1, 0.1 },
        tag_padding_x = 16,
        tag_padding_y = 6,
        tag_radius = 20,
        tag_gap = 10,
    },

    transitions = {
        default_fade_in = 0.5,
    },

    branding = "lua-shaders",
}
