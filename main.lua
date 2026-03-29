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
        elseif v == "--demo" then
            mode = "demo"
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
    elseif mode == "learn" or mode == "demo" then
        local KoanRunner = require("lib.koan_runner")
        runner = KoanRunner.new(mode == "demo")
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
