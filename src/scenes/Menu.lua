-- GAME_NAME_HERE
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local lg = love.graphics
local ipairs, sin = ipairs, math.sin

local BUTTON_DATA = {
    MENU = {
        { text = "PLAYER VS PLAYER", action = "start_pvp", width = 300, height = 55, color = { 0.7, 0.7, 0.7 } },
        { text = "PLAYER VS AI", action = "start_pvc", width = 300, height = 55, color = { 0.5, 0.6, 0.9 } },
        { text = "OPTIONS", action = "options", width = 300, height = 55, color = { 0.5, 0.6, 0.9 } },
        { text = "QUIT", action = "quit", width = 300, height = 55, color = { 0.9, 0.4, 0.3 } }
    },
    PAUSE = {
        { text = "RESUME", action = "resume", width = 240, height = 56, color = { 0.18, 0.72, 0.35 } },
        { text = "RESTART", action = "restart", width = 240, height = 56, color = { 0.95, 0.7, 0.18 } },
        { text = "MAIN MENU", action = "menu", width = 240, height = 56, color = { 0.82, 0.28, 0.32 } }
    },
    OPTIONS = {
        { text = "EASY", action = "diff easy", width = 110, height = 40, color = { 0.5, 0.9, 0.5 }, section = "difficulty" },
        { text = "MEDIUM", action = "diff medium", width = 110, height = 40, color = { 0.9, 0.8, 0.4 }, section = "difficulty" },
        { text = "HARD", action = "diff hard", width = 110, height = 40, color = { 0.9, 0.5, 0.4 }, section = "difficulty" },
        { text = "RETURN TO MENU", action = "back", width = 200, height = 45, color = { 0.6, 0.6, 0.6 }, section = "navigation" }
    }
}

local HELP_TEXT = {
    "Welcome to Ultimate Tic-Tac-Toe!",
    "",
    "How to Play:",
    "• The game is played on a 3x3 grid of smaller 3x3 boards",
    "• Your move in a small board determines where your opponent plays next",
    "• Win a small board by getting 3 in a row",
    "• Win the game by winning 3 small boards in a row on the big board",
    "• If sent to a completed board, you can play anywhere",
    "",
    "Controls:",
    "• Click to place your mark",
    "• ESC to pause the game",
    "• F11 to toggle fullscreen",
    "",
    "Click anywhere to close."
}

local Menu = {}
Menu.__index = Menu

local LAYOUT = {
    DIFF_BUTTON = { W = 110, H = 40, SPACING = 20 },
    TOTAL_SECTIONS_HEIGHT = 280,
    HELP_BOX = { W = 650, H = 600, LINE_HEIGHT = 24 }
}

local function createButton(data, x, y)
    return {
        text = data.text,
        action = data.action,
        x = x or 0,
        y = y or 0,
        width = data.width,
        height = data.height,
        color = data.color,
        section = data.section
    }
end

local function drawButton(self, button)
    local isHovered = self.buttonHover == button.action
    local pulse = sin(self.time * 6) * 0.1 + 0.9
    local glow = isHovered and 0.25 or 0.1

    -- Button background with hover effect
    lg.setColor(button.color[1] + glow, button.color[2] + glow, button.color[3] + glow, 0.9)
    lg.rectangle("fill", button.x, button.y, button.width, button.height, 12)

    -- Border highlight
    lg.setColor(1, 0.7, 0.2, isHovered and 1 or 0.6)
    lg.setLineWidth(isHovered and 3 or 2)
    lg.rectangle("line", button.x, button.y, button.width, button.height, 12)

    -- Text with shadow and pulse effect
    local font = self.fonts:getFont("mediumFont")
    self.fonts:setFont(font)
    local textX = button.x + (button.width - font:getWidth(button.text)) * 0.5
    local textY = button.y + (button.height - font:getHeight()) * 0.5

    lg.setColor(0, 0, 0, 0.5)
    lg.print(button.text, textX + 2, textY + 2)
    lg.setColor(1, 1, 1, pulse)
    lg.print(button.text, textX, textY)

    lg.setLineWidth(1)
end

