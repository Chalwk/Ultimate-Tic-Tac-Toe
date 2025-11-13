-- Ultimate Tic-Tac-Toe Player
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local Player = {}
Player.__index = Player

function Player.new(type, symbol)
    local instance = setmetatable({}, Player)
    instance.type = type     -- "human" or "ai"
    instance.symbol = symbol -- "X" or "O"
    return instance
end

return Player
