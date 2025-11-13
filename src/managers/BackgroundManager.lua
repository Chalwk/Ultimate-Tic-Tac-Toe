-- Ultimate Tic-Tac-Toe
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local lg = love.graphics
local random = love.math.random
local sin, pi = math.sin, math.pi

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

local function initObjects(self)
    self.objects = {}
    -- Mini tic-tac-toe boards
    for _ = 1, 50 do
        local size = random(40, 80)
        self.objects[#self.objects + 1] = {
            type = "board",
            x = random(0, screenWidth),
            y = random(0, screenHeight),
            size = size,
            rotation = random() * pi * 2,
            rotationSpeed = (random() - 0.5) * 0.5,
            alpha = random() * 0.3 + 0.2,
            cells = {} -- X or O
        }
        -- Randomly fill cells with X or O
        for i = 1, 9 do
            local choice = random() < 0.5 and "X" or "O"
            self.objects[#self.objects].cells[i] = choice
        end
    end
    -- Twinkling dots as highlights
    for _ = 1, 150 do
        self.objects[#self.objects + 1] = {
            type = "dot",
            x = random(0, screenWidth),
            y = random(0, screenHeight),
            size = random(1, 3),
            alpha = random() * 0.8 + 0.2,
            twinkleSpeed = random(1, 4)
        }
    end
end

function BackgroundManager.new()
    local instance = setmetatable({}, BackgroundManager)
    instance.time = 0
    initObjects(instance)
    return instance
end

function BackgroundManager:update(dt)
    self.time = self.time + dt

    for _, obj in ipairs(self.objects) do
        if obj.type == "board" then
            obj.rotation = obj.rotation + obj.rotationSpeed * dt
            -- Wrap edges
            if obj.x < -100 then
                obj.x = screenWidth + 100
            elseif obj.x > screenWidth + 100 then
                obj.x = -100
            end
            if obj.y < -100 then
                obj.y = screenHeight + 100
            elseif obj.y > screenHeight + 100 then
                obj.y = -100
            end
        end
    end
end

function BackgroundManager:drawMenuBackground()
    local t = self.time
    lg.setColor(0.05, 0.05, 0.08, 1)
    lg.rectangle("fill", 0, 0, screenWidth, screenHeight)

    for _, obj in ipairs(self.objects) do
        if obj.type == "dot" then
            local twinkle = (sin(t * obj.twinkleSpeed + obj.x) + 1) * 0.5
            lg.setColor(1, 1, 1, obj.alpha * twinkle)
            lg.circle("fill", obj.x, obj.y, obj.size)
        elseif obj.type == "board" then
            lg.push()
            lg.translate(obj.x, obj.y)
            lg.rotate(obj.rotation)
            lg.setColor(1, 1, 1, obj.alpha)
            local s = obj.size / 3
            -- Draw grid
            for i = -1, 1 do
                lg.line(-s * 1.5, i * s, s * 1.5, i * s)
                lg.line(i * s, -s * 1.5, i * s, s * 1.5)
            end
            -- Draw Xs and Os
            for i = 0, 2 do
                for j = 0, 2 do
                    local cell = obj.cells[i * 3 + j + 1]
                    local cx, cy = (j - 1) * s, (i - 1) * s
                    if cell == "X" then
                        lg.line(cx - s / 2, cy - s / 2, cx + s / 2, cy + s / 2)
                        lg.line(cx + s / 2, cy - s / 2, cx - s / 2, cy + s / 2)
                    else
                        lg.circle("line", cx, cy, s / 2)
                    end
                end
            end
            lg.pop()
        end
    end
end

function BackgroundManager:drawGameBackground()
    local t = self.time
    lg.setColor(0, 0, 0.05, 1)
    lg.rectangle("fill", 0, 0, screenWidth, screenHeight)

    for _, obj in ipairs(self.objects) do
        if obj.type == "dot" then
            local twinkle = (sin(t * obj.twinkleSpeed + obj.x * 0.5) + 1) * 0.5
            lg.setColor(1, 1, 1, obj.alpha * (0.6 + twinkle * 0.4))
            lg.circle("fill", obj.x, obj.y, obj.size)
        elseif obj.type == "board" then
            lg.push()
            lg.translate(obj.x, obj.y)
            lg.rotate(obj.rotation)
            lg.setColor(1, 1, 1, obj.alpha)
            local s = obj.size / 3
            -- Draw grid
            for i = -1, 1 do
                lg.line(-s * 1.5, i * s, s * 1.5, i * s)
                lg.line(i * s, -s * 1.5, i * s, s * 1.5)
            end
            -- Draw Xs and Os
            for i = 0, 2 do
                for j = 0, 2 do
                    local cell = obj.cells[i * 3 + j + 1]
                    local cx, cy = (j - 1) * s, (i - 1) * s
                    if cell == "X" then
                        lg.line(cx - s / 2, cy - s / 2, cx + s / 2, cy + s / 2)
                        lg.line(cx + s / 2, cy - s / 2, cx - s / 2, cy + s / 2)
                    else
                        lg.circle("line", cx, cy, s / 2)
                    end
                end
            end
            lg.pop()
        end
    end
end

return BackgroundManager
