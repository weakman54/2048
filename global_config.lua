
-- TODO: make into "library"?

local baton = require("baton")

Input = baton.new({
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
})

Title_Prefix = "2048 clone, by weakman54. Score: "
Grid_Size = 4
Tile_Size = 100

Max_Value_Power = 20 -- Determines how the hues for Tiles are calculated, the "max value" is 2^Max_Value_Power, which will be hue 1 (blue/purple). The game can play past this, but I don't know what the colors will do

Window_Width  = Grid_Size * Tile_Size
Window_Height = Grid_Size * Tile_Size

Chance_Of_Four = 0.1

Debug_Print = false