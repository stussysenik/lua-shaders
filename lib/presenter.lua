local ShaderLoader = require("lib.shader_loader")

local Presenter = {}
Presenter.__index = Presenter

--- Strips redundant extern uniform declarations from a GLSL source string.
--- ShaderLoader.compile prepends its own boilerplate with time/resolution uniforms,
--- so we must remove any duplicate declarations already present in the source.
--- @param source string Raw GLSL source
--- @return string cleaned GLSL source without duplicate extern declarations
local function strip_extern_declarations(source)
    -- Remove lines that re-declare the standard uniforms added by the boilerplate
    local lines = {}
    for line in source:gmatch("[^\r\n]+") do
        local is_dup = line:match("^%s*extern%s+number%s+time%s*;")
                    or line:match("^%s*extern%s+vec2%s+resolution%s*;")
        if not is_dup then
            table.insert(lines, line)
        end
    end
    return table.concat(lines, "\n")
end

--- Creates a new Presenter for a given koan.
--- @param koan_path string Folder path e.g. "koans/01_coordinates"
--- @param theme table Theme config from themes/instagram.lua
--- @return Presenter|nil presenter, string|nil error
function Presenter.new(koan_path, theme)
    local self = setmetatable({}, Presenter)

    -- Load koan data
    local koan_file = koan_path .. "/koan.lua"
    local koan_loader = love.filesystem.load(koan_file)
    if not koan_loader then
        return nil, "Cannot load " .. koan_file
    end
    self.koan = koan_loader()

    -- Load presentation timeline
    local present_file = koan_path .. "/present.lua"
    local present_loader = love.filesystem.load(present_file)
    if not present_loader then
        return nil, "Cannot load " .. present_file
    end
    self.present = present_loader()

    -- Load and compile solution shader.
    -- Strip duplicate extern declarations before handing to ShaderLoader.compile,
    -- which prepends its own boilerplate containing time and resolution uniforms.
    local solution_path = koan_path .. "/solution.glsl"
    local source, read_err = ShaderLoader.read(solution_path)
    if not source then
        return nil, read_err
    end
    local clean_source = strip_extern_declarations(source)
    local shader, compile_err = ShaderLoader.compile(clean_source)
    if not shader then
        return nil, "Shader compile error: " .. compile_err
    end
    self.shader = shader

    -- Load puzzle source for code overlay
    local puzzle_path = koan_path .. "/shader.glsl"
    self.puzzle_source = ShaderLoader.read(puzzle_path) or ""

    -- Set up theme and canvas
    self.theme = theme
    self.canvas = love.graphics.newCanvas(theme.width, theme.height)
    self.time = 0
    self.duration = self.present.duration
    self.fps = self.present.fps or 30

    -- Precompute timeline events sorted by time; initialise all fade alphas to 0
    self.visible = {}
    self.fade_alphas = {}
    for _, event in ipairs(self.present.timeline) do
        self.fade_alphas[event.show] = 0
    end

    -- Create fonts
    self.fonts = {}
    for name, size in pairs(theme.fonts) do
        self.fonts[name] = love.graphics.newFont(size)
    end

    -- Dummy 1×1 canvas (unused by current renderer but kept for future quad draws)
    self.pixel = love.graphics.newCanvas(1, 1)

    return self, nil
end

--- Advances the presenter by dt seconds.
--- @param dt number Delta time in seconds
function Presenter:update(dt)
    self.time = self.time + dt

    -- Update visibility and fade alphas based on timeline
    for _, event in ipairs(self.present.timeline) do
        local fade_duration = event.fade_in or self.theme.transitions.default_fade_in
        if self.time >= event.at then
            local elapsed = self.time - event.at
            local alpha = math.min(elapsed / fade_duration, 1.0)
            self.fade_alphas[event.show] = alpha
            self.visible[event.show] = true
        end
    end
end

