local lg = love.graphics

local background = {}

local bgImage, bg1Image, bgRImage
local currentBg = "bg"
local blackout = false
local blackoutTimer = 0
local bgTimer = 0
local nextBg = "bg"

function background.load()
    local success
    success, bgImage = pcall(lg.newImage, "Sprites/bg.png")
    if not success then print("Failed to load Sprites/bg.png") end
    success, bg1Image = pcall(lg.newImage, "Sprites/bg1.png")
    if not success then print("Failed to load Sprites/bg1.png") end
    success, bgRImage = pcall(lg.newImage, "Sprites/bgR.png")
    if not success then print("Failed to load Sprites/bgR.png") end
    currentBg = "bg"
    blackout = false
    blackoutTimer = 0
    bgTimer = 0
    nextBg = "bg"
end

function background.update(dt)
    bgTimer = bgTimer + dt

    if blackout then
        blackoutTimer = blackoutTimer + dt
        if blackoutTimer >= 0.5 then
            blackout = false
            blackoutTimer = 0
            currentBg = nextBg
            bgTimer = 0
        end
    elseif bgTimer >= 5 then
        local roll = math.random()
        if roll < (1/6) then
            nextBg = "bgR"
        elseif roll < (1/6 + 1/3) then
            nextBg = "bg1"
        else
            nextBg = "bg"
        end
        if nextBg ~= currentBg then
            blackout = true
            blackoutTimer = 0
        else
            bgTimer = 0
        end
    end
end

function background.draw()
    if blackout then
        lg.clear(0, 0, 0, 1)
    else
        local w, h = lg.getWidth(), lg.getHeight()
        if currentBg == "bg" and bgImage then
            lg.draw(bgImage, 0, 0, 0, w / bgImage:getWidth(), h / bgImage:getHeight())
        elseif currentBg == "bg1" and bg1Image then
            lg.draw(bg1Image, 0, 0, 0, w / bg1Image:getWidth(), h / bg1Image:getHeight())
        elseif currentBg == "bgR" and bgRImage then
            lg.draw(bgRImage, 0, 0, 0, w / bgRImage:getWidth(), h / bgRImage:getHeight())
        else
            lg.clear(0, 0, 0, 1)
        end
    end
end

return background