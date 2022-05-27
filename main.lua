-- 2048 clone, by weakman54 2022
-- TODO:
-- Tests for score
-- Test for highscores
-- Names for highscores
-- Implement win?
-- Implement settings?
-- Tile animation
-- "Seeded" randomness to make undo less cheaty (though it's still possible to use it to test for "favourable" moves)
-- joystick hotplug support?

local baton = require("baton")

local util = require("util")




-- Config ---------------------------------------------------------------------
local input = baton.new {
    controls = {
        left =  {"key:left" , "key:a", "axis:leftx-", "button:dpleft" , "key:h"},
        right = {"key:right", "key:d", "axis:leftx+", "button:dpright", "key:l"},
        up =    {"key:up"   , "key:w", "axis:lefty-", "button:dpup"   , "key:k"},
        down =  {"key:down" , "key:s", "axis:lefty+", "button:dpdown" , "key:j"},

        undo = {"key:z", "button:b"},
        restart = {"key:r", "button:x"},
        menuButton = {"key:escape", "button:start"},
        quit = {"key:q", "button:back"},
    },
    joystick = love.joystick.getJoysticks()[1],
}

local Title_Prefix = "2048 clone, by weakman54. Score: "
local Grid_Size = 4
local Tile_Size = 100

local Max_Value_Power = 20 -- Determines how the hues for Tiles are calculated, the "max value" is 2^Max_Value_Power, which will be hue 1 (blue/purple). The game can play past this, but I don't know what the colors will do

local Window_Width  = Grid_Size * Tile_Size
local Window_Height = Grid_Size * Tile_Size

local Chance_Of_Four = 0.1

local Debug_Print = false





-- Grid -----------------------------------------------------------------------
local Grid = {}

function Grid.equals(a, b)
    for x = 1, Grid_Size do
        for y = 1, Grid_Size do
            if a[x][y] ~= b[x][y] then
                return false
            end
        end
    end

    return true
end

function Grid:toString()
    local str = ""
    for y = 1, Grid_Size do
        for x = 1, Grid_Size do
            str = str .. self[x][y] .. " "
        end
        str = str .. "\n"
    end
    return str
end


function Grid:new()
    local grid = setmetatable({}, {__index = Grid, __eq = Grid.equals, __tostring = Grid.toString})

    for x = 1, Grid_Size do
        grid[x] = {}
        for y = 1, Grid_Size do
            grid[x][y] = 0
        end
    end

    return grid
end


function Grid:initialize()
    local grid = self:clone()

    -- Set up the initial tiles, scatter them randomly
    local numTiles = love.math.random(1, 3)
    for i = 1, numTiles do
        local x = love.math.random(1, Grid_Size)
        local y = love.math.random(1, Grid_Size)

        if grid[x][y] == 0 then
            grid[x][y] = 2
        end
    end

    return grid
end


function Grid:clone()
    local grid = Grid:new()

    for x = 1, Grid_Size do
        grid[x] = {}
        for y = 1, Grid_Size do
            grid[x][y] = self[x][y]
        end
    end

    return grid
end


function Grid:moveUp(inGrid)
    local grid = inGrid and inGrid:clone() or self:clone()
    local score = 0

    local mergedTiles = {} -- set of tiles that have been merged, so we don't merge a tile more than once per move

    for x = 1, Grid_Size do
        for y = 2, Grid_Size do -- NOTE: start at 2 since we can't move a tile above the top row
            if grid[x][y] == 0 then
                goto moveUp_Continue
            end
            
            local tY = y
            while tY > 1 do
                local mergedTilesKey = x .. ',' .. (tY - 1)

                if grid[x][tY - 1] == grid[x][tY] and not mergedTiles[mergedTilesKey] then -- if the tile above is the same, and has not already been merged, merge with it
                    grid[x][tY - 1] = grid[x][tY] * 2
                    grid[x][tY] = 0

                    score = score + grid[x][tY - 1]
                    
                    mergedTiles[mergedTilesKey] = true
                    goto moveUp_Continue
                
                elseif grid[x][tY - 1] == 0 then -- if the tile above is empty, move the tile up
                    grid[x][tY - 1] = grid[x][tY]
                    grid[x][tY] = 0
                    tY = tY - 1
                
                else -- can't move or merge, move on to the next tile
                    goto moveUp_Continue

                end
            end

            ::moveUp_Continue::
        end
    end

    return grid, score
end

function Grid:moveDown(inGrid)
    local grid = inGrid and inGrid:clone() or self:clone()
    local score = 0

    local mergedTiles = {} -- set of tiles that have been merged, so we don't merge them again
    
    -- for each tile in the grid
    for x = 1, Grid_Size do
        for y = Grid_Size - 1, 1, -1 do -- NOTE: start at Grid_Size - 1 since we can't move a tile below the bottom row
            -- if the tile is empty, continue
            if grid[x][y] == 0 then
                goto moveDown_Continue
            end
            
            local tY = y
            while tY < Grid_Size do
                local mergedTilesKey = x .. ',' .. (tY + 1)

                if grid[x][tY + 1] == grid[x][tY] and not mergedTiles[mergedTilesKey] then -- if the tile below is the same, and has not already been merged, merge with it
                    grid[x][tY + 1] = grid[x][tY] * 2
                    grid[x][tY] = 0

                    score = score + grid[x][tY + 1]
                    
                    mergedTiles[mergedTilesKey] = true
                    goto moveDown_Continue
                
                elseif grid[x][tY + 1] == 0 then -- if the tile below is empty, move the tile down
                    grid[x][tY + 1] = grid[x][tY]
                    grid[x][tY] = 0
                    tY = tY + 1
                
                else -- if the tile below is not the same, stop
                    goto moveDown_Continue

                end
            end

            ::moveDown_Continue::
        end
    end

    return grid, score
end

function Grid:moveLeft(inGrid)
    local grid = inGrid and inGrid:clone() or self:clone()
    local score = 0

    local mergedTiles = {} -- set of tiles that have been merged, so we don't merge them again
    
    -- for each tile in the grid
    for y = 1, Grid_Size do
        for x = 2, Grid_Size do -- NOTE: start at 2 since we can't move a tile to the left of the left row
            -- if the tile is empty, continue
            if grid[x][y] == 0 then
                goto moveLeft_Continue
            end
            
            local tX = x
            while tX > 1 do
                local mergedTilesKey = (tX - 1) .. ',' .. y

                if grid[tX - 1][y] == grid[tX][y] and not mergedTiles[mergedTilesKey] then -- if the tile to the left is the same, and has not already been merged, merge with it
                    grid[tX - 1][y] = grid[tX][y] * 2
                    grid[tX][y] = 0

                    score = score + grid[tX - 1][y]
                    
                    mergedTiles[mergedTilesKey] = true
                    goto moveLeft_Continue
                
                elseif grid[tX - 1][y] == 0 then -- if the tile to the left is empty, move the tile to the left
                    grid[tX - 1][y] = grid[tX][y]
                    grid[tX][y] = 0
                    tX = tX - 1
                
                else -- if the tile to the left is not the same, stop
                    goto moveLeft_Continue

                end
            end

            ::moveLeft_Continue::
        end
    end

    return grid, score
end

function Grid:moveRight(inGrid)
    local grid = inGrid and inGrid:clone() or self:clone()
    local score = 0

    local mergedTiles = {} -- set of tiles that have been merged, so we don't merge them again
    
    -- for each tile in the grid
    for y = 1, Grid_Size do
        for x = Grid_Size - 1, 1, -1 do -- NOTE: start at Grid_Size - 1 since we can't move a tile to the right of the right row
            -- if the tile is empty, continue
            if grid[x][y] == 0 then
                goto moveRight_Continue
            end
            
            local tX = x
            while tX < Grid_Size do
                local mergedTilesKey = (tX + 1) .. ',' .. y
                
                if grid[tX + 1][y] == grid[tX][y] and not mergedTiles[mergedTilesKey] then -- if the tile to the right is the same, and has not already been merged, merge with it
                    grid[tX + 1][y] = grid[tX][y] * 2
                    grid[tX][y] = 0

                    score = score + grid[tX + 1][y]
                    
                    mergedTiles[mergedTilesKey] = true
                    goto moveRight_Continue
                
                elseif grid[tX + 1][y] == 0 then -- if the tile to the right is empty, move the tile to the right
                    grid[tX + 1][y] = grid[tX][y]
                    grid[tX][y] = 0
                    tX = tX + 1
                
                else -- if the tile to the right is not the same, stop
                    goto moveRight_Continue

                end
            end

            ::moveRight_Continue::
        end
    end

    return grid, score
end


function Grid:isFull()
    for x = 1, Grid_Size do
        for y = 1, Grid_Size do
            if self[x][y] == 0 then
                return false
            end
        end
    end

    return true
end

function Grid:canMove()
    return self:moveUp()    ~= self
        or self:moveDown()  ~= self
        or self:moveLeft()  ~= self
        or self:moveRight() ~= self
end


function Grid:spawnTile(inGrid)
    local grid = inGrid and inGrid:clone() or self:clone()

    if grid:isFull() then
        error("Grid:spawnTile(): Grid is full, cannot spawn tile", 2)
    end
    
    
    local emptyTiles = {}
    for x = 1, Grid_Size do
        for y = 1, Grid_Size do
            if grid[x][y] == 0 then
                table.insert(emptyTiles, {x = x, y = y})
            end
        end
    end

    assert(#emptyTiles > 0, "Grid:spawnTile(): No empty tiles in grid")

    -- select random empty tile
    local tile = emptyTiles[math.random(#emptyTiles)]
    local x, y = tile.x, tile.y

    local tileToSpawn = love.math.random() <= Chance_Of_Four and 4 or 2

    grid[x][y] = tileToSpawn

    return grid
end


function Grid:serialize()
    local gridStr = ""

    for x = 1, Grid_Size do
        for y = 1, Grid_Size do
            gridStr = gridStr .. self[x][y] .. " "
        end
    end

    return gridStr
end

function Grid.deserialize(gridStr)
    local grid = Grid:new()

    for x = 1, Grid_Size do
        for y = 1, Grid_Size do
            local tile = gridStr:match("%d+")
            gridStr = gridStr:gsub("%d+", "", 1)

            grid[x][y] = tonumber(tile)
        end
    end

    return grid
end







-- Game -----------------------------------------------------------------------
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
end

function Game:restart()
    self:initialize() -- For now these are the same
end

function Game:hasLost()
    return not self.curGrid:canMove()
end

function Game:gameOver()
    self.gamestate = "gameOver"
    -- write score to high scores
    table.insert(self.highscores, self.score)
    self:saveHighscores()
end


-- ASSUMPTION: the grid is not in a lose state
-- returns bool depending on whether the move was successful
function Game:move(dir)
    local moveSuccessful = false
    if self.gamestate ~= "game" then return end

    local moveF = "move" .. dir  -- hacky and brittle
    
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

    -- check if the game is over
    if not self.curGrid:canMove() then
        self.gamestate = "gameOver"
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
    -- sort highscores
    table.sort(self.highscores, function(a, b) return a > b end)

    local highscoresStr = ""
    for _, score in ipairs(self.highscores) do
        highscoresStr = highscoresStr .. score .. '\n'
    end

    love.filesystem.write("highscores.dat", highscoresStr)
end





-- Tests ----------------------------------------------------------------------
function Tests()
    --#region Test: Grid isFull and canMove
    local grid = Grid:new():initialize()
    
    if grid:isFull() == true then
        print(grid)
        error("Grid:isFull() failed")
    else
        print("Grid:isFull() passed")
    end
    
    if grid:canMove() == false then
        print(grid)
        error("Grid:canMove() failed")
    else
        print("Grid:canMove() passed")
    end

    for x = 1, Grid_Size do
        for y = 1, Grid_Size do
            grid[x][y] = 2
        end
    end

    if grid:isFull() == false then
        print(grid)
        error("Grid:checkFull() failed")
    else
        print("Grid:checkFull() passed")
    end
    
    if grid:canMove() == false then
        print(grid)
        error("Grid:canMove() failed")
    else
        print("Grid:canMove() passed")
    end

    for x = 1, Grid_Size do
        for y = 1, Grid_Size do
            grid[x][y] = x * Grid_Size + y
        end
    end

    if grid:isFull() == false then
        print(grid)
        error("Grid:checkFull() failed")
    else
        print("Grid:checkFull() passed")
    end

    if grid:canMove() == true then
        print(grid)
        error("Grid:canMove() failed")
    else
        print("Grid:canMove() passed")
    end
    --#endregion


    --#region Test: Tiles only merge once per move 
    local grid = Grid:new()
    grid[1][1] = 4
    grid[2][1] = 2
    grid[3][1] = 2

    grid = grid:moveLeft()
    
    if grid[1][1] ~= 4 then
        error("Merge tiles only once failed")
    else
        print("Merge tiles only once passed")
    end

    if grid[2][1] ~= 4 then
        error("Merge tiles only once failed")
    else
        print("Merge tiles only once passed")
    end
    --#endregion

    --#region Test: Tiles only merge once per move
    local grid = Grid:new()
    grid[1][1] = 4
    grid[2][1] = 2
    grid[3][1] = 2

    grid = grid:moveRight()
    
    if grid[4][1] ~= 4 then
        error("Merge tiles only once failed")
    else
        print("Merge tiles only once passed")
    end

    if grid[3][1] ~= 4 then
        error("Merge tiles only once failed")
    else
        print("Merge tiles only once passed")
    end
    --#endregion

    --#region Test: Cannot undo if there is only one move
    Game:initialize()

    local beforeGrid = Game.curGrid:clone()

    Game:undo()

    if beforeGrid ~= Game.curGrid then
        error("Cannot undo if there is only one move failed")
    else
        print("Cannot undo if there is only one move passed")
    end
    --#endregion

    --#region Test: grid before move is same as grid after move and undo
    Game:initialize()

    Game.curGrid[1][1] = 0
    Game.curGrid[2][1] = 2

    local beforeGrid = Game.curGrid:clone()

    Game:move("Left")
    Game:undo()

    if beforeGrid ~= Game.curGrid then
        error("grid before move is same as grid after move and undo failed")
    else
        print("grid before move is same as grid after move and undo passed")
    end
    --#endregion

    --#region Test: grid serialize and deserialize
    local grid = Grid:new()
    grid[1][1] = 2
    grid[2][2] = 4
    grid[3][1] = 8
    grid[4][3] = 16

    local gridStr = grid:serialize()

    local grid2 = Grid.deserialize(gridStr)

    if grid2 ~= grid then
        error("grid serialize and deserialize failed")
    else
        print("grid serialize and deserialize passed")
    end
    --#endregion

    --#region Test: Game save and load
    Game:initialize()
    grid[1][1] = 2
    grid[1][2] = 2
    grid[3][1] = 8
    grid[4][3] = 16
    
    local initialGrid = Game.curGrid:clone()
    local initialScore = Game.score

    Game:save("test.dat")

    Game:load("test.dat")

    if initialGrid ~= Game.curGrid then
        error("Game save and load failed")
    else
        print("Game save and load passed")
    end

    if initialScore ~= Game.score then
        error("Game save and load failed")
    else
        print("Game save and load passed")
    end
    --#endregion

    --#region Test: Game undo after save and load initial state
    Game:initialize()
    Game.curGrid[1][1] = 2
    Game.curGrid[1][2] = 2
    Game.curGrid[3][1] = 4
    Game.curGrid[4][3] = 16
    
    local initialGrid = Game.curGrid:clone()
    local initialScore = Game.score
    
    Game:save("test.dat")
    Game:load("test.dat")

    Game:undo()

    if initialGrid ~= Game.curGrid then
        error("Game undo after save and load initial state failed")
    else
        print("Game undo after save and load initial state passed")
    end

    if initialScore ~= Game.score then
        error("Game undo after save and load initial state failed")
    else
        print("Game undo after save and load initial state passed")
    end
    --#endregion

    --#region Test: Game undo after save and load several moves
    Game:initialize()
    Game.curGrid[1][1] = 2
    Game.curGrid[1][2] = 2
    Game.curGrid[1][3] = 4
    Game.curGrid[4][3] = 16

    local initialGrids = {}
    local initialScores = {}
    table.insert(initialGrids, Game.curGrid:clone())
    table.insert(initialScores, Game.score)

    if Game:move("Left") then
        table.insert(initialGrids, Game.curGrid:clone())
        table.insert(initialScores, Game.score)
    end

    if Game:move("Left") then
        table.insert(initialGrids, Game.curGrid:clone())
        table.insert(initialScores, Game.score)
    end
    
    if Game:move("Left") then
        table.insert(initialGrids, Game.curGrid:clone())
        table.insert(initialScores, Game.score)
    end
    
    if Game:move("Up") then
        table.insert(initialGrids, Game.curGrid:clone())
        table.insert(initialScores, Game.score)
    end

    if Game:move("Right") then
        table.insert(initialGrids, Game.curGrid:clone())
        table.insert(initialScores, Game.score)
    end

    if Game:move("Down") then
        table.insert(initialGrids, Game.curGrid:clone())
        table.insert(initialScores, Game.score)
    end

    
    Game:save("test.dat")
    Game:load("test.dat")

    -- #initialGrids
    if #initialGrids ~= #Game.history then
        error("Game undo after save and load several moves failed, length of history does not match")
    else
        print("Game undo after save and load several moves passed")
    end

    for i = #initialGrids, 1, -1 do
        if initialGrids[i] ~= Game.curGrid then
            error("Game undo after save and load several moves failed, grids don't match")
        end

        if initialScores[i] ~= Game.score then
            error("Game undo after save and load several moves failed, scores don't match")
        end
        Game:undo()
    end

    print("Game undo after save and load several moves passed")
    --#endregion

end



-- Main ------------------------------------------------------------------------
function love.load()
    love.window.setTitle(Title_Prefix .. "0")
    love.window.setMode(Window_Width, Window_Height, nil)
    love.window.setFullscreen(false)
    -- love.window.setIcon(love.image.newImageData("assets/icon.png")) -- TODO: Fix icon

    love.graphics.setFont(love.graphics.newFont(24))

    
    Tests()


    Game:load()
end


function love.update(dt)
    input:update()

    if input:pressed("up") then
        Game:move("Up")

    elseif input:pressed("down") then
        Game:move("Down")
    
    elseif input:pressed("left") then
        Game:move("Left")
    
    elseif input:pressed("right") then
        Game:move("Right")
    

    elseif input:pressed("restart") then
        Game:restart()

    elseif input:pressed("undo") then
        if Game.gamestate == "game" then
            Game:undo()
        end
    
    elseif input:pressed("menuButton") then
        if Game.gamestate == "game" then
            Game.gamestate = "menu"

        elseif Game.gamestate == "menu" then
            Game.gamestate = "game"
        
        elseif Game.gamestate == "gameOver" then
            Game:restart()
        end
    
    elseif input:pressed("quit") then
        if Game.gamestate == "gameOver" or Game.gamestate == "menu" then
            love.event.quit()

        elseif Game.gamestate == "game" then
            Game.gamestate = "menu"

        end
    end
end


function love.keypressed(key)
    if key == "f11" then
        Tests()
    
    elseif key == "f12" then
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