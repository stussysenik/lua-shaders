# Lua Shader Koans — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a LÖVE-based progressive shader koan system with Instagram story export pipeline.

**Architecture:** Modular monolith — single LÖVE 11.5 project with clean internal module boundaries. `lib/` contains engine modules (shader_loader, koan_runner, presenter, recorder, exporter). `koans/` contains pure-data koan folders. `themes/` defines presentation layouts. Modules are composed in `main.lua` via a mode router (learn vs present).

**Tech Stack:** LÖVE 11.5 (Lua game framework with GLSL shaders), ffmpeg (frame → GIF/MP4), LuaJIT (LÖVE's embedded runtime)

**Spec:** `docs/superpowers/specs/2026-03-29-lua-shader-koans-design.md`

---

## File Map

| File | Responsibility |
|------|---------------|
| `conf.lua` | LÖVE window config, module toggles, identity |
| `main.lua` | Entry point, arg parsing, mode router |
| `lib/shader_loader.lua` | Read .glsl, prepend boilerplate, compile, detect blanks |
| `lib/koan_runner.lua` | Load koan folders, validate, hot-reload, learn mode UI |
| `lib/presenter.lua` | 9:16 canvas, run solution shader, render text overlays per timeline |
| `lib/recorder.lua` | Fixed-timestep frame capture to PNG sequence |
| `lib/exporter.lua` | ffmpeg wrapper: PNGs → GIF + MP4 |
| `themes/instagram.lua` | 1080×1920 layout config, fonts, overlay styles |
| `koans/index.lua` | Curriculum ordering, chapter/koan registry |
| `koans/01_coordinates/koan.lua` | First koan metadata + lesson |
| `koans/01_coordinates/shader.glsl` | First koan puzzle (with `???`) |
| `koans/01_coordinates/solution.glsl` | First koan completed shader |
| `koans/01_coordinates/present.lua` | First koan presentation timeline |
| `.gitignore` | Ignore export/, .superpowers/ |

---

### Task 1: Project Scaffold + Install LÖVE

**Files:**
- Create: `conf.lua`
- Create: `main.lua`
- Create: `.gitignore`

- [ ] **Step 1: Install LÖVE**

Run: `brew install love`
Expected: LÖVE 11.x installed at `/opt/homebrew/bin/love`

Verify: `love --version`
Expected output contains: `LOVE 11`

- [ ] **Step 2: Create `.gitignore`**

```gitignore
export/
.superpowers/
*.love
```

- [ ] **Step 3: Create `conf.lua`**

```lua
function love.conf(t)
    t.identity = "lua-shaders"
    t.version = "11.5"

    t.window.title = "Lua Shader Koans"
    t.window.width = 540
    t.window.height = 960
    t.window.resizable = true
    t.window.vsync = 0
    t.window.highdpi = true

    t.modules.audio = false
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.sound = false
    t.modules.touch = false
    t.modules.video = false
end
```

The default window is 540×960 (9:16 at half resolution) for development. Presentation mode renders to a 1080×1920 off-screen canvas regardless of window size.

- [ ] **Step 4: Create minimal `main.lua`**

```lua
local mode = "learn"
local koan_arg = nil

function love.load(args)
    for i, v in ipairs(args) do
        if v == "--present" then
            mode = "present"
            koan_arg = args[i + 1]
        end
    end

    love.graphics.setBackgroundColor(0.05, 0.05, 0.08)
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        "Lua Shader Koans\nMode: " .. mode,
        0, love.graphics.getHeight() / 2 - 20,
        love.graphics.getWidth(), "center"
    )
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
```

- [ ] **Step 5: Verify the scaffold runs**

Run: `cd /Users/s3nik/Desktop/lua-shaders && love .`
Expected: Window opens showing "Lua Shader Koans / Mode: learn". Press Escape to quit.

Run: `love . --present 01_coordinates`
Expected: Window shows "Mode: present".

- [ ] **Step 6: Commit**

```bash
git add conf.lua main.lua .gitignore
git commit -m "feat: project scaffold with LÖVE config and mode router"
```

---

### Task 2: Shader Loader Module

**Files:**
- Create: `lib/shader_loader.lua`

- [ ] **Step 1: Create `lib/` directory**

Run: `mkdir -p lib`

- [ ] **Step 2: Write `lib/shader_loader.lua`**

```lua
local ShaderLoader = {}

--- LÖVE shader boilerplate prepended to all .glsl files.
--- Provides the `time` and `resolution` uniforms that koans expect.
local BOILERPLATE = [[
extern number time;
extern vec2 resolution;
]]

--- Reads a .glsl file and returns its raw content.
--- @param path string Path relative to project root (e.g., "koans/01_coordinates/shader.glsl")
--- @return string|nil content, string|nil error
function ShaderLoader.read(path)
    local info = love.filesystem.getInfo(path)
    if not info then
        return nil, "File not found: " .. path
    end
    local content, err = love.filesystem.read(path)
    if not content then
        return nil, "Failed to read " .. path .. ": " .. tostring(err)
    end
    return content, nil
end

--- Detects ??? blank markers in shader source code.
--- @param source string GLSL source code
--- @return table blanks List of {line=number, col=number} for each blank
function ShaderLoader.detect_blanks(source)
    local blanks = {}
    local line_num = 0
    for line in source:gmatch("[^\r\n]+") do
        line_num = line_num + 1
        local col = 1
        while true do
            local start = line:find("%?%?%?", col)
            if not start then break end
            table.insert(blanks, { line = line_num, col = start })
            col = start + 3
        end
    end
    return blanks
end

--- Compiles a GLSL string into a LÖVE Shader object.
--- Prepends boilerplate (time, resolution uniforms).
--- @param source string GLSL source code (the effect function body)
--- @return Shader|nil shader, string|nil error
function ShaderLoader.compile(source)
    local full_source = BOILERPLATE .. source
    local ok, shader = pcall(love.graphics.newShader, full_source)
    if not ok then
        return nil, tostring(shader)
    end
    return shader, nil
end

--- Loads a .glsl file, reads it, and compiles it.
--- @param path string Path to .glsl file
--- @return Shader|nil shader, table blanks, string|nil error
function ShaderLoader.load(path)
    local source, err = ShaderLoader.read(path)
    if not source then
        return nil, {}, err
    end

    local blanks = ShaderLoader.detect_blanks(source)

    if #blanks > 0 then
        return nil, blanks, "Shader has " .. #blanks .. " unfilled blank(s)"
    end

    local shader, compile_err = ShaderLoader.compile(source)
    if not shader then
        return nil, blanks, compile_err
    end

    return shader, blanks, nil
end

--- Sends the standard uniforms (time, resolution) to a compiled shader.
--- @param shader Shader The compiled LÖVE shader
--- @param t number Current time in seconds
--- @param w number Canvas/screen width
--- @param h number Canvas/screen height
function ShaderLoader.send_uniforms(shader, t, w, h)
    if shader:hasUniform("time") then
        shader:send("time", t)
    end
    if shader:hasUniform("resolution") then
        shader:send("resolution", { w, h })
    end
end

--- Returns the modification time of a file (for hot-reload polling).
--- @param path string Path to file
--- @return number|nil modtime Unix timestamp, or nil if file doesn't exist
function ShaderLoader.get_modtime(path)
    local info = love.filesystem.getInfo(path)
    return info and info.modtime
end

return ShaderLoader
```

- [ ] **Step 3: Write an inline verification shader**

Create a temporary test by updating `main.lua` to load and run a test shader. Add after `love.graphics.setBackgroundColor`:

```lua
local ShaderLoader = require("lib.shader_loader")

local test_shader = nil
local test_time = 0

function love.load(args)
    for i, v in ipairs(args) do
        if v == "--present" then
            mode = "present"
            koan_arg = args[i + 1]
        end
    end

    love.graphics.setBackgroundColor(0.05, 0.05, 0.08)

    -- Test: compile a simple shader
    local source = [[
        extern number time;
        extern vec2 resolution;

        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
            vec2 uv = screen_coords / love_ScreenSize.xy;
            return vec4(uv.x, uv.y, 0.5 + 0.5 * sin(time), 1.0);
        }
    ]]
    local shader, err = ShaderLoader.compile(source)
    if shader then
        test_shader = shader
    else
        print("Shader compile error: " .. err)
    end

    -- Test: blank detection
    local blanks = ShaderLoader.detect_blanks("vec2 uv = ???;\nreturn vec4(uv, ???, 1.0);")
    assert(#blanks == 2, "Expected 2 blanks, got " .. #blanks)
    assert(blanks[1].line == 1 and blanks[2].line == 2, "Blank line numbers wrong")
    print("ShaderLoader tests passed!")
end

function love.update(dt)
    test_time = test_time + dt
end

function love.draw()
    if test_shader then
        local w, h = love.graphics.getDimensions()
        ShaderLoader.send_uniforms(test_shader, test_time, w, h)
        love.graphics.setShader(test_shader)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setShader()
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            "Lua Shader Koans\nMode: " .. mode,
            0, love.graphics.getHeight() / 2 - 20,
            love.graphics.getWidth(), "center"
        )
    end
end
```

- [ ] **Step 4: Verify shader loader works**

Run: `cd /Users/s3nik/Desktop/lua-shaders && love .`
Expected: Window shows an animated UV gradient (red/green with pulsing blue). Console prints "ShaderLoader tests passed!".

- [ ] **Step 5: Revert `main.lua` to clean state**

Revert `main.lua` back to the minimal version from Task 1, Step 4 (remove the inline test). The shader loader is verified; `main.lua` will integrate it properly in later tasks.

- [ ] **Step 6: Commit**

```bash
git add lib/shader_loader.lua
git commit -m "feat: add shader loader with compile, blank detection, and uniform sending"
```

---

### Task 3: First Koan Content

**Files:**
- Create: `koans/index.lua`
- Create: `koans/01_coordinates/koan.lua`
- Create: `koans/01_coordinates/shader.glsl`
- Create: `koans/01_coordinates/solution.glsl`
- Create: `koans/01_coordinates/present.lua`

- [ ] **Step 1: Create directory structure**

Run: `mkdir -p koans/01_coordinates`

- [ ] **Step 2: Create `koans/index.lua`**

```lua
--- Curriculum index: defines the order koans are presented.
--- Each entry maps a folder name to its chapter and position.
return {
    { id = "01_coordinates", chapter = "Coordinates & UV Space", order = 1 },
}
```

- [ ] **Step 3: Create `koans/01_coordinates/koan.lua`**

```lua
--- Koan: The Canvas is a Map
--- Chapter 1: Coordinates & UV Space
---
--- Every pixel on the screen has a position. In shader land, we normalize
--- these positions to the range 0.0–1.0 so our math works at any resolution.
--- This normalized position is called a UV coordinate.
return {
    title = "The Canvas is a Map",
    chapter = "coordinates",
    order = 1,
    difficulty = "beginner",

    lesson = [[
Every pixel has an address. In shader land, we normalize
these to 0.0–1.0. The bottom-left is (0,0), the top-right
is (1,1). This is your UV coordinate system.

To get UV coordinates, divide the pixel's screen position
by the total screen size. The result: a smooth gradient
where x-position becomes red and y-position becomes green.]],

    hints = {
        "What if x position = red, y position = green?",
        "screen_coords / love_ScreenSize.xy gives you 0→1",
    },

    concepts = { "normalization", "coordinate systems", "UV mapping" },
}
```

- [ ] **Step 4: Create `koans/01_coordinates/shader.glsl`**

```glsl
// Koan 01: The Canvas is a Map
//
// Every pixel has a screen position (screen_coords).
// The screen has a total size (love_ScreenSize.xy).
//
// To normalize the position to 0.0–1.0, divide position by size.
// Then map x → red and y → green to visualize the coordinate system.
//
// Fill in the ??? to compute the UV coordinates.

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = ???;
    return vec4(uv.x, uv.y, 0.0, 1.0);
}
```

- [ ] **Step 5: Create `koans/01_coordinates/solution.glsl`**

```glsl
// Koan 01: The Canvas is a Map — Solution
//
// Dividing screen_coords by love_ScreenSize.xy normalizes
// pixel positions to the 0→1 range. This is UV mapping:
// the foundation of every shader effect.

extern number time;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    return vec4(uv.x, uv.y, 0.5 + 0.5 * sin(time * 2.0), 1.0);
}
```

Note: The solution adds a time-animated blue channel for visual interest in presentation mode.

- [ ] **Step 6: Create `koans/01_coordinates/present.lua`**

```lua
--- Presentation timeline for Koan 01: The Canvas is a Map
--- Total duration: 20 seconds at 30fps
return {
    duration = 20,
    fps = 30,

    timeline = {
        { at = 0,  show = "title",    fade_in = 0.5 },
        { at = 3,  show = "lesson",   fade_in = 0.8 },
        { at = 9,  show = "code",     fade_in = 0.5 },
        { at = 15, show = "concepts", fade_in = 0.5 },
    },
}
```

- [ ] **Step 7: Verify koan files load**

Run: `cd /Users/s3nik/Desktop/lua-shaders && love -c "local k = dofile('koans/01_coordinates/koan.lua'); print(k.title)"`

Actually, LÖVE doesn't support `-c`. Verify by adding a quick print in `main.lua`'s `love.load`:

Temporarily add to `love.load` in `main.lua`:
```lua
    local index = love.filesystem.load("koans/index.lua")()
    print("Curriculum entries: " .. #index)
    print("First koan: " .. index[1].id)
    local koan = love.filesystem.load("koans/01_coordinates/koan.lua")()
    print("Koan title: " .. koan.title)
    print("Koan loaded successfully!")
```

Run: `love .`
Expected console output:
```
Curriculum entries: 1
First koan: 01_coordinates
Koan title: The Canvas is a Map
Koan loaded successfully!
```

Remove the temporary prints after verification.

- [ ] **Step 8: Commit**

```bash
git add koans/
git commit -m "feat: add first koan (01_coordinates) with curriculum index"
```

---

### Task 4: Instagram Theme

**Files:**
- Create: `themes/instagram.lua`

- [ ] **Step 1: Create themes directory**

Run: `mkdir -p themes`

- [ ] **Step 2: Create `themes/instagram.lua`**

```lua
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
```

- [ ] **Step 3: Commit**

```bash
git add themes/
git commit -m "feat: add Instagram story theme (1080x1920)"
```

---

### Task 5: Presenter Module

**Files:**
- Create: `lib/presenter.lua`
- Modify: `main.lua`

This is the core presentation engine: renders a koan's solution shader to a 9:16 canvas with text overlays driven by the timeline.

- [ ] **Step 1: Create `lib/presenter.lua`**

```lua
local ShaderLoader = require("lib.shader_loader")

local Presenter = {}
Presenter.__index = Presenter

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

    -- Load and compile solution shader
    local solution_path = koan_path .. "/solution.glsl"
    local source, read_err = ShaderLoader.read(solution_path)
    if not source then
        return nil, read_err
    end
    local shader, compile_err = ShaderLoader.compile(source)
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

    -- Precompute timeline events sorted by time
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

    -- Dummy image for drawing fullscreen shader quad
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

    -- Code overlay with dark background
    if self.visible.code then
        local a = self.fade_alphas.code
        local code_y = h * theme.layout.code_y
        local code_pad = theme.overlay.code_padding

        -- Extract just the effect function body for display (skip comments)
        local display_code = self:_extract_display_code()

        love.graphics.setFont(self.fonts.code)
        local code_text_h = self.fonts.code:getHeight() * select(2, self.fonts.code:getWrap(display_code, w - pad * 2 - code_pad * 2))
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

    -- Branding
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
--- Strips leading comment blocks, keeps the effect function.
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
```

- [ ] **Step 2: Wire presenter into `main.lua` for present mode**

Replace `main.lua` entirely:

```lua
local ShaderLoader = require("lib.shader_loader")

local mode = "learn"
local koan_arg = nil
local presenter = nil

function love.load(args)
    for i, v in ipairs(args) do
        if v == "--present" then
            mode = "present"
            koan_arg = args[i + 1]
        end
    end

    love.graphics.setBackgroundColor(0.05, 0.05, 0.08)

    if mode == "present" and koan_arg then
        local Presenter = require("lib.presenter")
        local theme = love.filesystem.load("themes/instagram.lua")()
        local koan_path = "koans/" .. koan_arg

        local p, err = Presenter.new(koan_path, theme)
        if p then
            presenter = p
            print("Presenting: " .. koan_arg)
        else
            print("Error loading koan: " .. err)
        end
    end
end

function love.update(dt)
    if presenter then
        presenter:update(dt)
    end
end

function love.draw()
    if presenter then
        presenter:render()
        -- Draw the 9:16 canvas scaled to fit the window
        local canvas = presenter:getCanvas()
        local win_w, win_h = love.graphics.getDimensions()
        local scale = math.min(win_w / canvas:getWidth(), win_h / canvas:getHeight())
        local ox = (win_w - canvas:getWidth() * scale) / 2
        local oy = (win_h - canvas:getHeight() * scale) / 2
        love.graphics.draw(canvas, ox, oy, 0, scale, scale)
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            "Lua Shader Koans\nMode: " .. mode .. "\n\nRun with --present 01_coordinates",
            0, love.graphics.getHeight() / 2 - 40,
            love.graphics.getWidth(), "center"
        )
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
```

- [ ] **Step 3: Verify presenter renders the first koan**

Run: `cd /Users/s3nik/Desktop/lua-shaders && love . --present 01_coordinates`
Expected: Window shows the UV gradient shader as a 9:16 canvas. Title "The Canvas is a Map" fades in at top, lesson text appears after 3s, code snippet after 9s, concept tags after 15s.

- [ ] **Step 4: Commit**

```bash
git add lib/presenter.lua main.lua
git commit -m "feat: add presenter module with timeline-driven overlays"
```

---

### Task 6: Recorder Module

**Files:**
- Create: `lib/recorder.lua`

- [ ] **Step 1: Create `lib/recorder.lua`**

```lua
local Recorder = {}
Recorder.__index = Recorder

--- Creates a new Recorder that captures frames from a Presenter.
--- Frames are saved as PNGs to the LÖVE save directory.
--- @param presenter table Presenter instance
--- @param output_name string Name for the output (e.g., "01_coordinates")
--- @return Recorder
function Recorder.new(presenter, output_name)
    local self = setmetatable({}, Recorder)
    self.presenter = presenter
    self.output_name = output_name
    self.frame_dir = "frames/" .. output_name
    self.frame_count = 0
    self.total_frames = math.ceil(presenter.duration * presenter.fps)
    self.dt = 1.0 / presenter.fps
    self.finished = false

    -- Create output directory in save directory
    love.filesystem.createDirectory(self.frame_dir)

    print(string.format(
        "Recording: %s (%d frames, %ds at %dfps)",
        output_name, self.total_frames, presenter.duration, presenter.fps
    ))

    return self
end

--- Captures one frame. Call this in love.update().
--- Uses fixed timestep (not wall clock) for deterministic output.
--- @return boolean done True when all frames have been captured
function Recorder:captureFrame()
    if self.finished then
        return true
    end

    -- Advance presenter by fixed dt
    self.presenter:update(self.dt)
    self.presenter:render()

    -- Capture the canvas to PNG
    local canvas = self.presenter:getCanvas()
    local image_data = canvas:newImageData()
    local filename = string.format("%s/frame_%04d.png", self.frame_dir, self.frame_count)
    image_data:encode("png", filename)

    self.frame_count = self.frame_count + 1

    -- Progress reporting every 30 frames
    if self.frame_count % 30 == 0 or self.frame_count == self.total_frames then
        print(string.format(
            "  Frame %d/%d (%.0f%%)",
            self.frame_count, self.total_frames,
            (self.frame_count / self.total_frames) * 100
        ))
    end

    if self.frame_count >= self.total_frames then
        self.finished = true
        print("Recording complete: " .. self.total_frames .. " frames")
        return true
    end

    return false
end

--- Returns the directory where frames were saved (absolute path).
--- @return string
function Recorder:getFrameDir()
    return love.filesystem.getSaveDirectory() .. "/" .. self.frame_dir
end

--- Returns progress as a fraction 0→1.
--- @return number
function Recorder:getProgress()
    return self.frame_count / self.total_frames
end

return Recorder
```

- [ ] **Step 2: Wire recorder into `main.lua`**

Update `main.lua` — add recorder support for present mode. Replace the full file:

```lua
local ShaderLoader = require("lib.shader_loader")

local mode = "learn"
local koan_arg = nil
local presenter = nil
local recorder = nil

function love.load(args)
    for i, v in ipairs(args) do
        if v == "--present" then
            mode = "present"
            koan_arg = args[i + 1]
        end
    end

    love.graphics.setBackgroundColor(0.05, 0.05, 0.08)

    if mode == "present" and koan_arg then
        local Presenter = require("lib.presenter")
        local Recorder = require("lib.recorder")
        local theme = love.filesystem.load("themes/instagram.lua")()
        local koan_path = "koans/" .. koan_arg

        local p, err = Presenter.new(koan_path, theme)
        if p then
            presenter = p
            recorder = Recorder.new(p, koan_arg)
            print("Presenting: " .. koan_arg)
        else
            print("Error loading koan: " .. err)
            love.event.quit(1)
        end
    end
end

function love.update(dt)
    if recorder and not recorder.finished then
        -- In recording mode, use fixed timestep (ignore wall clock dt)
        local done = recorder:captureFrame()
        if done then
            print("Frames saved to: " .. recorder:getFrameDir())
            -- Continue to exporter in next task; for now, quit
            love.event.quit()
        end
    elseif presenter then
        presenter:update(dt)
    end
end

function love.draw()
    if presenter then
        -- In non-recording mode, render live; in recording mode, show last frame
        if not recorder or recorder.finished then
            presenter:render()
        end
        local canvas = presenter:getCanvas()
        local win_w, win_h = love.graphics.getDimensions()
        local scale = math.min(win_w / canvas:getWidth(), win_h / canvas:getHeight())
        local ox = (win_w - canvas:getWidth() * scale) / 2
        local oy = (win_h - canvas:getHeight() * scale) / 2
        love.graphics.draw(canvas, ox, oy, 0, scale, scale)

        -- Show progress bar during recording
        if recorder and not recorder.finished then
            local progress = recorder:getProgress()
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
            love.graphics.rectangle("fill", 0, win_h - 4, win_w, 4)
            love.graphics.setColor(0.3, 0.8, 0.4, 1)
            love.graphics.rectangle("fill", 0, win_h - 4, win_w * progress, 4)
            love.graphics.setColor(1, 1, 1, 1)
        end
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            "Lua Shader Koans\nMode: " .. mode .. "\n\nRun with --present 01_coordinates",
            0, love.graphics.getHeight() / 2 - 40,
            love.graphics.getWidth(), "center"
        )
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
```

- [ ] **Step 3: Verify recording works**

Run: `cd /Users/s3nik/Desktop/lua-shaders && love . --present 01_coordinates`
Expected console output:
```
Recording: 01_coordinates (600 frames, 20s at 30fps)
Presenting: 01_coordinates
  Frame 30/600 (5%)
  ...
  Frame 600/600 (100%)
Recording complete: 600 frames
Frames saved to: /Users/s3nik/Library/Application Support/LOVE/lua-shaders/frames/01_coordinates
```

Verify frames exist:
Run: `ls ~/Library/Application\ Support/LOVE/lua-shaders/frames/01_coordinates/ | head -5`
Expected: `frame_0000.png frame_0001.png frame_0002.png ...`

- [ ] **Step 4: Commit**

```bash
git add lib/recorder.lua main.lua
git commit -m "feat: add recorder module with fixed-timestep frame capture"
```

---

### Task 7: Exporter Module

**Files:**
- Create: `lib/exporter.lua`
- Modify: `main.lua`

- [ ] **Step 1: Create `lib/exporter.lua`**

```lua
local Exporter = {}

--- Exports a PNG frame sequence to GIF and MP4 using ffmpeg.
--- @param frame_dir string Absolute path to directory containing frame_NNNN.png files
--- @param output_name string Base name for output files (e.g., "01_coordinates")
--- @param fps number Frame rate
--- @return boolean success, string|nil error
function Exporter.export(frame_dir, output_name, fps)
    -- Ensure export directory exists in the project directory
    local project_dir = love.filesystem.getSourceBaseDirectory()
    if love.filesystem.getSource() ~= project_dir then
        project_dir = love.filesystem.getSource()
    end
    local export_dir = project_dir .. "/export"
    os.execute('mkdir -p "' .. export_dir .. '"')

    local frame_pattern = frame_dir .. "/frame_%04d.png"
    local gif_path = export_dir .. "/" .. output_name .. ".gif"
    local mp4_path = export_dir .. "/" .. output_name .. ".mp4"

    -- Export MP4 (H.264, yuv420p for Instagram compatibility)
    print("Exporting MP4...")
    local mp4_cmd = string.format(
        'ffmpeg -y -framerate %d -i "%s" -c:v libx264 -pix_fmt yuv420p -crf 18 "%s" 2>&1',
        fps, frame_pattern, mp4_path
    )
    local mp4_ok = os.execute(mp4_cmd)
    if not mp4_ok then
        return false, "ffmpeg MP4 export failed"
    end
    print("  MP4: " .. mp4_path)

    -- Export GIF (two-pass for optimized palette)
    print("Exporting GIF...")
    local palette_path = frame_dir .. "/palette.png"
    local palette_cmd = string.format(
        'ffmpeg -y -framerate %d -i "%s" -vf "fps=%d,scale=540:-1:flags=lanczos,palettegen=max_colors=128" "%s" 2>&1',
        fps, frame_pattern, fps, palette_path
    )
    local palette_ok = os.execute(palette_cmd)
    if not palette_ok then
        return false, "ffmpeg palette generation failed"
    end

    local gif_cmd = string.format(
        'ffmpeg -y -framerate %d -i "%s" -i "%s" -lavfi "fps=%d,scale=540:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" "%s" 2>&1',
        fps, frame_pattern, palette_path, fps, gif_path
    )
    local gif_ok = os.execute(gif_cmd)
    if not gif_ok then
        return false, "ffmpeg GIF export failed"
    end
    print("  GIF: " .. gif_path)

    -- Clean up frame PNGs
    print("Cleaning up frames...")
    os.execute('rm -rf "' .. frame_dir .. '"')

    return true, nil
end

return Exporter
```

- [ ] **Step 2: Wire exporter into `main.lua` recording completion**

In `main.lua`, update the `love.update` function. Replace the recording-done block:

Find this code in `love.update`:
```lua
        local done = recorder:captureFrame()
        if done then
            print("Frames saved to: " .. recorder:getFrameDir())
            -- Continue to exporter in next task; for now, quit
            love.event.quit()
        end
```

Replace with:
```lua
        local done = recorder:captureFrame()
        if done then
            local Exporter = require("lib.exporter")
            local ok, err = Exporter.export(
                recorder:getFrameDir(),
                koan_arg,
                presenter.fps
            )
            if ok then
                print("Export complete!")
            else
                print("Export error: " .. tostring(err))
            end
            love.event.quit()
        end
```

- [ ] **Step 3: Verify full pipeline: present → record → export**

Run: `cd /Users/s3nik/Desktop/lua-shaders && love . --present 01_coordinates`
Expected console output ends with:
```
Exporting MP4...
  MP4: /Users/s3nik/Desktop/lua-shaders/export/01_coordinates.mp4
Exporting GIF...
  GIF: /Users/s3nik/Desktop/lua-shaders/export/01_coordinates.gif
Cleaning up frames...
Export complete!
```

Verify:
Run: `ls -la export/`
Expected: `01_coordinates.gif` and `01_coordinates.mp4` exist.

Run: `open export/01_coordinates.gif`
Expected: Animated GIF shows UV gradient with title, lesson, code, and concept tags fading in over 20 seconds.

- [ ] **Step 4: Commit**

```bash
git add lib/exporter.lua main.lua
git commit -m "feat: add exporter module (ffmpeg GIF + MP4 pipeline)"
```

---

### Task 8: Koan Runner (Learn Mode)

**Files:**
- Create: `lib/koan_runner.lua`
- Modify: `main.lua`

- [ ] **Step 1: Create `lib/koan_runner.lua`**

```lua
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
```

- [ ] **Step 2: Wire koan runner into `main.lua` for learn mode**

Update `main.lua`. Replace the full file:

```lua
local ShaderLoader = require("lib.shader_loader")

local mode = "learn"
local koan_arg = nil
local presenter = nil
local recorder = nil
local runner = nil

function love.load(args)
    for i, v in ipairs(args) do
        if v == "--present" then
            mode = "present"
            koan_arg = args[i + 1]
        end
    end

    love.graphics.setBackgroundColor(0.05, 0.05, 0.08)

    if mode == "present" and koan_arg then
        local Presenter = require("lib.presenter")
        local Recorder = require("lib.recorder")
        local theme = love.filesystem.load("themes/instagram.lua")()
        local koan_path = "koans/" .. koan_arg

        local p, err = Presenter.new(koan_path, theme)
        if p then
            presenter = p
            recorder = Recorder.new(p, koan_arg)
            print("Presenting: " .. koan_arg)
        else
            print("Error loading koan: " .. err)
            love.event.quit(1)
        end
    elseif mode == "learn" then
        local KoanRunner = require("lib.koan_runner")
        runner = KoanRunner.new()
        local ok, err = runner:loadCurriculum()
        if ok then
            print("Loaded " .. #runner.koans .. " koan(s)")
            print("Edit shader files in your text editor. They hot-reload on save.")
        else
            print("Error: " .. err)
        end
    end
end

function love.update(dt)
    if recorder and not recorder.finished then
        local done = recorder:captureFrame()
        if done then
            local Exporter = require("lib.exporter")
            local ok, err = Exporter.export(
                recorder:getFrameDir(),
                koan_arg,
                presenter.fps
            )
            if ok then
                print("Export complete!")
            else
                print("Export error: " .. tostring(err))
            end
            love.event.quit()
        end
    elseif presenter then
        presenter:update(dt)
    elseif runner then
        runner:update(dt)
    end
end

function love.draw()
    if presenter then
        if not recorder or recorder.finished then
            presenter:render()
        end
        local canvas = presenter:getCanvas()
        local win_w, win_h = love.graphics.getDimensions()
        local scale = math.min(win_w / canvas:getWidth(), win_h / canvas:getHeight())
        local ox = (win_w - canvas:getWidth() * scale) / 2
        local oy = (win_h - canvas:getHeight() * scale) / 2
        love.graphics.draw(canvas, ox, oy, 0, scale, scale)

        if recorder and not recorder.finished then
            local progress = recorder:getProgress()
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
            love.graphics.rectangle("fill", 0, win_h - 4, win_w, 4)
            love.graphics.setColor(0.3, 0.8, 0.4, 1)
            love.graphics.rectangle("fill", 0, win_h - 4, win_w * progress, 4)
            love.graphics.setColor(1, 1, 1, 1)
        end
    elseif runner then
        runner:draw()
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            "Lua Shader Koans\n\nlove . --learn\nlove . --present 01_coordinates",
            0, love.graphics.getHeight() / 2 - 40,
            love.graphics.getWidth(), "center"
        )
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif runner then
        runner:keypressed(key)
    end
end
```

- [ ] **Step 3: Verify learn mode works**

Run: `cd /Users/s3nik/Desktop/lua-shaders && love .`
Expected: Window shows koan title "The Canvas is a Map" at top, with an error panel explaining there are unfilled blanks. Message tells you to edit the .glsl file.

Test hot-reload: Open `koans/01_coordinates/shader.glsl` in a text editor, replace `???` with `screen_coords / love_ScreenSize.xy`, save. The window should automatically show the UV gradient within 0.5 seconds.

Test hints: Press `H` — shows first hint. Press `H` again — shows second hint. Press `H` again — hides hints.

Test solution: Press `S` — shows solution overlay. Press `S` again — hides it.

- [ ] **Step 4: Commit**

```bash
git add lib/koan_runner.lua main.lua
git commit -m "feat: add koan runner with hot-reload and learn mode UI"
```

---

### Task 9: Add Remaining Chapter 1 Koans

**Files:**
- Create: `koans/01_coordinates_b/` (aspect ratio)
- Create: `koans/01_coordinates_c/` (centering)
- Create: `koans/01_coordinates_d/` (remapping)
- Modify: `koans/index.lua`

- [ ] **Step 1: Create `koans/01_coordinates_b/` — Aspect Ratio**

Create directory: `mkdir -p koans/01_coordinates_b`

`koans/01_coordinates_b/koan.lua`:
```lua
--- Koan: The Stretch Problem
--- Chapter 1: Coordinates & UV Space
---
--- Raw UV coordinates stretch when the window isn't square.
--- To get perfect circles and undistorted shapes, we need
--- to correct for the aspect ratio.
return {
    title = "The Stretch Problem",
    chapter = "coordinates",
    order = 2,
    difficulty = "beginner",

    lesson = [[
When the screen isn't square, UV coordinates stretch.
A circle becomes an oval. To fix this, multiply the
x-coordinate by the aspect ratio (width / height).

This gives you a coordinate system where 1 unit
in x equals 1 unit in y — no distortion.]],

    hints = {
        "aspect ratio = width / height",
        "Multiply uv.x by the aspect ratio after centering",
    },

    concepts = { "aspect ratio", "distortion correction", "proportional coordinates" },
}
```

`koans/01_coordinates_b/shader.glsl`:
```glsl
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
```

`koans/01_coordinates_b/solution.glsl`:
```glsl
// Koan 01b: The Stretch Problem — Solution

extern number time;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    uv = uv - 0.5;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;
    float d = length(uv);
    float pulse = 0.3 + 0.02 * sin(time * 3.0);
    float circle = smoothstep(pulse, pulse - 0.01, d);
    return vec4(vec3(circle), 1.0);
}
```

`koans/01_coordinates_b/present.lua`:
```lua
return {
    duration = 18,
    fps = 30,
    timeline = {
        { at = 0,  show = "title",    fade_in = 0.5 },
        { at = 2,  show = "lesson",   fade_in = 0.8 },
        { at = 8,  show = "code",     fade_in = 0.5 },
        { at = 14, show = "concepts", fade_in = 0.5 },
    },
}
```

- [ ] **Step 2: Create `koans/01_coordinates_c/` — Centering**

Create directory: `mkdir -p koans/01_coordinates_c`

`koans/01_coordinates_c/koan.lua`:
```lua
--- Koan: Moving the Origin
--- Chapter 1: Coordinates & UV Space
---
--- By default, (0,0) is at the bottom-left corner.
--- For many effects (circles, rotations, radial patterns),
--- we want (0,0) at the center of the screen.
return {
    title = "Moving the Origin",
    chapter = "coordinates",
    order = 3,
    difficulty = "beginner",

    lesson = [[
By default, UV (0,0) is at the corner. But most interesting
effects need the origin at the center. Subtracting 0.5 from
UV coordinates shifts the range from 0→1 to -0.5→+0.5.

Now the center of the screen is (0,0) and distance from
center gives you radial patterns.]],

    hints = {
        "Subtract 0.5 from both x and y to center",
        "abs() gives you distance from the center axis",
    },

    concepts = { "origin translation", "centered coordinates", "radial distance" },
}
```

`koans/01_coordinates_c/shader.glsl`:
```glsl
// Koan 01c: Moving the Origin
//
// Shift the origin from bottom-left to screen center.
// Then use the distance from center to create a radial gradient.
//
// Fill in the ??? to center the coordinates.

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    uv = ???;
    float d = length(uv);
    return vec4(d, d, d, 1.0);
}
```

`koans/01_coordinates_c/solution.glsl`:
```glsl
// Koan 01c: Moving the Origin — Solution

extern number time;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    uv = uv - 0.5;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;
    float d = length(uv);
    float rings = sin(d * 20.0 - time * 3.0) * 0.5 + 0.5;
    return vec4(rings * 0.3, rings * 0.6, rings, 1.0);
}
```

`koans/01_coordinates_c/present.lua`:
```lua
return {
    duration = 20,
    fps = 30,
    timeline = {
        { at = 0,  show = "title",    fade_in = 0.5 },
        { at = 2,  show = "lesson",   fade_in = 0.8 },
        { at = 8,  show = "code",     fade_in = 0.5 },
        { at = 15, show = "concepts", fade_in = 0.5 },
    },
}
```

- [ ] **Step 3: Create `koans/01_coordinates_d/` — Coordinate Remapping**

Create directory: `mkdir -p koans/01_coordinates_d`

`koans/01_coordinates_d/koan.lua`:
```lua
--- Koan: Zooming In
--- Chapter 1: Coordinates & UV Space
---
--- Once you have centered UV coordinates, you can scale them
--- to zoom in or out, and add offsets to pan around.
--- This is coordinate remapping — the foundation of every fractal.
return {
    title = "Zooming In",
    chapter = "coordinates",
    order = 4,
    difficulty = "beginner",

    lesson = [[
Multiplying UV coordinates by a number zooms the view.
Multiply by 2.0 → zoom out (see more). Multiply by 0.5 → zoom in.
Adding a vec2 offset pans the camera.

This is coordinate remapping: transforming UV space before
computing your effect. Every fractal viewer uses this.]],

    hints = {
        "Multiply uv by a scale factor to zoom",
        "fract() repeats a pattern — try fract(uv * 4.0)",
    },

    concepts = { "coordinate remapping", "scaling", "tiling", "fract()" },
}
```

`koans/01_coordinates_d/shader.glsl`:
```glsl
// Koan 01d: Zooming In
//
// Use coordinate remapping to create a tiled pattern.
// fract() returns the fractional part: fract(2.7) = 0.7
// Applied to UVs, it repeats the 0→1 range.
//
// Fill in the ??? to tile the UV gradient into a 4×4 grid.

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    uv = ???;
    return vec4(uv.x, uv.y, 0.5, 1.0);
}
```

`koans/01_coordinates_d/solution.glsl`:
```glsl
// Koan 01d: Zooming In — Solution

extern number time;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    float tiles = 4.0 + 2.0 * sin(time * 0.5);
    uv = fract(uv * tiles);
    return vec4(uv.x, uv.y, 0.5 + 0.3 * sin(time), 1.0);
}
```

`koans/01_coordinates_d/present.lua`:
```lua
return {
    duration = 22,
    fps = 30,
    timeline = {
        { at = 0,  show = "title",    fade_in = 0.5 },
        { at = 2,  show = "lesson",   fade_in = 0.8 },
        { at = 9,  show = "code",     fade_in = 0.5 },
        { at = 17, show = "concepts", fade_in = 0.5 },
    },
}
```

- [ ] **Step 4: Update `koans/index.lua`**

```lua
--- Curriculum index: defines the order koans are presented.
--- Each entry maps a folder name to its chapter and position.
return {
    -- Chapter 1: Coordinates & UV Space
    { id = "01_coordinates",   chapter = "Coordinates & UV Space", order = 1 },
    { id = "01_coordinates_b", chapter = "Coordinates & UV Space", order = 2 },
    { id = "01_coordinates_c", chapter = "Coordinates & UV Space", order = 3 },
    { id = "01_coordinates_d", chapter = "Coordinates & UV Space", order = 4 },
}
```

- [ ] **Step 5: Verify all 4 koans load in learn mode**

Run: `cd /Users/s3nik/Desktop/lua-shaders && love .`
Expected: Shows "Koan 1/4" at top. Press right arrow → cycles through all 4 koans. Each shows appropriate title and error about unfilled blanks.

- [ ] **Step 6: Verify presentation mode for a new koan**

Run: `love . --present 01_coordinates_b`
Expected: Records and exports the aspect ratio koan (pulsing circle).

- [ ] **Step 7: Commit**

```bash
git add koans/
git commit -m "feat: add Chapter 1 koans (coordinates, aspect ratio, centering, remapping)"
```

---

### Task 10: Add Chapter 2 Koans (Color Mixing)

**Files:**
- Create: `koans/02_color_a/` through `koans/02_color_d/`
- Modify: `koans/index.lua`

- [ ] **Step 1: Create `koans/02_color_a/` — RGB as vec3**

Create directory: `mkdir -p koans/02_color_a`

`koans/02_color_a/koan.lua`:
```lua
return {
    title = "Colors Are Numbers",
    chapter = "color",
    order = 1,
    difficulty = "beginner",

    lesson = [[
In shaders, colors are vec3 or vec4 — just numbers.
Red is (1, 0, 0). Green is (0, 1, 0). Blue is (0, 0, 1).
You can add, multiply, and mix colors with arithmetic.

vec3(0.5) means (0.5, 0.5, 0.5) — a medium gray.
Multiplying a color by 0.5 makes it half as bright.]],

    hints = {
        "Try vec3(1.0, 0.0, 0.0) for pure red",
        "Use uv.x to interpolate between two colors",
    },

    concepts = { "RGB vectors", "color arithmetic", "brightness" },
}
```

`koans/02_color_a/shader.glsl`:
```glsl
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
```

`koans/02_color_a/solution.glsl`:
```glsl
extern number time;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    vec3 red = vec3(1.0, 0.2, 0.1);
    vec3 blue = vec3(0.1, 0.2, 1.0);
    float t = uv.x + 0.1 * sin(uv.y * 10.0 + time * 2.0);
    vec3 col = mix(red, blue, t);
    return vec4(col, 1.0);
}
```

`koans/02_color_a/present.lua`:
```lua
return {
    duration = 18,
    fps = 30,
    timeline = {
        { at = 0,  show = "title",    fade_in = 0.5 },
        { at = 2,  show = "lesson",   fade_in = 0.8 },
        { at = 8,  show = "code",     fade_in = 0.5 },
        { at = 14, show = "concepts", fade_in = 0.5 },
    },
}
```

- [ ] **Step 2: Create `koans/02_color_b/` — Smoothstep**

Create directory: `mkdir -p koans/02_color_b`

`koans/02_color_b/koan.lua`:
```lua
return {
    title = "The Smooth Knife",
    chapter = "color",
    order = 2,
    difficulty = "beginner",

    lesson = [[
smoothstep(edge0, edge1, x) is the shader swiss army knife.
It returns 0 when x < edge0, 1 when x > edge1, and a smooth
S-curve in between. No jagged edges, just butter.

Use it for: soft borders, smooth transitions, anti-aliasing,
color ramps, masks — almost everything.]],

    hints = {
        "smoothstep(0.4, 0.6, uv.x) creates a soft edge at x=0.5",
        "Try smoothstep on distance to create a soft circle",
    },

    concepts = { "smoothstep", "interpolation", "anti-aliasing", "S-curve" },
}
```

`koans/02_color_b/shader.glsl`:
```glsl
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
```

`koans/02_color_b/solution.glsl`:
```glsl
extern number time;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    float edge = 0.5 + 0.3 * sin(time);
    float gradient = smoothstep(edge - 0.1, edge + 0.1, uv.x);
    vec3 col = mix(vec3(0.9, 0.2, 0.3), vec3(0.2, 0.3, 0.9), gradient);
    return vec4(col, 1.0);
}
```

`koans/02_color_b/present.lua`:
```lua
return {
    duration = 18,
    fps = 30,
    timeline = {
        { at = 0,  show = "title",    fade_in = 0.5 },
        { at = 2,  show = "lesson",   fade_in = 0.8 },
        { at = 8,  show = "code",     fade_in = 0.5 },
        { at = 14, show = "concepts", fade_in = 0.5 },
    },
}
```

- [ ] **Step 3: Create `koans/02_color_c/` — Cosine Palettes**

Create directory: `mkdir -p koans/02_color_c`

`koans/02_color_c/koan.lua`:
```lua
return {
    title = "Inigo's Rainbow",
    chapter = "color",
    order = 3,
    difficulty = "intermediate",

    lesson = [[
Inigo Quilez discovered that beautiful color palettes can be
generated with a single formula:

  color(t) = a + b * cos(2π * (c*t + d))

Where a, b, c, d are vec3 parameters. By tweaking these four
vectors, you get infinite palettes. One formula to rule them all.]],

    hints = {
        "a = offset, b = amplitude, c = frequency, d = phase",
        "Try a=0.5, b=0.5, c=1.0, d=vec3(0.0, 0.33, 0.67) for rainbow",
    },

    concepts = { "cosine palettes", "Inigo Quilez", "parametric color", "periodic functions" },
}
```

`koans/02_color_c/shader.glsl`:
```glsl
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
```

`koans/02_color_c/solution.glsl`:
```glsl
extern number time;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy;
    uv = uv - 0.5;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;

    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.0, 0.33, 0.67);

    float dist = length(uv);
    float t = dist * 2.0 - time * 0.5;
    vec3 col = a + b * cos(6.28318 * (c * t + d));
    return vec4(col, 1.0);
}
```

`koans/02_color_c/present.lua`:
```lua
return {
    duration = 22,
    fps = 30,
    timeline = {
        { at = 0,  show = "title",    fade_in = 0.5 },
        { at = 2,  show = "lesson",   fade_in = 0.8 },
        { at = 9,  show = "code",     fade_in = 0.5 },
        { at = 17, show = "concepts", fade_in = 0.5 },
    },
}
```

- [ ] **Step 4: Create `koans/02_color_d/` — HSV Conversion**

Create directory: `mkdir -p koans/02_color_d`

`koans/02_color_d/koan.lua`:
```lua
return {
    title = "The Hue Wheel",
    chapter = "color",
    order = 4,
    difficulty = "intermediate",

    lesson = [[
RGB mixes colors by brightness. HSV separates them:
H = hue (which color: 0=red, 0.33=green, 0.67=blue)
S = saturation (0=gray, 1=vivid)
V = value (0=dark, 1=bright)

To convert: use the hue to pick 3 ramp values,
scale by saturation, and multiply by value.
The formula is just math — no lookup tables needed.]],

    hints = {
        "fract(h + vec3(0, 2, 1) / 3.0) offsets RGB phases",
        "clamp and mix to create the ramp for each channel",
    },

    concepts = { "HSV color space", "hue", "saturation", "color conversion" },
}
```

`koans/02_color_d/shader.glsl`:
```glsl
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
// Fill in ??? to create a hue wheel using the angle from center.

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
```

`koans/02_color_d/solution.glsl`:
```glsl
extern number time;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / love_ScreenSize.xy - 0.5;
    uv.x *= love_ScreenSize.x / love_ScreenSize.y;

    float angle = atan(uv.y, uv.x);
    float hue = angle / 6.28318 + 0.5 + time * 0.1;
    float dist = length(uv);
    float sat = smoothstep(0.0, 0.3, dist);
    float val = 1.0 - smoothstep(0.35, 0.4, dist);

    vec3 k = fract(hue + vec3(0.0, 2.0, 1.0) / 3.0) * 6.0 - 3.0;
    vec3 rgb = val * mix(vec3(1.0), clamp(abs(k) - 1.0, 0.0, 1.0), sat);
    return vec4(rgb, 1.0);
}
```

`koans/02_color_d/present.lua`:
```lua
return {
    duration = 20,
    fps = 30,
    timeline = {
        { at = 0,  show = "title",    fade_in = 0.5 },
        { at = 2,  show = "lesson",   fade_in = 0.8 },
        { at = 9,  show = "code",     fade_in = 0.5 },
        { at = 16, show = "concepts", fade_in = 0.5 },
    },
}
```

- [ ] **Step 5: Update `koans/index.lua`**

```lua
return {
    -- Chapter 1: Coordinates & UV Space
    { id = "01_coordinates",   chapter = "Coordinates & UV Space", order = 1 },
    { id = "01_coordinates_b", chapter = "Coordinates & UV Space", order = 2 },
    { id = "01_coordinates_c", chapter = "Coordinates & UV Space", order = 3 },
    { id = "01_coordinates_d", chapter = "Coordinates & UV Space", order = 4 },

    -- Chapter 2: Color Mixing & Palettes
    { id = "02_color_a", chapter = "Color Mixing & Palettes", order = 5 },
    { id = "02_color_b", chapter = "Color Mixing & Palettes", order = 6 },
    { id = "02_color_c", chapter = "Color Mixing & Palettes", order = 7 },
    { id = "02_color_d", chapter = "Color Mixing & Palettes", order = 8 },
}
```

- [ ] **Step 6: Verify all 8 koans in learn mode**

Run: `love .`
Expected: "Koan 1/8" at top. Navigate through all 8 with arrow keys.

- [ ] **Step 7: Verify a Chapter 2 presentation export**

Run: `love . --present 02_color_c`
Expected: Exports "Inigo's Rainbow" koan as GIF/MP4 with animated rainbow cosine palette.

- [ ] **Step 8: Commit**

```bash
git add koans/
git commit -m "feat: add Chapter 2 koans (color mixing, smoothstep, cosine palettes, HSV)"
```

---

### Task 11: Polish and End-to-End Verification

**Files:**
- Modify: various files for polish
- Create: `export/` directory

- [ ] **Step 1: Create export directory**

Run: `mkdir -p export`

- [ ] **Step 2: Run full end-to-end test — learn mode**

Run: `cd /Users/s3nik/Desktop/lua-shaders && love .`

Verify:
1. Window opens at 540×960 (9:16)
2. Shows "Koan 1/8" with "The Canvas is a Map" title
3. Error panel shows unfilled blanks message
4. Arrow keys navigate between all 8 koans
5. `H` key shows/cycles hints
6. `S` key toggles solution overlay
7. Editing a shader file triggers hot-reload within 0.5s

- [ ] **Step 3: Run full end-to-end test — present mode for each Chapter 1 koan**

Run: `love . --present 01_coordinates`
Run: `love . --present 01_coordinates_b`
Run: `love . --present 01_coordinates_c`
Run: `love . --present 01_coordinates_d`

Verify for each:
1. Console shows recording progress
2. MP4 and GIF files appear in `export/`
3. Open GIF — shader animates, overlays fade in per timeline
4. Instagram-ready: 9:16 aspect, clean layout, readable text

- [ ] **Step 4: Run full end-to-end test — present mode for Chapter 2**

Run: `love . --present 02_color_a`
Run: `love . --present 02_color_b`
Run: `love . --present 02_color_c`
Run: `love . --present 02_color_d`

Same verification as Step 3.

- [ ] **Step 5: Verify export file sizes are Instagram-friendly**

Run: `ls -lh export/`
Expected: GIFs under 15MB, MP4s under 5MB. If GIFs are too large, the GIF export in `exporter.lua` already scales to 540px wide with 128 colors — should be fine for 18-22 second clips.

- [ ] **Step 6: Final commit**

```bash
git add -A
git commit -m "feat: complete Chapter 1 & 2 with full presentation pipeline"
```

---

## Future Tasks (Not In This Plan)

These are tracked for reference but will be separate implementation plans:

- **Chapters 3-7**: SDF shapes, waves/motion, noise, fractals, raymarching
- **Batch export**: `love . --present all` to export every koan in sequence
- **Custom fonts**: bundle a monospace font (e.g., JetBrains Mono) for code overlays
- **Theme variants**: dark/light, different color schemes, YouTube Shorts (9:16 but different overlay style)
- **README.md**: project documentation, installation guide, contributor guide
