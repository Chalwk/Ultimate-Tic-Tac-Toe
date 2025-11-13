-- Ultimate Tic-Tac-Toe Board
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local lg = love.graphics
local ipairs = ipairs
local insert, remove = table.insert, table.remove
local min, sin, floor = math.min, math.sin, math.floor

local Board = {}
Board.__index = Board

function Board.new()
    local instance = setmetatable({}, Board)

    instance:reset()
    instance:calculateDimensions()

    -- Animation states
    instance.animations = {}
    instance.lastAIMove = nil

    return instance
end

function Board:reset()
    -- Main board state: 3x3 grid of small boards
    self.boards = {}
    self.winners = {}    -- Track winners of each small board
    self.nextBoard = nil -- {row, col} or nil if free choice
    self.currentPlayer = "X"
    self.gameOver = false
    self.winner = nil
    self.animations = {}
    self.lastAIMove = nil

    -- Initialize all small boards
    for bigRow = 1, 3 do
        self.boards[bigRow] = {}
        self.winners[bigRow] = {}
        for bigCol = 1, 3 do
            self.boards[bigRow][bigCol] = {}
            self.winners[bigRow][bigCol] = nil
            for smallRow = 1, 3 do
                self.boards[bigRow][bigCol][smallRow] = {}
                for smallCol = 1, 3 do
                    self.boards[bigRow][bigCol][smallRow][smallCol] = nil
                end
            end
        end
    end
end

function Board:calculateDimensions()
    local padding = 20
    local availableWidth = screenWidth - padding * 2
    local availableHeight = screenHeight - padding * 2 - 150

    self.boardSize = min(availableWidth, availableHeight)
    self.cellSize = self.boardSize / 9 -- 3 big cells * 3 small cells each
    self.bigCellSize = self.cellSize * 3

    -- Move the board up by reducing the Y offset
    self.x = (screenWidth - self.boardSize) * 0.5
    self.y = (screenHeight - self.boardSize) * 0.5 - 20
end

function Board:getCurrentPlayer() return self.currentPlayer end

function Board:getNextBoard() return self.nextBoard end

function Board:getWinner() return self.winner end

function Board:getPossibleMoves()
    local moves = {}

    local targetBoards = {}
    if self.nextBoard then
        targetBoards = { self.nextBoard }
    else
        -- All boards that aren't won
        for bigRow = 1, 3 do
            for bigCol = 1, 3 do
                if not self.winners[bigRow][bigCol] then
                    insert(targetBoards, { row = bigRow, col = bigCol })
                end
            end
        end
    end

    for _, board in ipairs(targetBoards) do
        local bigRow, bigCol = board.row, board.col

        -- Skip if this board is already won
        if self.winners[bigRow][bigCol] then goto continue end

        for smallRow = 1, 3 do
            for smallCol = 1, 3 do
                if not self.boards[bigRow][bigCol][smallRow][smallCol] then
                    insert(moves, {
                        bigRow = bigRow,
                        bigCol = bigCol,
                        smallRow = smallRow,
                        smallCol = smallCol
                    })
                end
            end
        end

        ::continue::
    end

    return moves
end

function Board:wouldWinSmallBoard(bigRow, bigCol, smallRow, smallCol, player)
    -- Create a temporary copy to test the move
    local tempBoard = {}
    for r = 1, 3 do
        tempBoard[r] = {}
        for c = 1, 3 do
            tempBoard[r][c] = self.boards[bigRow][bigCol][r][c]
        end
    end

    -- Apply the move
    tempBoard[smallRow][smallCol] = player

    -- Check if this wins the small board
    return self:checkSmallBoardWin(tempBoard, player)
end

function Board:getCellPosition(bigRow, bigCol, smallRow, smallCol)
    local boardX = self.x + (bigCol - 1) * self.bigCellSize
    local boardY = self.y + (bigRow - 1) * self.bigCellSize
    local cellX = boardX + (smallCol - 1) * self.cellSize
    local cellY = boardY + (smallRow - 1) * self.cellSize
    return cellX + self.cellSize * 0.5, cellY + self.cellSize * 0.5
end

function Board:addAnimation(bigRow, bigCol, smallRow, smallCol, player)
    local anim = {
        bigRow = bigRow,
        bigCol = bigCol,
        smallRow = smallRow,
        smallCol = smallCol,
        player = player,
        progress = 0,
        duration = 0.3
    }
    insert(self.animations, anim)
end

