local lg = love.graphics

local menu = {}

local crtIntensity = 0.23
local state = "main" -- or "settings"

-- Fonts (will be set in menu.load)
local titleFont, buttonFont

-- Button definitions
local buttons = {
    play = {
        w = 220, h = 80, text = "PLAY", rainbowT = 0, baseScale = 1.0, hoverScale = 1.12, scale = 1.0
    },
    settings = {
        w = 220, h = 80, text = "SETTINGS", rainbowT = 0, baseScale = 1.0, hoverScale = 1.12, scale = 1.0
    },
    exit = {
        w = 220, h = 80, text = "EXIT", rainbowT = 0, baseScale = 1.0, hoverScale = 1.12, scale = 1.0
    },
    back = {
        w = 220, h = 60, text = "BACK", rainbowT = 0, baseScale = 1.0, hoverScale = 1.10, scale = 1.0
    }
}
local buttonOrder = {"play", "settings", "exit"}

local slider = {
    x = 0, y = 0, w = 400, h = 12,
    knobRadius = 18,
    dragging = false
}

function menu.load()
    titleFont = lg.newFont(64)
    buttonFont = lg.newFont(36)
    slider.y = lg.getHeight() * 0.55
    slider.x = (lg.getWidth() - slider.w) / 2
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
    -- Border (no rainbow effect)
    lg.setLineWidth(6)
    lg.setColor(0.4, 0.7, 1.0)
    lg.rectangle("line", -btn.w/2, -btn.h/2, btn.w, btn.h, 0, 0)
    -- Text (no rainbow effect)
    lg.setFont(buttonFont)
    lg.setColor(1, 1, 1)
    lg.printf(btn.text, -btn.w/2, -btn.h/2 + btn.h/2 - 24, btn.w, "center")
    lg.pop()
end

function menu.update(dt)
    local mx, my = lg.getWidth()/2, lg.getHeight()/2
    if love.mouse then mx, my = love.mouse.getPosition() end

    layoutVerticalButtons()

    if state == "main" then
        for _, name in ipairs(buttonOrder) do
            local btn = buttons[name]
            btn.hovered = mx > btn.x and mx < btn.x + btn.w and my > btn.y and my < btn.y + btn.h
            if btn.hovered then
                btn.scale = btn.scale + (btn.hoverScale - btn.scale) * 0.5
            else
                btn.scale = btn.scale + (btn.baseScale - btn.scale) * 0.5
            end
        end
    elseif state == "settings" then
        -- Ensure slider is centered when entering settings
        slider.x = (lg.getWidth() - slider.w) / 2
        slider.y = lg.getHeight() * 0.55
        local btn = buttons.back
        btn.hovered = mx > btn.x and mx < btn.x + btn.w and my > btn.y and my < btn.y + btn.h
        if btn.hovered then
            btn.scale = btn.scale + (btn.hoverScale - btn.scale) * 0.5
        else
            btn.scale = btn.scale + (btn.baseScale - btn.scale) * 0.5
        end
    end
end

function menu.draw()
    -- Title
    lg.setFont(titleFont)
    lg.setColor(1, 1, 1, 0.92)
    lg.printf("[TITLE]", 0, lg.getHeight() * 0.22, lg.getWidth(), "center")

    if state == "main" then
        for _, name in ipairs(buttonOrder) do
            drawButton(buttons[name])
        end
    elseif state == "settings" then
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
    end
end

function menu.mousepressed(x, y, buttonNum)
    if state == "main" then
        if buttonNum == 1 then
            if buttons.play.hovered then
                print("Play button pressed!")
            elseif buttons.settings.hovered then
                state = "settings"
                -- Center the slider when entering settings
                slider.x = (lg.getWidth() - slider.w) / 2
                slider.y = lg.getHeight() * 0.55
            elseif buttons.exit.hovered then
                love.event.quit()
            end
        end
    elseif state == "settings" then
        if buttonNum == 1 then
            -- Slider knob
            local knobX = slider.x + (crtIntensity * slider.w)
            local dx = x - knobX
            local dy = y - (slider.y + slider.h/2)
            if dx*dx + dy*dy <= slider.knobRadius*slider.knobRadius then
                slider.dragging = true
            elseif buttons.back.hovered then
                state = "main"
            end
        end
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

return menu