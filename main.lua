-- 2048 clone, by weakman54 2022

--[[ TODO:
    Refactor tests into proper unit tests
    figure out options for window
    "Seeded" randomness to make undo less cheaty (though it's still possible to use it to test for "favourable" moves)
    Fix Icon

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
local util = require("util")





-- Main ------------------------------------------------------------------------
function love.load()
    love.window.setTitle(Title_Prefix)
    love.window.setMode(Window_Width, Window_Height, nil)
    love.window.setFullscreen(false)
    -- love.window.setIcon(love.image.newImageData("assets/icon.png"))

    love.graphics.setFont(love.graphics.newFont(24))

    Game:load()
end


function love.update(dt)
    Input:update()

    if Input:pressed("up") then
        Game:move("Up")

    elseif Input:pressed("down") then
        Game:move("Down")
    
    elseif Input:pressed("left") then
        Game:move("Left")
    
    elseif Input:pressed("right") then
        Game:move("Right")
    

    elseif Input:pressed("restart") then
        Game:restart()

    elseif Input:pressed("undo") then
        if Game.gamestate == "game" then
            Game:undo()
        end
    
    elseif Input:pressed("menuButton") then
        if Game.gamestate == "game" then
            Game.gamestate = "menu"

        elseif Game.gamestate == "menu" then
            Game.gamestate = "game"
        
        elseif Game.gamestate == "gameOver" then
            Game:restart()
        end
    
    elseif Input:pressed("quit") then
        if Game.gamestate == "gameOver" or Game.gamestate == "menu" then
            love.event.quit()

        elseif Game.gamestate == "game" then
            Game.gamestate = "menu"

        end
    end
end


function love.keypressed(key)
    -- if key == "f11" then
    --     Tests()
    -- end
    
    if key == "f12" then
        
        while not Game:hasLost() do
            Game:move("Up")
            Game:move("Down")
            Game:move("Left")
            Game:move("Right")
        end
    end
end


function love.draw()
    love.graphics.setColor(0.9, 0.9, 0.9)
    

    for x = 1, Grid_Size do
        for y = 1, Grid_Size do
            local tile = Game.curGrid[x][y]

            if tile == 0 then
                goto draw_grid_continue
            end
            
            -- draw a rectangle for each tile, set the color to a hue depending on the value
            -- given squared values, we can use the logarithm to get the hue
            local shade = (math.log(tile) / math.log(2)) / Max_Value_Power
            love.graphics.setColor(util.hsvToRGB(shade, 0.8, 0.8))
            love.graphics.rectangle("fill", (x - 1) * Tile_Size, (y - 1) * Tile_Size, Tile_Size, Tile_Size)
        
            -- draw the number inside the tile
            love.graphics.setColor(0, 0, 0)
            local font = love.graphics.getFont()
            local width = font:getWidth(tostring(tile))
            local height = font:getHeight()
            love.graphics.print(tostring(tile), (x - 1) * Tile_Size + (Tile_Size - width) / 2, (y - 1) * Tile_Size + (Tile_Size - height) / 2)
            

            ::draw_grid_continue::
        end
    end


    -- Draw game over scren
    if Game.gamestate == "gameOver" then
        love.graphics.setColor(0.9, 0.9, 0.9, 0.70)
        love.graphics.rectangle("fill", 0, 0, Window_Width, Window_Height)

        love.graphics.setColor(0, 0, 0)
        local font = love.graphics.getFont()
        local height = font:getHeight()

        love.graphics.print("Game Over", Window_Width / 2 - font:getWidth("Game Over") / 2, 20)
        love.graphics.print("Score: " .. Game.score, Window_Width / 2 - font:getWidth("Score: " .. Game.score) / 2, height*1.2 + 20)
        love.graphics.print("Press Q to quit", Window_Width / 2 - font:getWidth("Press Q to quit") / 2, Window_Height - height*1.2*3)
        love.graphics.print("Press R or Esc to restart", Window_Width / 2 - font:getWidth("Press R or Esc to restart") / 2, Window_Height - height*1.2*4)

        love.graphics.print("High Scores", Window_Width / 2 - font:getWidth("High Scores") / 2, 20 + height*1.2*2.5)
        for i = 1, math.min(#Game.highscores, 4) do
            love.graphics.print(Game.highscores[i], Window_Width / 2 - font:getWidth(Game.highscores[i]) / 2, 20 + height*1.2*2.5 + height*i)
        end
    end


    -- Draw menu screen
    if Game.gamestate == "menu" then
        love.graphics.setColor(0.9, 0.9, 0.9, 0.70)
        love.graphics.rectangle("fill", 0, 0, Window_Width, Window_Height)

        love.graphics.setColor(0, 0, 0)
        local font = love.graphics.getFont()
        local height = font:getHeight()

        love.graphics.print("2048 clone, by weakman54", Window_Width / 2 - font:getWidth("2048 clone, by weakman54") / 2, 20)

        love.graphics.print("High Scores", Window_Width / 2 - font:getWidth("High Scores") / 2, 20 + height*1.2*1.5)
        for i = 1, math.min(#Game.highscores, 4) do
            love.graphics.print(Game.highscores[i], Window_Width / 2 - font:getWidth(Game.highscores[i]) / 2, 20 + height*1.2*1.5 + height*i)
        end

        love.graphics.print("Press Q to quit", Window_Width / 2 - font:getWidth("Press Q to quit") / 2, Window_Height - height*1.2*3)
        love.graphics.print("Press R to restart", Window_Width / 2 - font:getWidth("Press R to restart") / 2, Window_Height - height*1.2*4)
        love.graphics.print("Press Esc to go back to game", Window_Width / 2 - font:getWidth("Press Escape to go back to game") / 2, Window_Height - height*1.2*5)
    end
end


function love.quit()
    Game:save()
end