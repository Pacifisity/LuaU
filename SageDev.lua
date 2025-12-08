-- ============================================================
--                     SAGE UI LIBRARY
-- ============================================================

-----------------------------
-- == SERVICES ==
-----------------------------
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild('PlayerGui', 10)

-----------------------------
-- == THEME (Fantasy Black/Purple) ==
-----------------------------
local Theme = {
    Background = Color3.fromRGB(10, 10, 16),
    Accent = Color3.fromRGB(145, 70, 255),
    AccentDark = Color3.fromRGB(90, 40, 180),
    Text = Color3.fromRGB(235, 220, 255),
    TextMuted = Color3.fromRGB(155, 130, 190),
    Section = Color3.fromRGB(20, 10, 30),
    Button = Color3.fromRGB(25, 15, 40),
    ToggleOn = Color3.fromRGB(150, 90, 255),
    ToggleOff = Color3.fromRGB(50, 40, 60),
}

-----------------------------
-- == UTILITY FUNCTIONS ==
-----------------------------

-- Smooth quad tween
local function tween(obj, time, props)
    TweenService
        :Create(
            obj,
            TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            props
        )
        :Play()
end

-- Round corners helper
local function makeRound(instance, radius)
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

-- Padding helper
local function padding(parent, px)
    local p = Instance.new('UIPadding')
    p.PaddingTop = UDim.new(0, px)
    p.PaddingBottom = UDim.new(0, px)
    p.PaddingLeft = UDim.new(0, px)
    p.PaddingRight = UDim.new(0, px)
    p.Parent = parent
    return p
end

-- Vertical list layout helper
local function vlist(parent, paddingPx)
    local layout = Instance.new('UIListLayout')
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, paddingPx or 6)
    layout.Parent = parent
    return layout
end

-- OOP-like class inheritance
local function class(base)
    local cls = {}
    cls.__index = cls
    if base then
        setmetatable(cls, { __index = base })
    end
    return cls
end

-----------------------------
-- CLASS DEFINITIONS
-----------------------------
local Window = class()
local Tab = class()
local Section = class()

local Library = {}
Library.__index = Library

