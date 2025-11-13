-- Ultimate Tic-Tac-Toe
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local SoundManager = require("src.managers.SoundManager")
local Board = require("src.entities.Board")

local lg = love.graphics
local random = love.math.random

local Game = {}
Game.__index = Game

local board

local function drawUI(self)
    local font = self.fonts:getFont("mediumFont")
    self.fonts:setFont(font)

    -- Current player indicator
    local currentPlayer = board:getCurrentPlayer()
    local playerText = "Current Player: " .. currentPlayer
    local modeText = "Mode: " .. (self.gameMode == "pvp" and "Player vs Player" or "Player vs AI")

    lg.setColor(1, 1, 1, 0.8)
    lg.print(playerText, 20, 20)
    lg.print(modeText, 20, 50)

    -- Instructions
    local nextBoard = board:getNextBoard()
    local instruction = nextBoard and
        "Next move must be in board: " .. (nextBoard.row) .. "," .. (nextBoard.col) or
        "You can play in any available board"

    lg.print(instruction, 20, screenHeight - 40)
end

local function drawGameOver(self)
    lg.setColor(0, 0, 0, 0.7)
    lg.rectangle("fill", 0, 0, screenWidth, screenHeight)

    lg.setColor(1, 1, 1, 1)
    self.fonts:setFont("largeFont")

    local winner = board:getWinner()
    local message = "Game Over - "

    if winner == "draw" then
        message = message .. "It's a Draw!"
    else
        message = message .. "Player " .. winner .. " Wins!"
    end

    lg.printf(message, 0, screenHeight * 0.4, screenWidth, "center")

    self.fonts:setFont("mediumFont")
    lg.printf("Click anywhere to return to menu", 0, screenHeight * 0.5, screenWidth, "center")
end

function Game.new(fontManager)
    local instance = setmetatable({}, Game)

    instance.fonts = fontManager
    instance.gameOver = false
    instance.won = false
    instance.paused = false
    instance.gameMode = "pvp"
    instance.difficulty = "easy"

    instance.sounds = SoundManager.new()
    board = Board.new()

    return instance
end

function Game:isGameOver() return self.gameOver end

function Game:isPaused() return self.paused end

function Game:setPaused(paused) self.paused = paused end

function Game:getGameMode() return self.gameMode end

function Game:startNewGame(mode, difficulty)
    self.gameMode = mode or "pvp"
    self.difficulty = difficulty or "easy"
    self.gameOver = false
    self.won = false
    self.paused = false
    board:reset()
end

function Game:handleClick(x, y)
    if self.gameOver or self.paused then return end

    local success = board:handleClick(x, y)

    if success and self.gameMode == "pvc" and board:getCurrentPlayer() == "O" then
        self:makeAIMove()
    end

    -- Check for game over
    local winner = board:getWinner()
    if winner then
        self.gameOver = true
        self.won = winner ~= "draw"
    end
end

function Game:makeAIMove()
    -- TODO: Implement minimax with alpha-beta pruning for AI

    local possibleMoves = board:getPossibleMoves()
    if #possibleMoves == 0 then return end

    if self.difficulty == "easy" then
        -- Random move
        local move = possibleMoves[random(1, #possibleMoves)]
        board:makeMove(move.bigRow, move.bigCol, move.smallRow, move.smallCol)
    elseif self.difficulty == "medium" then
        -- Try to win if possible, otherwise block, otherwise random
        local move = self:findStrategicMove(possibleMoves)
        board:makeMove(move.bigRow, move.bigCol, move.smallRow, move.smallCol)
    else -- hard
        -- More advanced strategy
        local move = self:findBestMove(possibleMoves)
        board:makeMove(move.bigRow, move.bigCol, move.smallRow, move.smallCol)
    end

    -- Check for game over after AI move
    local winner = board:getWinner()
    if winner then
        self.gameOver = true
        self.won = winner ~= "draw"
    end
end

function Game:findStrategicMove(possibleMoves)
    -- Simple strategy: try to win, then block, then take center, then random
    for _, move in ipairs(possibleMoves) do
        -- Check if this move would win the small board
        if board:wouldWinSmallBoard(move.bigRow, move.bigCol, move.smallRow, move.smallCol, "O") then
            return move
        end
    end

    for _, move in ipairs(possibleMoves) do
        -- Check if this move would block opponent from winning small board
        if board:wouldWinSmallBoard(move.bigRow, move.bigCol, move.smallRow, move.smallCol, "X") then
            return move
        end
    end

    -- Prefer center squares
    for _, move in ipairs(possibleMoves) do
        if move.smallRow == 2 and move.smallCol == 2 then
            return move
        end
    end

    -- Otherwise random
    return possibleMoves[random(1, #possibleMoves)]
end

function Game:findBestMove(possibleMoves)
    -- TODO: implement minimax algorithm to find best move
    return self:findStrategicMove(possibleMoves)
end

function Game:update(dt)
    if self.paused or self.gameOver then return end
    board:update(dt)
end

function Game:draw(time)
    lg.push()
    board:draw(time)
    drawUI(self)

    if self.gameOver then drawGameOver(self) end

    lg.pop()
end

function Game:screenResize()
    if board and board.screenResize then
        board:screenResize()
    end
end

return Game