function Board:makeMove(bigRow, bigCol, smallRow, smallCol)
    if self.gameOver then return false end

    -- Validate move
    if bigRow < 1 or bigRow > 3 or bigCol < 1 or bigCol > 3 or
        smallRow < 1 or smallRow > 3 or smallCol < 1 or smallCol > 3 then
        return false
    end

    -- Check if move is in the correct board
    if self.nextBoard and (self.nextBoard.row ~= bigRow or self.nextBoard.col ~= bigCol) then
        return false
    end

    -- Check if the target small board is already won
    if self.winners[bigRow][bigCol] then
        return false
    end

    -- Check if cell is empty
    if self.boards[bigRow][bigCol][smallRow][smallCol] then
        return false
    end

    -- Make the move
    self.boards[bigRow][bigCol][smallRow][smallCol] = self.currentPlayer

    -- Add animation for the move
    self:addAnimation(bigRow, bigCol, smallRow, smallCol, self.currentPlayer)

    -- Check if this move wins the small board
    if self:checkSmallBoardWin(self.boards[bigRow][bigCol], self.currentPlayer) then
        self.winners[bigRow][bigCol] = self.currentPlayer

        -- Check if this wins the big board
        if self:checkBigBoardWin(self.currentPlayer) then
            self.gameOver = true
            self.winner = self.currentPlayer
            return true
        end
    end

    -- Check if the entire board is full (draw)
    if self:isBoardFull() then
        self.gameOver = true
        self.winner = "draw"
        return true
    end

    -- Determine next board
    local targetBigRow, targetBigCol = smallRow, smallCol

    -- If the target board is already won or full, next player can choose any board
    if self.winners[targetBigRow][targetBigCol] or self:isSmallBoardFull(targetBigRow, targetBigCol) then
        self.nextBoard = nil
    else
        self.nextBoard = { row = targetBigRow, col = targetBigCol }
    end

    -- Switch player
    self.currentPlayer = self.currentPlayer == "X" and "O" or "X"

    return true
end

function Board:handleClick(x, y)
    -- Convert screen coordinates to board coordinates
    local relX, relY = x - self.x, y - self.y

    if relX < 0 or relX >= self.boardSize or relY < 0 or relY >= self.boardSize then
        return false
    end

    -- Calculate which big cell and small cell was clicked
    local bigCol = floor(relX / self.bigCellSize) + 1
    local bigRow = floor(relY / self.bigCellSize) + 1

    local smallX = relX - (bigCol - 1) * self.bigCellSize
    local smallY = relY - (bigRow - 1) * self.bigCellSize

    local smallCol = floor(smallX / self.cellSize) + 1
    local smallRow = floor(smallY / self.cellSize) + 1

    return self:makeMove(bigRow, bigCol, smallRow, smallCol)
end

function Board:checkSmallBoardWin(smallBoard, player)
    -- Check rows
    for row = 1, 3 do
        if smallBoard[row][1] == player and smallBoard[row][2] == player and smallBoard[row][3] == player then
            return true
        end
    end

    -- Check columns
    for col = 1, 3 do
        if smallBoard[1][col] == player and smallBoard[2][col] == player and smallBoard[3][col] == player then
            return true
        end
    end

    -- Check diagonals
    if smallBoard[1][1] == player and smallBoard[2][2] == player and smallBoard[3][3] == player then
        return true
    end

    if smallBoard[1][3] == player and smallBoard[2][2] == player and smallBoard[3][1] == player then
        return true
    end

    return false
end

function Board:checkBigBoardWin(player)
    -- Check rows
    for row = 1, 3 do
        if self.winners[row][1] == player and self.winners[row][2] == player and self.winners[row][3] == player then
            return true
        end
    end

    -- Check columns
    for col = 1, 3 do
        if self.winners[1][col] == player and self.winners[2][col] == player and self.winners[3][col] == player then
            return true
        end
    end

    -- Check diagonals
    if self.winners[1][1] == player and self.winners[2][2] == player and self.winners[3][3] == player then
        return true
    end

    if self.winners[1][3] == player and self.winners[2][2] == player and self.winners[3][1] == player then
        return true
    end

    return false
end

function Board:isSmallBoardFull(bigRow, bigCol)
    for smallRow = 1, 3 do
        for smallCol = 1, 3 do
            if not self.boards[bigRow][bigCol][smallRow][smallCol] then
                return false
            end
        end
    end
    return true
end

function Board:isBoardFull()
    for bigRow = 1, 3 do
        for bigCol = 1, 3 do
            if not self.winners[bigRow][bigCol] and not self:isSmallBoardFull(bigRow, bigCol) then
                return false
            end
        end
    end
    return true
end

function Board:update(dt)
    -- Update animations
    for i = #self.animations, 1, -1 do
        local anim = self.animations[i]
        anim.progress = anim.progress + dt / anim.duration
        if anim.progress >= 1 then
            remove(self.animations, i)
        end
    end
end