----------------------------------------------------------------
-- == WINDOW CREATION ==
----------------------------------------------------------------
function Library:CreateWindow(options)
    options = options or {}
    local title = options.Title or 'Pain'
    local size = options.Size or Vector2.new(500, 300)

    ------------------------------------------------------------
    -- SCREEN GUI CONTAINER
    ------------------------------------------------------------
    local gui = Instance.new('ScreenGui')
    gui.Name = 'Sage'
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = PlayerGui

    ------------------------------------------------------------
    -- MAIN WINDOW
    ------------------------------------------------------------
    local main = Instance.new('Frame')
    main.Name = 'Window'
    main.Size = UDim2.fromOffset(size.X, size.Y)
    main.Position = UDim2.new(0.5, -size.X / 2, 0.5, -size.Y / 2)
    main.BackgroundColor3 = Theme.Background
    main.BorderSizePixel = 0
    main.Parent = gui
    makeRound(main, 10)

    ------------------------------------------------------------
    -- TOPBAR (Title Bar)
    ------------------------------------------------------------
    local topbar = Instance.new('Frame')
    topbar.Name = 'Topbar'
    topbar.Size = UDim2.new(1, 0, 0, 32)
    topbar.BackgroundColor3 = Theme.Section
    topbar.BorderSizePixel = 0
    topbar.Parent = main
    makeRound(topbar, 10)

    -- Window title
    local titleLabel = Instance.new('TextLabel')
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.fromOffset(12, 0)
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Theme.Text
    titleLabel.TextSize = 16
    titleLabel.Text = title
    titleLabel.Parent = topbar

    -- Close button
    local close = Instance.new('TextButton')
    close.BackgroundTransparency = 1
    close.Size = UDim2.fromOffset(40, 32)
    close.Position = UDim2.new(1, -40, 0, 0)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 16
    close.TextColor3 = Theme.TextMuted
    close.Text = 'X'
    close.Parent = topbar

    ------------------------------------------------------------
    -- TAB BAR (Left Side Tabs)
    ------------------------------------------------------------
    local tabBar = Instance.new('Frame')
    tabBar.Size = UDim2.new(0, 120, 1, -32)
    tabBar.Position = UDim2.fromOffset(0, 32)
    tabBar.BackgroundColor3 = Theme.Section
    tabBar.BorderSizePixel = 0
    tabBar.Parent = main
    makeRound(tabBar, 10)

    padding(tabBar, 8)
    local tabList = vlist(tabBar, 4)

    ------------------------------------------------------------
    -- CONTENT AREA (Right Side)
    ------------------------------------------------------------
    local content = Instance.new('Frame')
    content.Size = UDim2.new(1, -128, 1, -40)
    content.Position = UDim2.fromOffset(128, 36)
    content.BackgroundColor3 = Theme.Background
    content.BorderSizePixel = 0
    content.ClipsDescendants = false
    content.Parent = main
    makeRound(content, 10)

    ------------------------------------------------------------
    -- DRAGGING
    ------------------------------------------------------------
    do
        local dragging = false
        local dragInput, dragStart, startPos
        local UIS = game:GetService('UserInputService')

        local function update(input)
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            main.Position = newPos
        end

        topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = main.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        topbar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)

        UIS.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end)
    end

    ------------------------------------------------------------
    -- MINIMIZE SYSTEM (S button in CoreGui area)
    ------------------------------------------------------------
    local minimized = false

    -- Minimize button on the topbar
    local minimize = Instance.new('TextButton')
    minimize.BackgroundTransparency = 1
    minimize.Size = UDim2.fromOffset(40, 32)
    minimize.Position = UDim2.new(1, -80, 0, 0)
    minimize.Font = Enum.Font.GothamBold
    minimize.TextSize = 18
    minimize.TextColor3 = Theme.TextMuted
    minimize.Text = '-'
    minimize.Parent = topbar

    ------------------------------------------------------------
    -- Floating S icon aligned EXACTLY with CoreGui icons
    ------------------------------------------------------------
    local GuiService = game:GetService('GuiService')
    local RunService = game:GetService('RunService')

    local sButton = Instance.new('TextButton')
    sButton.Name = 'SageMinimizedButton'
    sButton.Text = 'S'
    sButton.Font = Enum.Font.GothamSemibold
    sButton.TextScaled = true
    sButton.TextColor3 = Color3.fromRGB(100, 30, 180)
    sButton.AutoButtonColor = false

    -- CoreGui pill-style button
    sButton.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    sButton.BackgroundTransparency = 0.1
    sButton.BorderSizePixel = 0
    sButton.Size = UDim2.fromOffset(45, 45)
    sButton.AnchorPoint = Vector2.new(1, 0)
    sButton.Visible = false
    sButton.Parent = gui

    local pad = Instance.new('UIPadding')
    pad.PaddingTop = UDim.new(0, -1.5)
    pad.Parent = sButton

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(1, 0) -- full round
    corner.Parent = sButton

    sButton.AnchorPoint = Vector2.new(0, 0)

    local function updateSButtonPosition()
        local inset = GuiService:GetGuiInset().Y

        -- Roblox menu sits at y = inset
        local robloxIconY = inset

        local xOffset = 15 -- move left/right
        local yOffset = 7 -- move up/down

        sButton.Position = UDim2.new(0, xOffset, 0, robloxIconY + yOffset)
    end

    RunService.RenderStepped:Connect(updateSButtonPosition)

    -- Hover effect, matching Roblox style
    sButton.MouseEnter:Connect(function()
        tween(sButton, 0.12, { BackgroundTransparency = 0.02 })
    end)
    sButton.MouseLeave:Connect(function()
        tween(sButton, 0.12, { BackgroundTransparency = 0.1 })
    end)

    ------------------------------------------------------------
    -- Minimize & Restore logic
    ------------------------------------------------------------
    local function minimizeWindow()
        minimized = true
        tween(
            main,
            0.2,
            { Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1 }
        )
        task.delay(0.2, function()
            main.Visible = false
            sButton.Visible = true
            tween(sButton, 0.2, { BackgroundTransparency = 0 })
        end)
    end

    local function restoreWindow()
        minimized = false
        sButton.Visible = false
        main.Visible = true
        tween(main, 0.2, {
            Size = UDim2.fromOffset(size.X, size.Y),
            BackgroundTransparency = 0,
        })
    end

    minimize.MouseButton1Click:Connect(function()
        if not minimized then
            minimizeWindow()
        end
    end)

    sButton.MouseButton1Click:Connect(function()
        if minimized then
            restoreWindow()
        end
    end)

    ------------------------------------------------------------
    -- WINDOW OBJECT
    ------------------------------------------------------------
    local window = setmetatable({
        _gui = gui,
        _main = main,
        _topbar = topbar,
        _tabBar = tabBar,
        _tabList = tabList,
        _content = content,
        _tabs = {},
        _activeTab = nil,
        _toggles = {}, -- stores all toggles for reset-on-close
    }, Window)

    -- now window exists, so this callback works
    close.MouseButton1Click:Connect(function()
        -- turn ALL toggles off before closing
        for _, toggle in ipairs(window._toggles) do
            toggle.Set(false)
        end

        gui:Destroy()
    end)

    minimizeWindow()
    
    -- Create default tabs
    local mainTab  = window:Tab({ Title = "Main" })
    local toolsTab = window:Tab({ Title = "Tools" })

    window.Main  = mainTab
    window.Tools = toolsTab

    return window
