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
