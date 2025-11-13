-- Ultimate Tic-Tac-Toe
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local SoundManager = require("src.managers.SoundManager")
local Board = require("src.entities.Board")

local lg = love.graphics
local random = love.math.random
local newImageData = love.image.newImageData

local sin, PI = math.sin, math.pi
local remove = table.remove

local Game = {}
Game.__index = Game

-- Create a simple 1x1 white pixel for particles
local function createParticleImage()
    local imageData = newImageData(1, 1)
    imageData:setPixel(0, 0, 1, 1, 1, 1) -- White pixel
    return lg.newImage(imageData)
end

local particleImage = createParticleImage()

local function createParticleSystem()
    local ps = lg.newParticleSystem(particleImage, 100)
    ps:setColors(1, 1, 1, 1, 1, 1, 1, 0)
    ps:setSizes(0.5, 0.2)
    ps:setSizeVariation(0.5)
    ps:setLinearAcceleration(-20, -20, 20, 20)
    ps:setEmissionRate(50)
    ps:setEmitterLifetime(0.1)
    ps:setParticleLifetime(0.5, 1.0)
    ps:setSpread(2 * PI)
    ps:setSpeed(50, 100)
    return ps
end

local function drawBackground(time)
    -- Animated gradient background
    local r1, g1, b1 = 0.08, 0.06, 0.15
    local r2, g2, b2 = 0.12, 0.08, 0.25

    for i = 0, screenHeight, 4 do
        local ratio = (i + time * 20) % screenHeight / screenHeight
        local r = r1 + (r2 - r1) * sin(ratio * PI)
        local g = g1 + (g2 - g1) * sin(ratio * PI)
        local b = b1 + (b2 - b1) * sin(ratio * PI)

        lg.setColor(r, g, b, 0.3)
        lg.rectangle("fill", 0, i, screenWidth, 4)
    end
end

local function drawUI(self, time)
    local font = self.fonts:getFont("mediumFont")
    self.fonts:setFont(font)

    -- Current player indicator with glow effect
    local currentPlayer = self.board:getCurrentPlayer()
    local playerText = "Current Player: "

    -- Player indicator with colored text
    lg.setColor(1, 1, 1, 0.9)
    lg.print(playerText, 30, 25)

    if currentPlayer == "X" then
        lg.setColor(1, 0.3, 0.3, 1)
    else
        lg.setColor(0.3, 0.6, 1, 1)
    end
    lg.print(currentPlayer, 30 + font:getWidth(playerText), 25)

    -- Mode indicator
    lg.setColor(1, 1, 1, 0.8)
    local modeText = "Mode: " .. (self.gameMode == "pvp" and "Player vs Player" or "Player vs AI")
    lg.print(modeText, 30, 60)

    -- Difficulty indicator (if applicable)
    if self.gameMode == "pvc" then
        lg.setColor(1, 1, 1, 0.7)
        local diffText = "Difficulty: " .. self.difficulty
        lg.print(diffText, 30, 85)
    end

    -- Instructions with animated background
    local nextBoard = self.board:getNextBoard()
    local instruction = nextBoard and
        "Next move must be in board: " .. (nextBoard.row) .. "," .. (nextBoard.col) or
        "You can play in any available board"

    -- Instruction background
    local textWidth = font:getWidth(instruction) + 40
    local textHeight = 40
    local instructionY = screenHeight - 50

    -- Animated instruction background
    local pulse = 0.7 + 0.3 * sin(time * 4)
    lg.setColor(0.1, 0.1, 0.2, 0.8 * pulse)
    lg.rectangle("fill", (screenWidth - textWidth) * 0.5, instructionY, textWidth, textHeight, 10)

    lg.setColor(0.5, 0.8, 1, 1)
    lg.rectangle("line", (screenWidth - textWidth) * 0.5, instructionY, textWidth, textHeight, 10)

    lg.setColor(1, 1, 1, 1)
    lg.printf(instruction, 0, instructionY, screenWidth, "center")
end

local function drawGameOver(self, time)
    -- Animated overlay
    local pulse = 0.8 + 0.2 * sin(time * 3)
    lg.setColor(0, 0, 0, 0.8 * pulse)
    lg.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Victory banner
    lg.setColor(0.2, 0.1, 0.3, 0.9)
    local bannerHeight = 150
    lg.rectangle("fill", 0, screenHeight * 0.35, screenWidth, bannerHeight)

    -- Banner border
    lg.setColor(0.6, 0.3, 1, 1)
    lg.setLineWidth(3)
    lg.rectangle("line", 0, screenHeight * 0.35, screenWidth, bannerHeight)

    -- Game over text
    lg.setColor(1, 1, 1, 1)
    self.fonts:setFont("largeFont")

    local winner = self.board:getWinner()
    local message = "Game Over - "

    if winner == "draw" then
        message = message .. "It's a Draw!"
        lg.setColor(0.8, 0.8, 0.3, 1)
    else
        message = message .. "Player " .. winner .. " Wins!"
        if winner == "X" then
            lg.setColor(1, 0.4, 0.4, 1)
        else
            lg.setColor(0.4, 0.7, 1, 1)
        end
    end

    -- Text shadow
    lg.setColor(0, 0, 0, 0.5)
    lg.printf(message, 2, screenHeight * 0.4 + 2, screenWidth, "center")

    -- Main text
    if winner == "draw" then
        lg.setColor(1, 1, 0.5, 1)
    elseif winner == "X" then
        lg.setColor(1, 0.6, 0.6, 1)
    else
        lg.setColor(0.6, 0.8, 1, 1)
    end
    lg.printf(message, 0, screenHeight * 0.4, screenWidth, "center")

    -- Continue prompt
    self.fonts:setFont("mediumFont")
    local promptPulse = 0.5 + 0.5 * sin(time * 2)
    lg.setColor(1, 1, 1, promptPulse)
    lg.printf("Click anywhere to return to menu", 0, screenHeight * 0.55, screenWidth, "center")
