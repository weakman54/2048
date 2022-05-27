
local util = require("util")
local Grid = require("grid")


local Game = {}

function Game:setScore(inScore)
    self.score = inScore
    love.window.setTitle(Title_Prefix .. self.score)
end

function Game:insertHistory(grid, score)
    table.insert(self.history, {
        grid = grid,
        score = score
    })
    self.curGrid = grid
end


function Game:initialize()
    self.history = {}

    self:insertHistory(Grid:new():initialize(), 0)

    self.gamestate = "game"

    self:setScore(0)
    
    self.highscores = {}
    self:loadHighscores()

    self.autoplay = false
end

function Game:restart()
    self:initialize() -- For now these are the same
end

function Game:hasLost()
    return not self.curGrid:canMove()
end

function Game:gameOver()
    self.gamestate = "gameOver"
    table.insert(self.highscores, self.score)
    self:saveHighscores()
end


function Game:move(dir)
    local moveSuccessful = false
    if self.gamestate ~= "game" then return end

    local moveF = "move" .. dir  -- TODO: This is hacky and brittle
    
    local newGrid, mergeScore = self.curGrid[moveF](self.curGrid)
    
    if newGrid ~= self.curGrid then
        moveSuccessful = true
        self:setScore(self.score + mergeScore)

        newGrid = newGrid:spawnTile()

        self:insertHistory(newGrid, self.score)

        if self:hasLost() then
            self:gameOver()
        end
    end

    return moveSuccessful
end

function Game:undo()
    if self.gamestate ~= "game" then return end

    if #self.history > 1 then
        table.remove(self.history)
        self.curGrid = self.history[#self.history].grid
        self:setScore(self.history[#self.history].score)
    end
end


function Game:save(filename)
    filename = filename or "save.dat"

    local saveStr = ""
    for _, historyData in ipairs(self.history) do
        saveStr = saveStr .. historyData.grid:serialize() .. '\n'
        saveStr = saveStr .. historyData.score .. '\n'
    end

    love.filesystem.write(filename, saveStr)
end

function Game:load(filename)
    filename = filename or "save.dat"

    local saveStr = love.filesystem.read(filename)

    local saveLines = {}
    for line in saveStr:gmatch("[^\n]+") do
        table.insert(saveLines, line)
    end

    self.history = {}
    for i = 1, #saveLines, 2 do
        local grid = Grid:new().deserialize(saveLines[i])
        local score = tonumber(saveLines[i + 1])
        self:insertHistory(grid, score)
    end

    self.curGrid = self.history[#self.history].grid
    self:setScore(self.history[#self.history].score)

    
    if not self.curGrid:canMove() then
        self.gamestate = "gameOver"
    else
        self.gamestate = "game"
    end
end


function Game:loadHighscores()
    local highscores = {}
    local highscoresFile = love.filesystem.read("highscores.dat")

    if not highscoresFile then
        return {}
    end

    for line in highscoresFile:gmatch("[^\n]+") do
        local score = tonumber(line)
        table.insert(highscores, score)
    end
    
    self.highscores = highscores
    table.sort(self.highscores, function(a, b) return a > b end)
end

function Game:saveHighscores()
    table.sort(self.highscores, function(a, b) return a > b end)

    local highscoresStr = ""
    for _, score in ipairs(self.highscores) do
        highscoresStr = highscoresStr .. score .. '\n'
    end

    love.filesystem.write("highscores.dat", highscoresStr)
end





function Game:update(dt)
    if self.autoplay then -- For debug purposes, also it looks cool
        local directions = {'Up', 'Down', 'Left', 'Right'}

        self.autoplayAcc = (self.autoplayAcc or 0) + dt
        if self.autoplayAcc > self.autoplayInterval then
            self.autoplayAcc = 0
            self:move(directions[math.random(1, #directions)])
        end
    end


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




local function drawGrid()
    for x = 1, Grid_Size do
        for y = 1, Grid_Size do
            local tile = Game.curGrid[x][y]

            if tile == 0 then
                goto draw_grid_continue
            end
            
            -- Draw the tile
            -- calculate the hue of each tile based on the value, the hue is a 0-1 value depending on Max_Value_Power
            -- This basically means there is a maximum power for the value of the tile, though it is not a hard limit
            -- What happens to the hue beyond 2^Max_Value_Power I have no clue
            local shade = (math.log(tile) / math.log(2)) / Max_Value_Power
            love.graphics.setColor(util.hsvToRGB(shade, 0.8, 0.8))
            love.graphics.rectangle("fill", (x - 1) * Tile_Size, (y - 1) * Tile_Size, Tile_Size, Tile_Size)
        

            -- draw the number
            love.graphics.setColor(0, 0, 0)
            local font = love.graphics.getFont()
            local width = font:getWidth(tostring(tile))
            local height = font:getHeight()
            love.graphics.print(tostring(tile), (x - 1) * Tile_Size + (Tile_Size - width) / 2, (y - 1) * Tile_Size + (Tile_Size - height) / 2)

            ::draw_grid_continue::
        end
    end
end


local function drawGameOver()
    love.graphics.setColor(0.9, 0.9, 0.9, 0.70)
    love.graphics.rectangle("fill", 0, 0, Window_Width, Window_Height)

    love.graphics.setColor(0, 0, 0)
    local font = love.graphics.getFont()
    local height = font:getHeight()

    love.graphics.print("Game Over", Window_Width / 2 - font:getWidth("Game Over") / 2, 20)
    love.graphics.print("Your score: " .. Game.score, Window_Width / 2 - font:getWidth("Your score: " .. Game.score) / 2, height*1.2 + 20)

    love.graphics.print("High Scores", Window_Width / 2 - font:getWidth("High Scores") / 2, 20 + height*1.2*2.5)
    for i = 1, math.min(#Game.highscores, 4) do
        love.graphics.print(Game.highscores[i], Window_Width / 2 - font:getWidth(Game.highscores[i]) / 2, 20 + height*1.2*2.5 + height*i)
    end

    love.graphics.print("Press Q to quit", Window_Width / 2 - font:getWidth("Press Q to quit") / 2, Window_Height - height*1.2*3)
    love.graphics.print("Press R or Esc to restart", Window_Width / 2 - font:getWidth("Press R or Esc to restart") / 2, Window_Height - height*1.2*4)


end


local function drawMenu()
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


function Game:draw()
    drawGrid()
    
    if Game.gamestate == "gameOver" then
        drawGameOver()
    
    elseif Game.gamestate == "menu" then
        drawMenu()
    end
end




return Game