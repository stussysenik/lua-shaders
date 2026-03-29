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
