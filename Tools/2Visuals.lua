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
    local section = Sage.Tools:Section({ Title = "Visuals" })

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

    -- Smooth (aim velocity) storage
    local lastMoveX     = 0
    local lastMoveY     = 0

    ------------------------------------------------------
    -- CONSTANTS
    ------------------------------------------------------
    local REFRESH_RATE = 0.08
    local AIM_FOV      = 200
    local MAX_DIST     = 1500
    local MAX_JUMP     = 40          -- maximum mouse move per frame
    local SMOOTH_K     = 0.18        -- proportional aim factor
    local SMOOTH_BLEND = 0.35        -- directional smoothing factor

    ------------------------------------------------------
    -- RMB INPUT
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
            currentTarget = nil
            currentPart   = nil
            lastMoveX     = 0
            lastMoveY     = 0
        end
    end)

    ------------------------------------------------------
    -- VISIBILITY CHECK
    ------------------------------------------------------
    local function isVisible(part, character)
        if not part then return false end

        local origin = Camera.CFrame.Position
        local dir    = part.Position - origin
        if dir.Magnitude > MAX_DIST then return false end

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {
            LocalPlayer.Character,
            character
        }

        return Workspace:Raycast(origin, dir, params) == nil
    end

    ------------------------------------------------------
    -- BEST VISIBLE PART
    ------------------------------------------------------
    local function getBestPart(char)
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
        currentTarget = nil
        currentPart   = nil

        if not LocalPlayer or not LocalPlayer.Character then return end
        if not Camera then Camera = Workspace.CurrentCamera end

        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local bestScore = math.huge

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then

                        local part = getBestPart(char)
                        if part then
                            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                            if onScreen then
                                local dist2d = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude

                                if dist2d < AIM_FOV and dist2d < bestScore then
                                    bestScore    = dist2d
                                    currentTarget = char
                                    currentPart   = part
                                end
                            end
                        end

                    end
                end
            end
        end
    end

    ------------------------------------------------------
    -- TRUE TRACKING AIMING
    ------------------------------------------------------
    local function aimAt(worldPos)
        local pos, onScreen = Camera:WorldToViewportPoint(worldPos)
        if not onScreen then return end

        local cx = Camera.ViewportSize.X / 2
        local cy = Camera.ViewportSize.Y / 2

        -- Error signal (distance from crosshair)
        local dx = pos.X - cx
        local dy = pos.Y - cy

        ------------------------------------------------------
        -- PROPORTIONAL AIM CONTROLLER
        -- Smoothly reduces error until it reaches EXACT zero.
        ------------------------------------------------------
        local k = (strength / 10) * SMOOTH_K
        local moveX = dx * k
        local moveY = dy * k

        ------------------------------------------------------
        -- DIRECTIONAL SMOOTHING
        -- Prevents flicking by blending old and new directions.
        ------------------------------------------------------
        moveX = lastMoveX + (moveX - lastMoveX) * SMOOTH_BLEND
        moveY = lastMoveY + (moveY - lastMoveY) * SMOOTH_BLEND

        lastMoveX, lastMoveY = moveX, moveY

        ------------------------------------------------------
        -- SAFETY CLAMP (only to prevent insane values)
        ------------------------------------------------------
        moveX = math.clamp(moveX, -MAX_JUMP, MAX_JUMP)
        moveY = math.clamp(moveY, -MAX_JUMP, MAX_JUMP)

        mousemoverel(moveX, moveY)
    end

    ------------------------------------------------------
    -- UI TOGGLE
    ------------------------------------------------------
    section:Toggle({
        Title = "Aimbot",
        Default = false,

        Callback = function(state)
            running = state

            if state then
                updateThread = task.spawn(function()
                    while running do
                        if isRMB then
                            selectTarget()
                        else
                            currentTarget = nil
                            currentPart   = nil
                            lastMoveX     = 0
                            lastMoveY     = 0
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