--- Renders the current frame to the internal canvas.
--- Call this once per frame, then use :getCanvas() to read the result.
function Presenter:render()
    local theme = self.theme
    local w, h = theme.width, theme.height

    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 1)

    -- Draw shader as fullscreen background
    ShaderLoader.send_uniforms(self.shader, self.time, w, h)
    love.graphics.setShader(self.shader)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setShader()

    -- Draw overlays
    local pad = theme.layout.padding_x

    -- Title
    if self.visible.title then
        local a = self.fade_alphas.title

        love.graphics.setFont(self.fonts.koan_number)
        love.graphics.setColor(1, 1, 1, a * 0.5)
        love.graphics.printf(
            string.upper("Koan " .. string.format("%02d", self.koan.order)),
            pad, h * theme.layout.koan_number_y,
            w - pad * 2, "left"
        )

        love.graphics.setFont(self.fonts.title)
        love.graphics.setColor(1, 1, 1, a)
        love.graphics.printf(
            self.koan.title,
            pad, h * theme.layout.title_y,
            w - pad * 2, "left"
        )
    end

    -- Lesson text
    if self.visible.lesson then
        local a = self.fade_alphas.lesson
        love.graphics.setFont(self.fonts.lesson)
        love.graphics.setColor(1, 1, 1, a * 0.85)
        love.graphics.printf(
            self.koan.lesson,
            pad, h * theme.layout.lesson_y,
            w - pad * 2, "left"
        )
    end

    -- Code overlay with dark glass background
    if self.visible.code then
        local a = self.fade_alphas.code
        local code_y = h * theme.layout.code_y
        local code_pad = theme.overlay.code_padding

        -- Extract just the effect function body for display (skip comments)
        local display_code = self:_extract_display_code()

        love.graphics.setFont(self.fonts.code)
        -- getWrap returns (width, wrapped_lines_table) — use #lines for line count
        local _, wrapped = self.fonts.code:getWrap(display_code, w - pad * 2 - code_pad * 2)
        local code_text_h = self.fonts.code:getHeight() * #wrapped
        local box_h = code_text_h + code_pad * 2

        -- Dark glass background
        love.graphics.setColor(
            theme.overlay.code_bg[1],
            theme.overlay.code_bg[2],
            theme.overlay.code_bg[3],
            theme.overlay.code_bg[4] * a
        )
        love.graphics.rectangle("fill", pad, code_y, w - pad * 2, box_h, theme.overlay.code_radius)

        -- Code text
        love.graphics.setColor(1, 1, 1, a * 0.95)
        love.graphics.printf(
            display_code,
            pad + code_pad, code_y + code_pad,
            w - pad * 2 - code_pad * 2, "left"
        )
    end

    -- Concept tags
    if self.visible.concepts and self.koan.concepts then
        local a = self.fade_alphas.concepts
        local tag_y = h * theme.layout.concepts_y
        local tag_x = pad

        love.graphics.setFont(self.fonts.tag)
        for _, concept in ipairs(self.koan.concepts) do
            local tw = self.fonts.tag:getWidth(concept) + theme.overlay.tag_padding_x * 2
            local th = self.fonts.tag:getHeight() + theme.overlay.tag_padding_y * 2

            -- Tag pill background
            love.graphics.setColor(
                theme.overlay.tag_bg[1],
                theme.overlay.tag_bg[2],
                theme.overlay.tag_bg[3],
                theme.overlay.tag_bg[4] * a
            )
            love.graphics.rectangle("fill", tag_x, tag_y, tw, th, theme.overlay.tag_radius)

            -- Tag text
            love.graphics.setColor(1, 1, 1, a * 0.8)
            love.graphics.print(concept, tag_x + theme.overlay.tag_padding_x, tag_y + theme.overlay.tag_padding_y)

            tag_x = tag_x + tw + theme.overlay.tag_gap
        end
    end

    -- Branding watermark
    love.graphics.setFont(self.fonts.branding)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.printf(
        theme.branding,
        pad, h * theme.layout.branding_y,
        w - pad * 2, "left"
    )

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
end

--- Returns the canvas with the current frame rendered.
--- @return Canvas
function Presenter:getCanvas()
    return self.canvas
end

--- Returns true if the presentation has finished.
--- @return boolean
function Presenter:isFinished()
    return self.time >= self.duration
end

--- Extracts a clean code snippet from the puzzle source for overlay display.
--- Strips leading comment blocks, keeps the effect function body only.
--- @return string
function Presenter:_extract_display_code()
    local lines = {}
    local in_body = false
    for line in self.puzzle_source:gmatch("[^\r\n]+") do
        if line:match("^%s*vec4%s+effect") or in_body then
            in_body = true
            table.insert(lines, line)
        end
    end
    if #lines == 0 then
        return self.puzzle_source
    end
    return table.concat(lines, "\n")
end

return Presenter