end

function Game.new(fontManager)
    local instance = setmetatable({}, Game)

    instance.fonts = fontManager
    instance.gameOver = false
    instance.won = false
    instance.paused = false
    instance.gameMode = "pvp"
    instance.difficulty = "easy"
    instance.particles = {}

    instance.sounds = SoundManager.new()
    instance.board = Board.new()

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
    self.particles = {}
    self.board:reset()
end

function Game:addParticles(x, y, color)
    local ps = createParticleSystem()
    ps:setPosition(x, y)
    if color == "X" then
        ps:setColors(1, 0.3, 0.3, 1, 1, 0.6, 0.6, 0)
    else
        ps:setColors(0.3, 0.6, 1, 1, 0.6, 0.8, 1, 0)
    end
    ps:emit(30)
    table.insert(self.particles, { system = ps, life = 1.0 })
end

function Game:handleClick(x, y)
    if self.gameOver or self.paused then return end

    local success = self.board:handleClick(x, y)

    if success then
        -- Add particles at click position
        self:addParticles(x, y, self.board:getCurrentPlayer() == "X" and "O" or "X")

        if self.gameMode == "pvc" and self.board:getCurrentPlayer() == "O" then
            -- AI's turn
            self:makeAIMove()
        end
    end

    -- Check for game over
    local winner = self.board:getWinner()
    if winner then
        self.gameOver = true
        self.won = winner ~= "draw"
        -- Add celebration particles on game over
        if winner ~= "draw" then
            for _ = 1, 50 do
                local x = random(0, screenWidth)
                local y = random(0, screenHeight)
                self:addParticles(x, y, winner)
            end
        end
    end
end

function Game:makeAIMove()
    -- Simple AI implementation
    local possibleMoves = self.board:getPossibleMoves()
    if #possibleMoves == 0 then return end

    if self.difficulty == "easy" then
        -- Random move
        local move = possibleMoves[random(1, #possibleMoves)]
        self.board:makeMove(move.bigRow, move.bigCol, move.smallRow, move.smallCol)
    elseif self.difficulty == "medium" then
        -- Try to win if possible, otherwise block, otherwise random
        local move = self:findStrategicMove(possibleMoves)
        self.board:makeMove(move.bigRow, move.bigCol, move.smallRow, move.smallCol)
    else -- hard
        -- More advanced strategy
        local move = self:findBestMove(possibleMoves)
        self.board:makeMove(move.bigRow, move.bigCol, move.smallRow, move.smallCol)
    end

    -- Add particles for AI move
    if self.board.lastAIMove then
        local move = self.board.lastAIMove
        local cellX, cellY = self.board:getCellPosition(move.bigRow, move.bigCol, move.smallRow, move.smallCol)
        self:addParticles(cellX, cellY, "O")
    end

    -- Check for game over after AI move
    local winner = self.board:getWinner()
    if winner then
        self.gameOver = true
        self.won = winner ~= "draw"
    end
end

function Game:findStrategicMove(possibleMoves)
    -- Simple strategy: try to win, then block, then take center, then random
    for _, move in ipairs(possibleMoves) do
        -- Check if this move would win the small board
        if self.board:wouldWinSmallBoard(move.bigRow, move.bigCol, move.smallRow, move.smallCol, "O") then
            self.board.lastAIMove = move
            return move
        end
    end

    for _, move in ipairs(possibleMoves) do
        -- Check if this move would block opponent from winning small board
        if self.board:wouldWinSmallBoard(move.bigRow, move.bigCol, move.smallRow, move.smallCol, "X") then
            self.board.lastAIMove = move
            return move
        end
    end

    -- Prefer center squares
    for _, move in ipairs(possibleMoves) do
        if move.smallRow == 2 and move.smallCol == 2 then
            self.board.lastAIMove = move
            return move
        end
    end

    -- Otherwise random
    local move = possibleMoves[random(1, #possibleMoves)]
    self.board.lastAIMove = move
    return move
end

function Game:findBestMove(possibleMoves)
    --TODO: Implementation of minimax algorithm
    return self:findStrategicMove(possibleMoves)
end

function Game:update(dt)
    if self.paused or self.gameOver then return end
    self.board:update(dt)

    -- Update particles
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.system:update(dt)
        particle.life = particle.life - dt
        if particle.life <= 0 then remove(self.particles, i) end
    end
end

function Game:draw(time)
    lg.push()

    -- Draw animated background
    drawBackground(time)

    -- Draw particles
    for _, particle in ipairs(self.particles) do lg.draw(particle.system) end

    -- Draw board and UI
    self.board:draw(time)
    drawUI(self, time)

    if self.gameOver then drawGameOver(self, time) end

    lg.pop()
end

function Game:screenResize()
    if self.board and self.board.screenResize then self.board:screenResize() end
end

return Game