local function createButtonSet(buttonData, layoutFn)
    local buttons = {}
    for _, data in ipairs(buttonData) do
        buttons[#buttons + 1] = createButton(data)
    end
    layoutFn(buttons)
    return buttons
end

local function layoutMenuButtons(buttons)
    local startY = screenHeight * 0.5 - 80
    for i, button in ipairs(buttons) do
        button.x = (screenWidth - button.width) * 0.5
        button.y = startY + (i - 1) * 70
    end
end

local function layoutPauseButtons(buttons)
    local centerX, centerY = screenWidth * 0.5, screenHeight * 0.5
    for i, button in ipairs(buttons) do
        button.x = centerX - 120
        button.y = centerY - 70 + (i - 1) * 76
    end
end

local function layoutOptionsButtons(buttons)
    local centerX, centerY = screenWidth * 0.5, screenHeight * 0.5
    local startY = centerY - LAYOUT.TOTAL_SECTIONS_HEIGHT * 0.5

    local diffTotalW = 3 * LAYOUT.DIFF_BUTTON.W + 2 * LAYOUT.DIFF_BUTTON.SPACING
    local diffStartX = centerX - diffTotalW * 0.5
    local diffY = startY + 40
    local navY = startY + 278

    for i, button in ipairs(buttons) do
        if button.section == "difficulty" then
            button.x = diffStartX + (i - 1) * (LAYOUT.DIFF_BUTTON.W + LAYOUT.DIFF_BUTTON.SPACING)
            button.y = diffY
        elseif button.section == "navigation" then
            button.x = centerX - button.width * 0.5
            button.y = navY
        end
    end
end

local function updateTitleAnimation(self, dt)
    self.title.scale = self.title.scale + self.title.scaleDirection * self.title.scaleSpeed * dt
    self.title.glow = sin(self.time * 3) * 0.3 + 0.7

    if self.title.scale > self.title.maxScale then
        self.title.scale, self.title.scaleDirection = self.title.maxScale, -1
    elseif self.title.scale < self.title.minScale then
        self.title.scale, self.title.scaleDirection = self.title.minScale, 1
    end
end

local function drawGameTitle(self)
    local cx, cy = screenWidth * 0.5, screenHeight * 0.2
    lg.push()
    lg.translate(cx, cy)
    lg.scale(1.6, 1.6)

    local font = self.fonts:getFont("largeFont")
    self.fonts:setFont(font)
    local fontH = font:getHeight(self.title.text) * 0.5
    local offset = 55

    lg.setColor(0, 0, 0, 0.5)
    lg.printf(self.title.text, -300 + 4, -fontH + 4 - offset, 600, "center")
    lg.setColor(1, 0.7, 0.2, self.title.glow)
    lg.printf(self.title.text, -300, -fontH - offset, 600, "center")
    lg.pop()

    -- Draw subtitle
    lg.setColor(0.9, 0.9, 0.9, 0.8)
    self.fonts:setFont("mediumFont")
    lg.printf(self.title.subtitle, 0, screenHeight * 0.20, screenWidth, "center")
end

local function drawPauseMenu(self)
    lg.setColor(0, 0, 0, 0.7)
    lg.rectangle("fill", 0, 0, screenWidth, screenHeight)

    lg.setColor(1, 1, 1, 1)
    self.fonts:setFont("largeFont")
    lg.printf("PAUSED", 0, screenHeight * 0.3, screenWidth, "center")

    for _, button in ipairs(self.pauseButtons) do
        drawButton(self, button)
    end
end

local function drawHelpOverlay(self)
    for i = 1, 3 do
        local alpha = 0.9 - (i * 0.2)
        lg.setColor(0, 0, 0, alpha)
        lg.rectangle("fill", -i, -i, screenWidth + i * 2, screenHeight + i * 2)
    end

    local box = LAYOUT.HELP_BOX
    local boxX = (screenWidth - box.W) * 0.5
    local boxY = (screenHeight - box.H) * 0.5

    -- Gradient background
    for y = boxY, boxY + box.H do
        local p = (y - boxY) / box.H
        lg.setColor(0.05 + p * 0.08, 0.04 + p * 0.05, 0.06 + p * 0.08, 0.98)
        lg.line(boxX, y, boxX + box.W, y)
    end

    lg.setColor(1, 0.7, 0.2, 0.8)
    lg.setLineWidth(3)
    lg.rectangle("line", boxX, boxY, box.W, box.H, 12)

    -- Help text
    lg.setColor(1, 1, 1)
    self.fonts:setFont("mediumFont")
    lg.printf("GAME_NAME_HERE - HOW TO PLAY", boxX, boxY + 25, box.W, "center")

    self.fonts:setFont("smallFont")
    for i, line in ipairs(HELP_TEXT) do
        local y = boxY + 90 + (i - 1) * box.LINE_HEIGHT
        lg.setColor(line:sub(1, 2) == "• " and { 1, 0.7, 0.3 } or { 0.9, 0.9, 0.9 })
        lg.printf(line, boxX + 40, y, box.W - 80, "left")
    end

    lg.setLineWidth(1)
end

function Menu.new(fontManager)
    local instance = setmetatable({}, Menu)

    instance.difficulty = "easy"
    instance.showHelp = false
    instance.time = 0
    instance.buttonHover = nil
    instance.fonts = fontManager

    instance.title = {
        text = "ULTIMATE TIC-TAC-TOE",
        subtitle = "The Strategic Evolution of a Classic",
        scale = 1,
        scaleDirection = 1,
        scaleSpeed = 0.4,
        minScale = 0.92,
        maxScale = 1.08,
        glow = 0
    }

    -- Create all button sets
    instance.menuButtons = createButtonSet(BUTTON_DATA.MENU, layoutMenuButtons)
    instance.pauseButtons = createButtonSet(BUTTON_DATA.PAUSE, layoutPauseButtons)
    instance.optionsButtons = createButtonSet(BUTTON_DATA.OPTIONS, layoutOptionsButtons)

    -- Help button (special case)
    instance.helpButton = createButton({
        text = "?", action = "help", width = 50, height = 50, color = { 0.8, 0.6, 0.3 }
    }, 10, screenHeight - 60)

    return instance
end

function Menu:update(dt)
    self.time = self.time + dt
    updateTitleAnimation(self, dt)
    self:updateButtonHover(love.mouse.getX(), love.mouse.getY())
end

function Menu:updateButtonHover(x, y)
    self.buttonHover = nil

    if self.showHelp then return end

    local buttons = self.state == "pause" and self.pauseButtons or
        self.state == "options" and self.optionsButtons or
        self.menuButtons

    for _, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.width and
            y >= button.y and y <= button.y + button.height then
            self.buttonHover = button.action
            return
        end
    end

    -- Check help button in main menu
    if self.state == "menu" and self.helpButton then
        local hb = self.helpButton
        if x >= hb.x and x <= hb.x + hb.width and y >= hb.y and y <= hb.y + hb.height then
            self.buttonHover = "help"
        end
    end
end

function Menu:draw(state)
    self.state = state

    if state == "pause" then
        drawPauseMenu(self)
    else
        drawGameTitle(self)

        if state == "menu" then
            if self.showHelp then
                drawHelpOverlay(self)
            else
                for _, button in ipairs(self.menuButtons) do
                    drawButton(self, button)
                end

                lg.setColor(0.9, 0.9, 0.9, 0.8)
                self.fonts:setFont("mediumFont")
                lg.printf(self.title.subtitle, 0, screenHeight * 0.20, screenWidth, "center")

                -- Draw help button
                local hb = self.helpButton
                local isHovered = self.buttonHover == "help"
                local pulse = sin(self.time * 5) * 0.2 + 0.8
                local cx, cy = hb.x + hb.width * 0.5, hb.y + hb.height * 0.5

                lg.setColor(hb.color[1], hb.color[2], hb.color[3], isHovered and 1 or 0.8)
                lg.circle("fill", cx, cy, hb.width * 0.5)
                lg.setColor(1, 0.7, 0.2, isHovered and 1 or 0.6)
                lg.setLineWidth(isHovered and 3 or 2)
                lg.circle("line", cx, cy, hb.width * 0.5)

                lg.setColor(1, 1, 1, pulse)
                local font = self.fonts:getFont("mediumFont")
                self.fonts:setFont(font)
                local w, h = font:getWidth(hb.text), font:getHeight()
                lg.print(hb.text, hb.x + (hb.width - w) * 0.5, hb.y + (hb.height - h) * 0.5)
                lg.setLineWidth(1)
            end
        elseif state == "options" then
            layoutOptionsButtons(self.optionsButtons)

            local startY = (screenHeight - LAYOUT.TOTAL_SECTIONS_HEIGHT) * 0.5
            lg.setColor(1, 0.7, 0.3)
            self.fonts:setFont("sectionFont")
            lg.printf("Difficulty", 0, startY, screenWidth, "center")

            for _, button in ipairs(self.optionsButtons) do
                drawButton(self, button)
                if button.section == "difficulty" and self.difficulty == button.action:sub(6) then
                    lg.setColor(1, 0.7, 0.2, 0.2)
                    lg.rectangle("fill", button.x - 5, button.y - 5, button.width + 10, button.height + 10, 8)
                    lg.setColor(1, 0.7, 0.2, 0.8)
                    lg.setLineWidth(3)
                    lg.rectangle("line", button.x - 5, button.y - 5, button.width + 10, button.height + 10, 8)
                    lg.setLineWidth(1)
                end
            end
        end
    end

    -- Footer
    lg.setColor(1, 1, 1, 0.6)
    self.fonts:setFont("smallFont")
    lg.printf("© 2025 Jericho Crosby - GAME_NAME_HERE", 10, screenHeight - 30, screenWidth - 20, "right")
end

function Menu:handleClick(x, y, state)
    if state == "menu" and self.showHelp then
        self.showHelp = false
        return "help_close"
    end

    local buttons = self.state == "pause" and self.pauseButtons or
        self.state == "options" and self.optionsButtons or
        self.menuButtons

    for _, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.width and
            y >= button.y and y <= button.y + button.height then
            return button.action
        end
    end

    if state == "menu" and self.helpButton then
        local hb = self.helpButton
        if x >= hb.x and x <= hb.x + hb.width and y >= hb.y and y <= hb.y + hb.height then
            self.showHelp = true
            return "help"
        end
    end

    return nil
end

function Menu:setDifficulty(d) self.difficulty = d end

function Menu:getDifficulty() return self.difficulty end

function Menu:screenResize()
    layoutMenuButtons(self.menuButtons)
    layoutPauseButtons(self.pauseButtons)
    layoutOptionsButtons(self.optionsButtons)
    self.helpButton.y = screenHeight - 60
end

return Menu
