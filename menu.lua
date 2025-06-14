local lg = love.graphics

local menu = {}

local crtIntensity = 0.23
local state = "main" -- "main", "flash", "saves", "save_flash"
local flashTimer = 0
local flashDuration = 0.5
local flashAlpha = 1

-- Fonts (will be set in menu.load)
local titleFont, buttonFont

-- Button definitions
local buttons = {
    play = {
        w = 220, h = 80, text = "PLAY", baseScale = 1.0, hoverScale = 1.12, scale = 1.0, textOffset = {x = 0, y = 0}
    },
    settings = {
        w = 220, h = 80, text = "SETTINGS", baseScale = 1.0, hoverScale = 1.12, scale = 1.0, textOffset = {x = 0, y = 0}
    },
    exit = {
        w = 220, h = 80, text = "EXIT", baseScale = 1.0, hoverScale = 1.12, scale = 1.0, textOffset = {x = 0, y = 0}
    },
    back = {
        w = 220, h = 60, text = "BACK", baseScale = 1.0, hoverScale = 1.10, scale = 1.0, textOffset = {x = 0, y = 0}
    }
}
local buttonOrder = {"play", "settings", "exit"}

local slider = {
    x = 0, y = 0, w = 400, h = 12,
    knobRadius = 18,
    dragging = false
}

-- Save slots for the "saves" menu
local saveSlots = {}
for i = 1, 5 do
    saveSlots[i] = {name = "Save " .. i .. " - Empty"}
end

-- Save menu button size (square, a bit smaller)
local saveBtnSize = 64

-- Back button for saves menu
local saveBackBtn = {
    w = 140, h = 60, text = "BACK", baseScale = 1.0, hoverScale = 1.10, scale = 1.0, textOffset = {x = 0, y = 0}, hovered = false
}

function menu.load()
    titleFont = lg.newFont(64)
    buttonFont = lg.newFont(36)
    slider.y = lg.getHeight() * 0.55
    slider.x = (lg.getWidth() - slider.w) / 2
    state = "main"
    flashTimer = 0
    flashAlpha = 1
end

