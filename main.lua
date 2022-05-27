-- 2048 clone, by weakman54 2022

--[[ TODO:
    Refactor tests into proper unit tests
    figure out options for window
    "Seeded" randomness to make undo less cheaty (though it's still possible to use it to test for "favourable" moves)
    Fix Icon
    Proper state management

    Find a nice font
    Redo menu screens to look nicer and be more consistent between each other

    Tests for score
    Tests for highscores

    Tile animation?
    Names for highscores?
    Implement win?
    Implement settings?
    joystick hotplug support?
]]


require("global_config")

local Game = require("game")


function love.load()
    love.window.setTitle(Title_Prefix)
    love.window.setMode(Window_Width, Window_Height, nil)
    love.window.setFullscreen(false)
    -- love.window.setIcon(love.image.newImageData("assets/icon.png"))

    love.graphics.setFont(love.graphics.newFont(24))

    Game:initialize()
    Game:load()
end


function love.update(dt)
    Input:update()

    Game:update(dt)
end


function love.draw()
    Game:draw()
end


function love.keypressed(key)
    if key == "f9" then
        Game.autoplay = not Game.autoplay
        Game.autoplayInterval = 0.1
    
    elseif key == "f10" then
        Game.autoplay = not Game.autoplay
        Game.autoplayInterval = 0.0

    end
end


function love.quit()
    Game:save()
end