function Board:draw(time)
    self:calculateDimensions()

    -- Draw the big board background with subtle animation
    local pulse = 0.95 + 0.05 * sin(time * 2)
    lg.setColor(0.08 * pulse, 0.06 * pulse, 0.12 * pulse, 0.9)
    lg.rectangle("fill", self.x, self.y, self.boardSize, self.boardSize, 15)

    -- Draw board border with glow
    lg.setColor(0.4, 0.3, 0.8, 0.6)
    lg.setLineWidth(6)
    lg.rectangle("line", self.x, self.y, self.boardSize, self.boardSize, 15)

    -- Draw the big grid lines (thicker with glow)
    lg.setColor(0.6, 0.5, 0.9, 0.8)
    lg.setLineWidth(5)

    for i = 1, 2 do
        local x = self.x + i * self.bigCellSize
        lg.line(x, self.y, x, self.y + self.boardSize)
    end

    for i = 1, 2 do
        local y = self.y + i * self.bigCellSize
        lg.line(self.x, y, self.x + self.boardSize, y)
    end

    -- Draw each small board
    for bigRow = 1, 3 do
        for bigCol = 1, 3 do
            local boardX = self.x + (bigCol - 1) * self.bigCellSize
            local boardY = self.y + (bigRow - 1) * self.bigCellSize

            -- Highlight active board if next move is restricted
            if self.nextBoard and self.nextBoard.row == bigRow and self.nextBoard.col == bigCol then
                local glow = 0.7 + 0.3 * sin(time * 3)
                lg.setColor(0.3, 0.3, 0.8, 0.4 * glow)
                lg.rectangle("fill", boardX, boardY, self.bigCellSize, self.bigCellSize, 8)

                -- Border glow for active board
                lg.setColor(0.5, 0.5, 1, glow)
                lg.setLineWidth(3)
                lg.rectangle("line", boardX, boardY, self.bigCellSize, self.bigCellSize, 8)
            end

            -- Draw small board winner or grid
            if self.winners[bigRow][bigCol] then
                -- This small board has been won
                local winner = self.winners[bigRow][bigCol]
                local alpha = 0.7 + 0.3 * sin(time * 2)

                if winner == "X" then
                    lg.setColor(1, 0.3, 0.3, alpha)
                else
                    lg.setColor(0.3, 0.6, 1, alpha)
                end
                lg.rectangle("fill", boardX, boardY, self.bigCellSize, self.bigCellSize, 8)

                lg.setColor(1, 1, 1, 1)
                local font = lg.newFont(self.bigCellSize * 0.6)
                lg.setFont(font)
                lg.printf(winner, boardX, boardY + self.bigCellSize * 0.5 - font:getHeight() * 0.5, self.bigCellSize,
                    "center")
            else
                -- Draw the small grid lines
                lg.setColor(0.5, 0.4, 0.7, 0.6)
                lg.setLineWidth(2)

                for i = 1, 2 do
                    local x = boardX + i * self.cellSize
                    lg.line(x, boardY, x, boardY + self.bigCellSize)
                end

                for i = 1, 2 do
                    local y = boardY + i * self.cellSize
                    lg.line(boardX, y, boardX + self.bigCellSize, y)
                end

                -- Draw marks in this small board
                for smallRow = 1, 3 do
                    for smallCol = 1, 3 do
                        local mark = self.boards[bigRow][bigCol][smallRow][smallCol]
                        local cellX = boardX + (smallCol - 1) * self.cellSize
                        local cellY = boardY + (smallRow - 1) * self.cellSize
                        local padding = self.cellSize * 0.15

                        if mark then
                            -- Check if this mark has an animation
                            local animProgress = 1
                            for _, anim in ipairs(self.animations) do
                                if anim.bigRow == bigRow and anim.bigCol == bigCol and
                                    anim.smallRow == smallRow and anim.smallCol == smallCol then
                                    animProgress = anim.progress
                                    break
                                end
                            end

                            if mark == "X" then
                                lg.setColor(1, 0.4, 0.4, 1)
                                lg.setLineWidth(4 * animProgress)

                                local offset = padding * (1 - animProgress)
                                lg.line(
                                    cellX + padding + offset, cellY + padding + offset,
                                    cellX + self.cellSize - padding - offset, cellY + self.cellSize - padding - offset
                                )
                                lg.line(
                                    cellX + self.cellSize - padding - offset, cellY + padding + offset,
                                    cellX + padding + offset, cellY + self.cellSize - padding - offset
                                )
                            else -- "O"
                                lg.setColor(0.4, 0.7, 1, 1)
                                lg.setLineWidth(4 * animProgress)
                                lg.circle("line",
                                    cellX + self.cellSize * 0.5,
                                    cellY + self.cellSize * 0.5,
                                    (self.cellSize * 0.4) * animProgress
                                )
                            end
                        end
                    end
                end
            end
        end
    end

    lg.setLineWidth(1)
end

function Board:screenResize()
    self:calculateDimensions()
end

return Board
