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
