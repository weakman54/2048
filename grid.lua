


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


return Grid