end

----------------------------------------------------------------
-- == WINDOW : CREATE TAB ==
----------------------------------------------------------------
function Window:Tab(options)
    options = options or {}
    local title = options.Title or 'Tab'

    ------------------------------------------------------------
    -- TAB BUTTON (Left side)
    ------------------------------------------------------------
    local btn = Instance.new('TextButton')
    btn.Name = 'TabButton_' .. title
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.BackgroundColor3 = Theme.Button
    btn.BorderSizePixel = 0
    btn.Text = title
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextColor3 = Theme.TextMuted
    btn.AutoButtonColor = false
    btn.Parent = self._tabBar
    makeRound(btn, 6)

    ------------------------------------------------------------
    -- TAB CONTENT FRAME
    ------------------------------------------------------------
    local frame = Instance.new('ScrollingFrame')
    frame.Name = 'Tab_' .. title
    frame.Size = UDim2.new(1, -16, 1, -16)
    frame.Position = UDim2.fromOffset(8, 8)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 6
    frame.ScrollBarImageColor3 = Theme.Accent
    frame.Visible = false
    frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.Parent = self._content

    padding(frame, 8)
    local list = vlist(frame, 8)

    ------------------------------------------------------------
    -- TAB OBJECT
    ------------------------------------------------------------
    local tab = setmetatable({
        _window = self,
        _button = btn,
        _frame = frame,
        _list = list,
        _sections = {},
    }, Tab)

    table.insert(self._tabs, tab)

    ------------------------------------------------------------
    -- TAB ACTIVATION / VISUAL FEEDBACK
    ------------------------------------------------------------
    local function activate()
        if self._activeTab == tab then
            return
        end

        for _, t in ipairs(self._tabs) do
            t._frame.Visible = false
            tween(t._button, 0.15, {
                BackgroundColor3 = Theme.Button,
                TextColor3 = Theme.TextMuted,
            })
        end

        tab._frame.Visible = true
        tween(btn, 0.15, {
            BackgroundColor3 = Theme.AccentDark,
            TextColor3 = Theme.Text,
        })

        self._activeTab = tab
    end

    btn.MouseButton1Click:Connect(activate)

    -- Hover visuals
    btn.MouseEnter:Connect(function()
        if self._activeTab ~= tab then
            tween(btn, 0.15, { BackgroundColor3 = Theme.Section })
        end
    end)
    btn.MouseLeave:Connect(function()
        if self._activeTab ~= tab then
            tween(btn, 0.15, { BackgroundColor3 = Theme.Button })
        end
    end)

    -- Auto-select the first tab
    if not self._activeTab then
        activate()
    end

    return tab
