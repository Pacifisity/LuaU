return function(Sage)

    if not Sage.Tools then
        warn("NO Tools TAB FOUND IN WINDOW")
        return
    end

    ------------------------------------------------------
    -- UI
    ------------------------------------------------------
    local section = Sage.Tools:Section({ Title = "Visuals" })

    ------------------------------------------------------
    -- INTERNAL STATE
    ------------------------------------------------------
    local running = false
    local renderConn = nil
    local updateThread = nil

    local currentTarget = nil
    local currentAimPart = nil
    local aimbotStrength = 5
    local isRMB = false

    ------------------------------------------------------
    -- SERVICES
    ------------------------------------------------------
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    ------------------------------------------------------
    -- CONSTANTS
    ------------------------------------------------------
    local REFRESH_RATE = 0.15
    local AIM_FOV = 150

    ------------------------------------------------------
    -- CHARACTER TRACKING / CACHING
    ------------------------------------------------------
    local trackedCharacters = {}
    local cachedParts = {}

    local function cacheModelParts(model)
        local parts = {}
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("BasePart") then
                parts[#parts+1] = obj
            end
        end
        cachedParts[model] = parts
    end

    local function registerCharacter(model)
        if trackedCharacters[model] then return end
        if model == LocalPlayer.Character then return end
        if not model:FindFirstChildOfClass("Humanoid") then return end

        trackedCharacters[model] = true
        cacheModelParts(model)

        model.DescendantAdded:Connect(function(obj)
            if obj:IsA("BasePart") then
                table.insert(cachedParts[model], obj)
            end
        end)

        model.DescendantRemoving:Connect(function(obj)
            if obj:IsA("BasePart") then
                local list = cachedParts[model]
                for i = #list, 1, -1 do
                    if list[i] == obj then
                        table.remove(list, i)
                        break
                    end
                end
            end
        end)
    end

    Workspace.ChildAdded:Connect(registerCharacter)
    for _, child in ipairs(Workspace:GetChildren()) do
        registerCharacter(child)
    end

    Workspace.ChildRemoved:Connect(function(model)
        trackedCharacters[model] = nil
        cachedParts[model] = nil
    end)

    ------------------------------------------------------
    -- VISIBILITY CHECK
    ------------------------------------------------------
    local function isPartVisible(part)
        if not (part and part:IsA("BasePart")) then return false end

        local origin = Camera.CFrame.Position
        local dir = part.Position - origin

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {
            LocalPlayer.Character, part.Parent
        }

        local result = Workspace:Raycast(origin, dir, params)
        return not result or result.Instance:IsDescendantOf(part.Parent)
    end

    ------------------------------------------------------
    -- BODY PART PRIORITY
    ------------------------------------------------------
    local BODY_PRIORITY = {
        Head = 1,
        UpperTorso = 2, Torso = 2,
        HumanoidRootPart = 3,
        LowerTorso = 4,
        LeftUpperArm = 5, RightUpperArm = 5,
        LeftLowerArm = 6, RightLowerArm = 6,
        LeftHand = 7, RightHand = 7,
        LeftUpperLeg = 8, RightUpperLeg = 8,
        LeftLowerLeg = 9, RightLowerLeg = 9,
        LeftFoot = 10, RightFoot = 10,
    }

    local function findBestBodyPart(model)
        local parts = cachedParts[model]
        if not parts then return nil end

        local best = nil
        local bestScore = math.huge

        for _, part in ipairs(parts) do
            local score = BODY_PRIORITY[part.Name]
            if score and score < bestScore and isPartVisible(part) then
                bestScore = score
                best = part
            end
        end

        return best
    end

    ------------------------------------------------------
    -- TARGET REFRESH
    ------------------------------------------------------
    local visibleTargets = {}

    local function updateVisibleTargets()
        visibleTargets = {}
        for model in pairs(trackedCharacters) do
            local best = findBestBodyPart(model)
            if best then
                visibleTargets[model] = best
            end
        end
    end

    ------------------------------------------------------
    -- GET CLOSEST TARGET
    ------------------------------------------------------
    local function getClosestTarget()
        local closest = nil
        local bestDist = AIM_FOV

        local center = Vector2.new(
            Camera.ViewportSize.X/2,
            Camera.ViewportSize.Y/2
        )

        for model, part in pairs(visibleTargets) do
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    closest = model
                end
            end
        end

        return closest
    end

    ------------------------------------------------------
    -- TARGET ACQUISITION
    ------------------------------------------------------
    local function acquireTarget()
        local new = getClosestTarget()

        if new ~= currentTarget then
            currentTarget = new
            currentAimPart = new and findBestBodyPart(new) or nil
        else
            if currentTarget and (not currentAimPart or not isPartVisible(currentAimPart)) then
                currentAimPart = findBestBodyPart(currentTarget)
            end
        end
    end

    ------------------------------------------------------
    -- AIM WITH MOUSE MOVEMENT  (NEW LOGIC)
    ------------------------------------------------------
    local function aimAtWorldPosition(worldPos, strength)
        local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
        if not onScreen then return end

        local cx = Camera.ViewportSize.X / 2
        local cy = Camera.ViewportSize.Y / 2

        local dx = (screenPos.X - cx)
        local dy = (screenPos.Y - cy)

        -- nonlinear falloff for smoothness
        local alpha = (strength / 10) ^ 3

        mousemoverel(dx * alpha, dy * alpha)
    end

    ------------------------------------------------------
    -- INPUT HOOKS
    ------------------------------------------------------
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.UserInputType == Enum.UserInputType.MouseButton2 then
            isRMB = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            isRMB = false
            currentTarget = nil
            currentAimPart = nil
        end
    end)

    ------------------------------------------------------
    -- UI TOGGLE
    ------------------------------------------------------
    section:Toggle({
        Title = "Aimbot (Hold Right-Click)",
        Default = false,

        Callback = function(state)
            if state then
                running = true

                updateThread = task.spawn(function()
                    while running do
                        updateVisibleTargets()
                        task.wait(REFRESH_RATE)
                    end
                end)

                renderConn = RunService.RenderStepped:Connect(function()
                    if running and isRMB then
                        acquireTarget()
                        if currentAimPart then
                            aimAtWorldPosition(currentAimPart.Position, aimbotStrength)
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

    ------------------------------------------------------
    -- STRENGTH SLIDER
    ------------------------------------------------------
    section:Slider({
        Title = "Aimbot Strength",
        Min = 1,
        Max = 10,
        Default = 5,
        Callback = function(v)
            aimbotStrength = v
        end
    })

end