local function layoutVerticalButtons()
    local gap = 32
    local totalHeight = 0
    for _, name in ipairs(buttonOrder) do
        local btn = buttons[name]
        totalHeight = totalHeight + btn.h * btn.scale
    end
    local totalGap = gap * (#buttonOrder - 1)
    local groupHeight = totalHeight + totalGap
    local startY = (lg.getHeight() - groupHeight) / 2
    local x = 60
    local y = startY
    for _, name in ipairs(buttonOrder) do
        local btn = buttons[name]
        btn.x = x
        btn.y = y
        y = y + btn.h * btn.scale + gap
    end
    buttons.back.x = x
    buttons.back.y = y + 40
end

local function drawButton(btn)
    local bx = btn.x + btn.w/2
    local by = btn.y + btn.h/2
    lg.push()
    lg.translate(bx, by)
    lg.scale(btn.scale, btn.scale)
    -- Shadow
    lg.setColor(0, 0, 0, 0.35)
    lg.rectangle("fill", -btn.w/2 + 4, -btn.h/2 + 6, btn.w, btn.h, 0, 0)
    -- Button fill
    if btn.hovered then
        lg.setColor(0.18, 0.22, 0.32, 1.0)
    else
        lg.setColor(0.13, 0.15, 0.22, 1.0)
    end
    lg.rectangle("fill", -btn.w/2, -btn.h/2, btn.w, btn.h, 0, 0)
    -- Border
    lg.setLineWidth(6)
    lg.setColor(0.4, 0.7, 1.0)
    lg.rectangle("line", -btn.w/2, -btn.h/2, btn.w, btn.h, 0, 0)
    -- Text
    lg.setFont(buttonFont)
    lg.setColor(1, 1, 1)
    local offsetX = btn.textOffset and btn.textOffset.x or 0
    local offsetY = btn.textOffset and btn.textOffset.y or 0
    lg.printf(
        btn.text,
        -btn.w/2 + offsetX,
        -btn.h/2 + btn.h/2 - 24 + offsetY,
        btn.w,
        "center"
    )
    lg.pop()
end

local function drawSaveButton(x, y, hovered)
    -- Draws a square save button at (x, y)
    lg.push()
    lg.translate(x + saveBtnSize/2, y + saveBtnSize/2)
    local scale = hovered and 1.10 or 1.0
    lg.scale(scale, scale)
    -- Shadow
    lg.setColor(0, 0, 0, 0.35)
    lg.rectangle("fill", -saveBtnSize/2 + 3, -saveBtnSize/2 + 5, saveBtnSize, saveBtnSize, 8, 8)
    -- Fill
    if hovered then
        lg.setColor(0.18, 0.22, 0.32, 1.0)
    else
        lg.setColor(0.13, 0.15, 0.22, 1.0)
    end
    lg.rectangle("fill", -saveBtnSize/2, -saveBtnSize/2, saveBtnSize, saveBtnSize, 8, 8)
    -- Border
    lg.setLineWidth(4)
    lg.setColor(0.4, 0.7, 1.0)
    lg.rectangle("line", -saveBtnSize/2, -saveBtnSize/2, saveBtnSize, saveBtnSize, 8, 8)
    -- Play triangle
    lg.setColor(0.2, 1, 0.2)
    lg.polygon("fill", 8, 0, -12, -14, -12, 14)
    lg.setColor(1, 1, 1)
    lg.setLineWidth(2)
    lg.polygon("line", 8, 0, -12, -14, -12, 14)
    lg.pop()
end

function menu.update(dt)
    local mx, my = lg.getWidth()/2, lg.getHeight()/2
    if love.mouse then mx, my = love.mouse.getPosition() end

    if state == "flash" then
        flashTimer = flashTimer + dt
        flashAlpha = 1 - math.min(flashTimer / flashDuration, 1)
        if flashTimer >= flashDuration then
            state = "saves"
        end
        return
    elseif state == "save_flash" then
        flashTimer = flashTimer + dt
        flashAlpha = 1 - math.min(flashTimer / flashDuration, 1)
        if flashTimer >= flashDuration then
            state = "main"
        end
        return
    end

    if state == "main" then
        layoutVerticalButtons()
        for _, name in ipairs(buttonOrder) do
            local btn = buttons[name]
            btn.hovered = mx > btn.x and mx < btn.x + btn.w and my > btn.y and my < btn.y + btn.h
            if btn.hovered then
                btn.scale = btn.scale + (btn.hoverScale - btn.scale) * 0.5
                local relX = (mx - btn.x) / btn.w
                local relY = (my - btn.y) / btn.h
                btn.textOffset = {
                    x = (relX - 0.5) * 16,
                    y = (relY - 0.5) * 16
                }
            else
                btn.scale = btn.scale + (btn.baseScale - btn.scale) * 0.5
                btn.textOffset = {x = 0, y = 0}
            end
        end
    elseif state == "settings" then
        layoutVerticalButtons()
        slider.x = (lg.getWidth() - slider.w) / 2
        slider.y = lg.getHeight() * 0.55
        local btn = buttons.back
        btn.hovered = mx > btn.x and mx < btn.x + btn.w and my > btn.y and my < btn.y + btn.h
        if btn.hovered then
            btn.scale = btn.scale + (btn.hoverScale - btn.scale) * 0.5
            local relX = (mx - btn.x) / btn.w
            local relY = (my - btn.y) / btn.h
            btn.textOffset = {
                x = (relX - 0.5) * 16,
                y = (relY - 0.5) * 16
            }
        else
            btn.scale = btn.scale + (btn.baseScale - btn.scale) * 0.5
            btn.textOffset = {x = 0, y = 0}
        end
    elseif state == "saves" then
        -- Save slot hover
        local slotH = 80
        local slotGap = 18
        local totalH = 5 * slotH + 4 * slotGap
        local startY = (lg.getHeight() - totalH) / 2
        local slotX = lg.getWidth() * 0.18 + 16
        local slotBtnX = lg.getWidth() * 0.78 - saveBtnSize - 16
        for i = 1, 5 do
            local y = startY + (i - 1) * (slotH + slotGap)
            saveSlots[i].hovered = mx > slotBtnX and mx < slotBtnX + saveBtnSize and my > y + (slotH - saveBtnSize)/2 and my < y + (slotH - saveBtnSize)/2 + saveBtnSize
        end
        -- Back button hover
        local backX = lg.getWidth() * 0.5 - saveBackBtn.w/2
        local backY = startY + totalH + 32
        saveBackBtn.x = backX
        saveBackBtn.y = backY
        saveBackBtn.hovered = mx > backX and mx < backX + saveBackBtn.w and my > backY and my < backY + saveBackBtn.h
    end
end

function menu.draw()
    if state == "flash" or state == "save_flash" then
        lg.setColor(1, 1, 1, flashAlpha)
        lg.rectangle("fill", 0, 0, lg.getWidth(), lg.getHeight())
        return
    end

    if state == "main" then
        -- Title
        lg.setFont(titleFont)
        lg.setColor(1, 1, 1, 0.92)
        lg.printf("[TITLE]", 0, lg.getHeight() * 0.22, lg.getWidth(), "center")
        for _, name in ipairs(buttonOrder) do
            drawButton(buttons[name])
        end
    elseif state == "settings" then
        -- Title
        lg.setFont(titleFont)
        lg.setColor(1, 1, 1, 0.92)
        lg.printf("[TITLE]", 0, lg.getHeight() * 0.22, lg.getWidth(), "center")
        -- Slider label
        lg.setFont(buttonFont)
        lg.setColor(1, 1, 1)
        lg.printf("CRT Intensity", 0, slider.y - 48, lg.getWidth(), "center")
        -- Slider bar
        lg.setColor(0.18, 0.22, 0.32, 1.0)
        lg.rectangle("fill", slider.x, slider.y, slider.w, slider.h, 4, 4)
        -- Slider border
        lg.setLineWidth(3)
        lg.setColor(0.4, 0.7, 1.0)
        lg.rectangle("line", slider.x, slider.y, slider.w, slider.h, 4, 4)
        -- Slider knob
        local knobX = slider.x + (crtIntensity * slider.w)
        lg.setColor(0.4, 0.7, 1.0)
        lg.circle("fill", knobX, slider.y + slider.h/2, slider.knobRadius)
        lg.setColor(1, 1, 1)
        lg.setLineWidth(2)
        lg.circle("line", knobX, slider.y + slider.h/2, slider.knobRadius)
        -- Value text
        lg.setFont(lg.newFont(20))
        lg.setColor(1, 1, 1, 0.7)
        lg.printf(string.format("%.2f", crtIntensity), 0, slider.y + 32, lg.getWidth(), "center")
        -- Back button
        drawButton(buttons.back)
    elseif state == "saves" then
        -- Draw saves menu
        lg.setFont(titleFont)
        lg.setColor(1, 1, 1, 0.92)
        lg.printf("Saves", 0, 30, lg.getWidth(), "center")
        local slotH = 80
        local slotGap = 18
        local totalH = 5 * slotH + 4 * slotGap
        local startY = (lg.getHeight() - totalH) / 2
        local slotBtnX = lg.getWidth() * 0.78 - saveBtnSize - 16
        for i = 1, 5 do
            local y = startY + (i - 1) * (slotH + slotGap)
            -- Slot background
            lg.setColor(0.13, 0.15, 0.22, 1)
            lg.rectangle("fill", lg.getWidth() * 0.18, y, lg.getWidth() * 0.64, slotH, 12, 12)
            -- Slot border
            lg.setColor(0.4, 0.7, 1.0)
            lg.setLineWidth(3)
            lg.rectangle("line", lg.getWidth() * 0.18, y, lg.getWidth() * 0.64, slotH, 12, 12)
            -- Slot text
            lg.setFont(buttonFont)
            lg.setColor(1, 1, 1)
            lg.printf(saveSlots[i].name, lg.getWidth() * 0.18 + 20, y + 16, lg.getWidth() * 0.64 - 40, "left")
            -- Save button (square, smaller)
            drawSaveButton(slotBtnX, y + (slotH - saveBtnSize)/2, saveSlots[i].hovered)
        end
        -- Draw back button
        saveBackBtn.x = lg.getWidth() * 0.5 - saveBackBtn.w/2
        saveBackBtn.y = startY + totalH + 32
        drawButton(saveBackBtn)
    end
end

function menu.mousepressed(x, y, buttonNum)
    if state == "main" then
        if buttonNum == 1 then
            if buttons.play.hovered then
                state = "flash"
                flashTimer = 0
                flashAlpha = 1
            elseif buttons.settings.hovered then
                state = "settings"
                slider.x = (lg.getWidth() - slider.w) / 2
                slider.y = lg.getHeight() * 0.55
            elseif buttons.exit.hovered then
                love.event.quit()
            end
        end
    elseif state == "settings" then
        if buttonNum == 1 then
            local knobX = slider.x + (crtIntensity * slider.w)
            local dx = x - knobX
            local dy = y - (slider.y + slider.h/2)
            if dx*dx + dy*dy <= slider.knobRadius*slider.knobRadius then
                slider.dragging = true
            elseif buttons.back.hovered then
                state = "main"
            end
        end
    elseif state == "saves" then
        -- Back button
        if saveBackBtn.hovered and buttonNum == 1 then
            state = "save_flash"
            flashTimer = 0
            flashAlpha = 1
        end
        -- Save slot buttons (add logic here if needed)
    end
end

function menu.mousemoved(x, y, dx, dy, istouch)
    if state == "settings" and slider.dragging then
        local rel = (x - slider.x) / slider.w
        crtIntensity = math.max(0, math.min(1, rel))
    end
end

function menu.mousereleased(x, y, buttonNum)
    if slider.dragging then
        slider.dragging = false
    end
end

function menu.getCRTIntensity()
    return crtIntensity
end

function menu.shouldHideBackground()
    return state == "flash" or state == "save_flash"
end

return menu