end

----------------------------------------------------------------
-- == TAB : SECTION ==
----------------------------------------------------------------
function Tab:Section(options)
    options = options or {}
    local title = options.Title or 'Section'

    ------------------------------------------------------------
    -- SECTION FRAME
    ------------------------------------------------------------
    local frame = Instance.new('Frame')
    frame.Name = 'Section_' .. title
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundColor3 = Theme.Section
    frame.BorderSizePixel = 0
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.ClipsDescendants = false
    frame.Parent = self._frame
    makeRound(frame, 8)

    local pad = padding(frame, 8)

    local layout = Instance.new('UIListLayout')
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.Parent = frame

    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    -- Section heading
    local titleLabel = Instance.new('TextLabel')
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 18)
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Theme.Text
    titleLabel.TextSize = 14
    titleLabel.Text = title
    titleLabel.Parent = frame

    local section = setmetatable({
        _tab = self,
        _frame = frame,
        _layout = layout,
    }, Section)

    table.insert(self._sections, section)
    return section
end

----------------------------------------------------------------
-- == SECTION : BUTTON ==
----------------------------------------------------------------
function Section:Button(options)
    options = options or {}

    local text = options.Title or options.Text or 'Button'
    local callback = options.Callback or function() end

    local btn = Instance.new('TextButton')
    btn.Name = 'Button_' .. text
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Theme.Button
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextColor3 = Theme.Text
    btn.AutoButtonColor = false
    btn.Parent = self._frame
    makeRound(btn, 6)

    ------------------------------------------------------------
    -- CLICK EFFECT + CALLBACK
    ------------------------------------------------------------
    btn.MouseButton1Click:Connect(function()
        tween(btn, 0.08, { BackgroundColor3 = Theme.Accent })
        task.delay(0.08, function()
            tween(btn, 0.15, { BackgroundColor3 = Theme.Button })
        end)

        task.spawn(callback)
    end)

    -- Hover color
    btn.MouseEnter:Connect(function()
        tween(btn, 0.15, { BackgroundColor3 = Theme.Section })
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.15, { BackgroundColor3 = Theme.Button })
    end)

    return btn
end

----------------------------------------------------------------
-- == SECTION : TOGGLE ==
----------------------------------------------------------------
function Section:Toggle(options)
    options = options or {}

    local text = options.Title or options.Text or 'Toggle'
    local default = options.Default or false
    local callback = options.Callback or function() end

    ------------------------------------------------------------
    -- TOGGLE HOLDER
    ------------------------------------------------------------
    local holder = Instance.new('Frame')
    holder.Size = UDim2.new(1, 0, 0, 26)
    holder.BackgroundTransparency = 1
    holder.Parent = self._frame

    -- Label
    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Theme.Text
    label.TextSize = 14
    label.Parent = holder

    ------------------------------------------------------------
    -- SWITCH BUTTON
    ------------------------------------------------------------
    local btn = Instance.new('TextButton')
    btn.BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff
    btn.Size = UDim2.fromOffset(30, 16)
    btn.Position = UDim2.new(1, -30, 0.5, -8)
    btn.Text = ''
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = holder
    makeRound(btn, 8)

    -- Knob inside the switch
    local knob = Instance.new('Frame')
    knob.Size = UDim2.fromOffset(12, 12)
    knob.Position = default and UDim2.fromOffset(16, 2)
        or UDim2.fromOffset(2, 2)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = btn
    makeRound(knob, 6)

    ------------------------------------------------------------
    -- TOGGLE LOGIC
    ------------------------------------------------------------
    local state = default

    local function setState(v)
        state = v and true or false

        tween(btn, 0.15, {
            BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
        })

        tween(knob, 0.15, {
            Position = state and UDim2.fromOffset(16, 2)
                or UDim2.fromOffset(2, 2),
        })

        task.spawn(callback, state)
    end

    btn.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    local toggleObj = {
        Set = setState,
        Get = function()
            return state
        end,
    }

    -- register toggle for reset-on-close
    table.insert(self._tab._window._toggles, toggleObj)

    return toggleObj
