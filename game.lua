
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
    Game:initialize() -- Ensure everything is set TODO: Do this in main code instead?

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
    -- sort highscores
    table.sort(self.highscores, function(a, b) return a > b end)

    local highscoresStr = ""
    for _, score in ipairs(self.highscores) do
        highscoresStr = highscoresStr .. score .. '\n'
    end

    love.filesystem.write("highscores.dat", highscoresStr)
end

return Game