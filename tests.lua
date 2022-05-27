
local Game = require("game")
local Grid = require("grid")

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