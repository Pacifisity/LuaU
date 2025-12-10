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

    local lastMoveX     = 0
    local lastMoveY     = 0

    ------------------------------------------------------
    -- CONSTANTS
    ------------------------------------------------------
    local REFRESH_RATE = 0.08
    local AIM_FOV      = 200
    local MAX_DIST     = 1500
    local MAX_JUMP     = 40
    local SMOOTH_K     = 0.18
    local SMOOTH_BLEND = 0.35

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
            currentTarget = nil
            currentPart   = nil
            lastMoveX     = 0
            lastMoveY     = 0
        end
    end)

    ------------------------------------------------------
    -- BEST PART SELECTION (whitelist raycasts into humanoid)
    ------------------------------------------------------
    local function getBestPartFromRay(char)
        if not char then return nil end

        local candidates = {
            char:FindFirstChild("Head"),
            char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"),
            char:FindFirstChild("HumanoidRootPart")
        }

        local origin = Camera.CFrame.Position
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Whitelist
        params.FilterDescendantsInstances = { char }

        for _, part in ipairs(candidates) do
            if part then
                local result = Workspace:Raycast(origin, part.Position - origin, params)
                if result and result.Instance and result.Instance:IsDescendantOf(char) then
                    return part
                end
            end
        end

        return nil
    end

    ------------------------------------------------------
    -- TARGET VALIDITY CHECK
    ------------------------------------------------------
    local function targetStillValid()
        if not currentTarget or not currentPart then
            return false
        end

        local hum = currentTarget:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            return false
        end

        if not currentPart.Parent then
            return false
        end

        local pos, onScreen = Camera:WorldToViewportPoint(currentPart.Position)
        if not onScreen then
            return false
        end

        return true
    end

    ------------------------------------------------------
    -- TARGET SELECTION (crosshair-only locking)
    ------------------------------------------------------
    local function selectTarget()
        -- Do not change once locked unless invalid
        if currentTarget and currentPart then
            return
        end

        if not isRMB then
            return
        end

        local origin = Camera.CFrame.Position
        local direction = Camera.CFrame.LookVector * MAX_DIST

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = { LocalPlayer.Character }

        local result = Workspace:Raycast(origin, direction, params)
        if not result then return end

        local hit = result.Instance
        if not hit then return end

        local model = hit:FindFirstAncestorOfClass("Model")
        if not model then return end

        local hum = model:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end

        local best = getBestPartFromRay(model)
        if not best then return end

        currentTarget = model
        currentPart   = best
    end

    ------------------------------------------------------
    -- AIM FUNCTION
    ------------------------------------------------------
    local function aimAt(worldPos)
        local pos, onScreen = Camera:WorldToViewportPoint(worldPos)
        if not onScreen then return end

        local cx = Camera.ViewportSize.X / 2
        local cy = Camera.ViewportSize.Y / 2

        local dx = pos.X - cx
        local dy = pos.Y - cy

        local k = (strength / 10) * SMOOTH_K
        local moveX = dx * k
        local moveY = dy * k

        moveX = lastMoveX + (moveX - lastMoveX) * SMOOTH_BLEND
        moveY = lastMoveY + (moveY - lastMoveY) * SMOOTH_BLEND

        lastMoveX, lastMoveY = moveX, moveY

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
                            -- If target is invalid, clear → allow new lock
                            if currentTarget and not targetStillValid() then
                                currentTarget = nil
                                currentPart   = nil
                                lastMoveX     = 0
                                lastMoveY     = 0
                            end

                            if not currentTarget then
                                selectTarget()
                            end
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
                        local screenPos, onScreen = Camera:WorldToViewportPoint(currentPart.Position)
                        if onScreen then
                            local dx = screenPos.X - Camera.ViewportSize.X/2
                            local dy = screenPos.Y - Camera.ViewportSize.Y/2
                            local dist = math.sqrt(dx*dx + dy*dy)

                            if dist <= AIM_FOV then
                                aimAt(currentPart.Position)
                            end
                        end
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
