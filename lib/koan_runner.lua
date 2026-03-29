local ShaderLoader = require("lib.shader_loader")

local KoanRunner = {}
KoanRunner.__index = KoanRunner

--- Creates a new KoanRunner that loads and manages the koan curriculum.
--- @return KoanRunner
function KoanRunner.new()
    local self = setmetatable({}, KoanRunner)
    self.index = {}
    self.koans = {}
    self.current_index = 1
    self.current_shader = nil
    self.current_koan = nil
    self.shader_error = nil
    self.shader_time = 0
    self.hint_index = 0
    self.show_solution = false
    self.file_modtime = 0
    self.poll_timer = 0

    return self
end

--- Loads the curriculum index and all koan metadata.
--- @return boolean success, string|nil error
function KoanRunner:loadCurriculum()
    local loader = love.filesystem.load("koans/index.lua")
    if not loader then
        return false, "Cannot load koans/index.lua"
    end
    self.index = loader()

    for i, entry in ipairs(self.index) do
        local koan_path = "koans/" .. entry.id .. "/koan.lua"
        local koan_loader = love.filesystem.load(koan_path)
        if koan_loader then
            self.koans[i] = {
                id = entry.id,
                data = koan_loader(),
                shader_path = "koans/" .. entry.id .. "/shader.glsl",
                solution_path = "koans/" .. entry.id .. "/solution.glsl",
            }
        end
    end

    if #self.koans == 0 then
        return false, "No koans found"
    end

    self:loadCurrentKoan()
    return true, nil
end

--- Loads the shader for the current koan and attempts compilation.
function KoanRunner:loadCurrentKoan()
    local koan = self.koans[self.current_index]
    if not koan then return end

    self.current_koan = koan
    self.shader_error = nil
    self.current_shader = nil
    self.shader_time = 0
    self.hint_index = 0
    self.show_solution = false

    local source, read_err = ShaderLoader.read(koan.shader_path)
    if not source then
        self.shader_error = read_err
        return
    end

    local blanks = ShaderLoader.detect_blanks(source)
    if #blanks > 0 then
        self.shader_error = string.format(
            "Fill in %d blank(s) marked with ??? in:\n%s",
            #blanks, koan.shader_path
        )
        return
    end

    local shader, compile_err = ShaderLoader.compile(source)
    if not shader then
        self.shader_error = compile_err
        return
    end

    self.current_shader = shader
    self.file_modtime = ShaderLoader.get_modtime(koan.shader_path) or 0
end

--- Polls for file changes and hot-reloads the shader.
--- @param dt number Delta time
function KoanRunner:update(dt)
    self.shader_time = self.shader_time + dt

    -- Send uniforms to current shader
    if self.current_shader then
        local w, h = love.graphics.getDimensions()
        ShaderLoader.send_uniforms(self.current_shader, self.shader_time, w, h)
    end

    -- Poll for file changes every 0.5s
    self.poll_timer = self.poll_timer + dt
    if self.poll_timer >= 0.5 and self.current_koan then
        self.poll_timer = 0
        local new_modtime = ShaderLoader.get_modtime(self.current_koan.shader_path) or 0
        if new_modtime > self.file_modtime then
            self.file_modtime = new_modtime
            print("File changed, reloading shader...")
            self:loadCurrentKoan()
        end
    end
end

--- Draws the current koan's shader and UI.
function KoanRunner:draw()
    local w, h = love.graphics.getDimensions()
    local koan = self.current_koan

    if not koan then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("No koans loaded", 0, h / 2, w, "center")
        return
    end

    -- Draw shader output if compiled
    if self.current_shader then
        love.graphics.setShader(self.current_shader)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setShader()
    end

    -- Draw info overlay at top
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, w, 80)

    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.printf(
        string.format("Koan %d/%d", self.current_index, #self.koans),
        10, 8, w - 20, "left"
    )

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(koan.data.title, 10, 28, w - 20, "left")

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.printf(
        "[H]int  [S]olution  [←][→] navigate  [Esc] quit",
        10, 52, w - 20, "left"
    )

    -- Draw error panel if shader failed
    if self.shader_error then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 20, 100, w - 40, h - 200)

        love.graphics.setColor(1, 0.4, 0.4)
        love.graphics.printf(self.shader_error, 40, 120, w - 80, "left")

        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.printf(
            "Edit the .glsl file in your text editor.\nThe shader will hot-reload when you save.",
            40, h - 160, w - 80, "left"
        )
    end

    -- Draw hint panel
    if self.hint_index > 0 and koan.data.hints then
        local hint = koan.data.hints[self.hint_index]
        if hint then
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.rectangle("fill", 20, h - 100, w - 40, 60)
            love.graphics.setColor(1, 0.9, 0.4)
            love.graphics.printf(
                "Hint " .. self.hint_index .. ": " .. hint,
                40, h - 88, w - 80, "left"
            )
        end
    end

    -- Draw solution overlay
    if self.show_solution then
        local source = ShaderLoader.read(koan.solution_path) or "Solution not found"
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", 20, 100, w - 40, h - 200)
        love.graphics.setColor(0.4, 1, 0.6)
        love.graphics.printf("SOLUTION:", 40, 120, w - 80, "left")
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.printf(source, 40, 150, w - 80, "left")
    end
end

--- Handles keypresses for learn mode navigation.
--- @param key string The key pressed
function KoanRunner:keypressed(key)
    if key == "right" or key == "n" then
        if self.current_index < #self.koans then
            self.current_index = self.current_index + 1
            self:loadCurrentKoan()
        end
    elseif key == "left" or key == "p" then
        if self.current_index > 1 then
            self.current_index = self.current_index - 1
            self:loadCurrentKoan()
        end
    elseif key == "h" then
        if self.current_koan and self.current_koan.data.hints then
            self.hint_index = self.hint_index + 1
            if self.hint_index > #self.current_koan.data.hints then
                self.hint_index = 0
            end
        end
    elseif key == "s" then
        self.show_solution = not self.show_solution
    elseif key == "r" then
        self:loadCurrentKoan()
    end
end

return KoanRunner