end

----------------------------------------------------------------
-- == SECTION : INPUT FIELD ==
----------------------------------------------------------------
function Section:Input(options)
    options = options or {}

    local text = options.Title or options.Text or 'Input'
    local placeholder = options.Placeholder or ''
    local callback = options.Callback or function() end

    ------------------------------------------------------------
    -- INPUT CONTAINER
    ------------------------------------------------------------
    local holder = Instance.new('Frame')
    holder.Size = UDim2.new(1, 0, 0, 32)
    holder.BackgroundTransparency = 1
    holder.Parent = self._frame

    -- Label
    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.4, -4, 1, 0)
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Theme.Text
    label.TextSize = 14
    label.Parent = holder

    -- TextBox
    local box = Instance.new('TextBox')
    box.Size = UDim2.new(0.6, 0, 1, 0)
    box.Position = UDim2.new(0.4, 4, 0, 0)
    box.BackgroundColor3 = Theme.Button
    box.BorderSizePixel = 0
    box.TextColor3 = Theme.Text
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Theme.TextMuted
    box.Font = Enum.Font.Gotham
    box.TextSize = 14
    box.Parent = holder
    makeRound(box, 6)

    ------------------------------------------------------------
    -- FIRE CALLBACK ON ENTER
    ------------------------------------------------------------
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            task.spawn(callback, box.Text)
        end
    end)

    return box
end

----------------------------------------------------------------
-- == SECTION : SLIDER ==
----------------------------------------------------------------
function Section:Slider(options)
    options = options or {}

    local text = options.Title or options.Text or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local callback = options.Callback or function() end
    local round = options.Decimals or 0 -- how many decimal places

    ------------------------------------------------------------
    -- HOLDER
    ------------------------------------------------------------
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 40)
    holder.BackgroundTransparency = 1
    holder.Parent = self._frame

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 18)
    label.Text = text .. " [" .. tostring(default) .. "]"
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextColor3 = Theme.Text
    label.Parent = holder

    ------------------------------------------------------------
    -- BAR
    ------------------------------------------------------------
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.Position = UDim2.new(0, 0, 0, 22)
    bar.BackgroundColor3 = Theme.Button
    bar.BorderSizePixel = 0
    bar.Parent = holder
    makeRound(bar, 8)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    makeRound(fill, 8)

    ------------------------------------------------------------
    -- DRAGGING LOGIC
    ------------------------------------------------------------
    local UIS = game:GetService("UserInputService")
    local dragging = false
    local value = default

    local function setValueFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * rel

        if round == 0 then
            value = math.floor(raw + 0.5)
        else
            value = tonumber(string.format("%." .. round .. "f", raw))
        end

        label.Text = text .. " [" .. tostring(value) .. "]"
        fill.Size = UDim2.new(rel, 0, 1, 0)

        task.spawn(callback, value)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setValueFromX(input.Position.X)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setValueFromX(input.Position.X)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    ------------------------------------------------------------
    -- PUBLIC OBJECT
    ------------------------------------------------------------
    local sliderObj = {
        Get = function() return value end,
        Set = function(v)
            v = math.clamp(v, min, max)
            setValueFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * ((v - min) / (max - min)))
        end
    }

    return sliderObj
end

----------------------------------------------------------------
-- LOADSTRING ACCESS
----------------------------------------------------------------
return setmetatable({
    CreateWindow = Library.CreateWindow,
}, Library)
