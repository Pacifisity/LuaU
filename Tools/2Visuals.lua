return function(Window)

    if not Window.Tools then
        warn("NO Tools TAB FOUND IN WINDOW")
        return
    end

    -- VISUALS SECTION -----------------------------------
    local section = Window.Tools:Section({
        Title = "Visuals [Dev]"
    })

    -- INTERNAL STATE ------------------------------------
    local running = false
    local renderConn = nil
    local updateThread = nil

    local currentTarget = nil
    local currentAimPart = nil
    local aimbotStrength = 10

    -- SERVICES ------------------------------------------
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local REFRESH_RATE = 0.12
    local AIM_FOV = 200

    local isRMB = false
    local visiblePlayers = {}

    -- VISIBILITY ----------------------------------------
    local function isPartVisible(part)
        if not part or not part:IsA("BasePart") then return false end

        local origin = Camera.CFrame.Position
        local direction = (part.Position - origin)

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {
            LocalPlayer.Character,
            part.Parent, -- ignore entire enemy body so accessories don't block
        }

        local result = Workspace:Raycast(origin, direction, params)
        
        -- Ray hits NOTHING → assumed visible  
        if not result then return true end

        -- If ray hit something from *inside the enemy model*, treat as visible  
        return result.Instance:IsDescendantOf(part.Parent)
    end


    -- AIM PRIORITY --------------------------------------
    local function getPreferredAimPart(character)
        local head = character:FindFirstChild("Head")
        if head and isPartVisible(head) then return head end

        local chest = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        if chest and isPartVisible(chest) then return chest end

        local root = character:FindFirstChild("HumanoidRootPart")
        if root and isPartVisible(root) then return root end

        return nil
    end

    -- UPDATE VISIBILITY ---------------------------------
    local function updateVisiblePlayers()
        visiblePlayers = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local p = getPreferredAimPart(plr.Character)
                if p then
                    visiblePlayers[plr] = p
                end
            end
        end
    end

    -- FIND CLOSEST --------------------------------------
    local function getClosestTarget()
        local closest = nil
        local bestDist = AIM_FOV

        for plr, part in pairs(visiblePlayers) do
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude

                if dist < bestDist then
                    bestDist = dist
                    closest = plr
                end
            end
        end

        return closest
    end

    -- TARGET LOCK ---------------------------------------
    local function acquireTarget()
        local newTarget = getClosestTarget()

        if newTarget ~= currentTarget then
            currentTarget = newTarget

            if currentTarget and currentTarget.Character then
                currentAimPart = getPreferredAimPart(currentTarget.Character)
            else
                currentAimPart = nil
            end
        end
    end

    -- SMOOTH AIM ----------------------------------------
    local function smoothAim(fromCF, toPos, strength)
        local alpha = (strength / 10) ^ 3   -- cubic curve
        alpha = math.clamp(alpha, 0.01, 1) -- extremely soft at low strength

        local targetCF = CFrame.new(fromCF.Position, toPos)
        return fromCF:Lerp(targetCF, alpha)
    end


    -- INPUT HOOKS ---------------------------------------
    UserInputService.InputBegan:Connect(function(i, gp)
        if not gp and i.UserInputType == Enum.UserInputType.MouseButton2 then
            isRMB = true
        end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton2 then
            isRMB = false
            currentTarget = nil
            currentAimPart = nil
        end
    end)

    -- TOGGLE --------------------------------------------
    section:Toggle({
        Title = "Aimbot (Hold Right-Click)",
        Default = false,

        Callback = function(state)
            if state then
                running = true

                updateThread = task.spawn(function()
                    while running do
                        updateVisiblePlayers()
                        task.wait(REFRESH_RATE)
                    end
                end)

                renderConn = RunService.RenderStepped:Connect(function()
                    if running and isRMB then
                        acquireTarget()
                        if currentAimPart then
                            local pos = currentAimPart.Position
                            Camera.CFrame = smoothAim(Camera.CFrame, pos, aimbotStrength)
                        end
                    end
                end)

            else
                running = false
                currentTarget = nil
                currentAimPart = nil

                if renderConn then
                    renderConn:Disconnect()
                    renderConn = nil
                end
            end
        end
    })

    -- SLIDER --------------------------------------------
    section:Slider({
        Title = "Aimbot Strength",
        Min = 1,
        Max = 10,
        Default = 10,

        Callback = function(v)
            aimbotStrength = v
        end
    })

end
