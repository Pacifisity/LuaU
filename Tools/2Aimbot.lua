return function(Sage)

    ------------------------------------------------------
    -- SERVICES
    ------------------------------------------------------
    local Players          = game:GetService("Players")
    local RunService       = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace        = game:GetService("Workspace")

    local LocalPlayer      = Players.LocalPlayer
    local Camera           = Workspace.CurrentCamera

    ------------------------------------------------------
    -- UI SECTION
    ------------------------------------------------------
    local section = Sage.Tools:Section({ Title = "Aimbot" })

    ------------------------------------------------------
    -- INTERNAL STATE
    ------------------------------------------------------
    local running       = false
    local renderConn    = nil
    local updateThread  = nil

    local isRMB         = false
    local currentTarget = nil
    local currentPart   = nil
    local strength      = 5

    local aimProgress   = 0
    local lastDX        = 0
    local lastDY        = 0

    ------------------------------------------------------
    -- CONSTANTS
    ------------------------------------------------------
    local REFRESH_RATE = 0.10
    local AIM_FOV      = 200
    local MAX_DIST     = 1500
    local MAX_STEP     = 15
    local AIM_RAMP     = 0.12
    local ANGLE_SMOOTH = 0.35   -- NEW: angular smoothing factor

    ------------------------------------------------------
    -- INPUT
    ------------------------------------------------------
    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.UserInputType == Enum.UserInputType.MouseButton2 then
            isRMB = true
        end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton2 then
            isRMB = false
            currentPart = nil
            aimProgress = 0
        end
    end)

    ------------------------------------------------------
    -- VISIBILITY CHECK
    ------------------------------------------------------
    local function isVisible(part, char)
        if not part then return false end

        local origin = Camera.CFrame.Position
        local dir    = part.Position - origin
        if dir.Magnitude > MAX_DIST then return false end

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = { LocalPlayer.Character, char }

        return Workspace:Raycast(origin, dir, params) == nil
    end

    ------------------------------------------------------
    -- VISIBLE PART PRIORITY
    ------------------------------------------------------
    local function findStableVisiblePart(char, oldPart)
        -- First try to KEEP the same part if still visible
        if oldPart and isVisible(oldPart, char) then
            return oldPart
        end

        -- Otherwise choose best new part
        local head  = char:FindFirstChild("Head")
        local chest = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        local root  = char:FindFirstChild("HumanoidRootPart")

        if head and isVisible(head, char) then return head end
        if chest and isVisible(chest, char) then return chest end
        if root and isVisible(root, char) then return root end

        return nil
    end

    ------------------------------------------------------
    -- TARGET SELECTION
    ------------------------------------------------------
    local function selectTarget()
        local oldTarget = currentTarget

        currentTarget = nil
        currentPart   = nil

        local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local bestScore = math.huge

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then

                        local part = findStableVisiblePart(char, currentTarget == char and currentPart or nil)
                        if part then
                            local pos, onscreen = Camera:WorldToViewportPoint(part.Position)
                            if onscreen then
                                local dist2d = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                                if dist2d < AIM_FOV and dist2d < bestScore then
                                    bestScore = dist2d
                                    currentTarget = char
                                    currentPart   = part
                                end
                            end
                        end

                    end
                end
            end
        end

        -- Smooth aim only resets when TARGET changes, NOT part
        if currentTarget ~= oldTarget then
            aimProgress = 0
        end
    end

    ------------------------------------------------------
    -- AIMING
    ------------------------------------------------------
    local function aimAt(worldPos)
        local pos, onScreen = Camera:WorldToViewportPoint(worldPos)
        if not onScreen then return end

        local cx = Camera.ViewportSize.X/2
        local cy = Camera.ViewportSize.Y/2

        local dx = pos.X - cx
        local dy = pos.Y - cy

        -- Smooth aim strength ramp
        aimProgress = math.clamp(aimProgress + AIM_RAMP, 0, 1)
        local alpha = ((strength / 10) ^ 3) * aimProgress

        dx *= alpha
        dy *= alpha

        -- Angular smoothing: lerp movement direction
        dx = lastDX + (dx - lastDX) * ANGLE_SMOOTH
        dy = lastDY + (dy - lastDY) * ANGLE_SMOOTH

        lastDX, lastDY = dx, dy

        -- Hard clamp step
        dx = math.clamp(dx, -MAX_STEP, MAX_STEP)
        dy = math.clamp(dy, -MAX_STEP, MAX_STEP)

        mousemoverel(dx, dy)
    end

    ------------------------------------------------------
    -- TOGGLE
    ------------------------------------------------------
    section:Toggle({
        Title = "Enable",
        Default = false,

        Callback = function(state)
            running = state

            if state then
                updateThread = task.spawn(function()
                    while running do
                        if isRMB then
                            selectTarget()
                        else
                            currentPart = nil
                            aimProgress = 0
                        end
                        task.wait(REFRESH_RATE)
                    end
                end)

                renderConn = RunService.RenderStepped:Connect(function()
                    if running and isRMB and currentPart then
                        aimAt(currentPart.Position)
                    end
                end)
            end
        end
    })

    ------------------------------------------------------
    -- Strength Slider
    ------------------------------------------------------
    section:Slider({
        Title = "Strength",
        Min = 1,
        Max = 10,
        Default = 5,
        Callback = function(v)
            strength = v
        end
    })
end
