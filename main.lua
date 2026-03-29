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
