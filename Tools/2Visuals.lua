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
    local running        = false
    local renderConn     = nil
    local updateThread   = nil
    local isRMB          = false

    local currentTarget  = nil
    local currentAimPart = nil
    local aimbotStrength = 5

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
    -- CONSTANTS
    ------------------------------------------------------
    local REFRESH_RATE = 0.15
    local AIM_FOV      = 150

    ------------------------------------------------------
    -- TRACKED CHARACTERS
    ------------------------------------------------------
    local trackedCharacters = {}
    local cachedParts       = {}

    ------------------------------------------------------
    -- UTILS
    ------------------------------------------------------
    local function findHumanoid(model)
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("Humanoid") then
                return d
            end
        end
        return nil
    end

    local function isAlive(model)
        local h = findHumanoid(model)
        return h and h.Health > 0
    end

    local function cacheModelParts(model)
        local parts = {}
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") then
                parts[#parts + 1] = d
            end
        end
        cachedParts[model] = parts
    end

    ------------------------------------------------------
    -- CHARACTER REGISTRATION
    ------------------------------------------------------
    local function registerCharacter(model)
        if trackedCharacters[model] then return end
        if model == LocalPlayer.Character then return end
        if not model:IsA("Model") then return end

        local humanoid = findHumanoid(model)
        if not humanoid then return end

        trackedCharacters[model] = true
        cacheModelParts(model)

        model.DescendantAdded:Connect(function(obj)
            if obj:IsA("BasePart") and cachedParts[model] then
                table.insert(cachedParts[model], obj)
            end
        end)

        model.DescendantRemoving:Connect(function(obj)
            if obj:IsA("BasePart") and cachedParts[model] then
                for i = #cachedParts[model], 1, -1 do
                    if cachedParts[model][i] == obj then
                        table.remove(cachedParts[model], i)
                        break
                    end
                end
            end
        end)
    end

    -- Recursive workspace scan
    local function deepScan(root)
        for _, obj in ipairs(root:GetChildren()) do
            if obj:IsA("Model") then
                registerCharacter(obj)
            end
            deepScan(obj)
        end
    end

    deepScan(Workspace)

    Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") then
            registerCharacter(obj)
        end
    end)

    Workspace.DescendantRemoving:Connect(function(model)
        trackedCharacters[model] = nil
        cachedParts[model]      = nil
    end)

    ------------------------------------------------------
    -- VISIBILITY
    ------------------------------------------------------
    local function isPartVisible(part)
        if not (part and part:IsA("BasePart")) then return false end

        local model = part:FindFirstAncestorOfClass("Model")
        if not model then return false end
        if not isAlive(model) then return false end

        local origin = Camera.CFrame.Position
        local dir    = part.Position - origin

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {
            LocalPlayer.Character,
            model
        }

        local hit = Workspace:Raycast(origin, dir, params)
        return hit == nil
    end

    ------------------------------------------------------
    -- PRIORITY
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
        if not isAlive(model) then return nil end

        local parts = cachedParts[model]
        if not parts then return nil end

        local bestScore = math.huge
        local bestPart  = nil

        for _, part in ipairs(parts) do
            local score = BODY_PRIORITY[part.Name]
            if score and score < bestScore and isPartVisible(part) then
                bestScore = score
                bestPart  = part
            end
        end

        return bestPart
    end

    ------------------------------------------------------
    -- TARGETING
    ------------------------------------------------------
    local visibleTargets = {}

    local function updateVisibleTargets()
        visibleTargets = {}
        for model in pairs(trackedCharacters) do
            if isAlive(model) then
                local part = findBestBodyPart(model)
                if part then
                    visibleTargets[model] = part
                end
            else
                if currentTarget == model then
                    currentTarget = nil
                    currentAimPart = nil
                end
            end
        end
    end

    local function getClosestTarget()
        local bestModel = nil
        local bestDist  = AIM_FOV

        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

        for model, part in pairs(visibleTargets) do
            local pos, visible = Camera:WorldToViewportPoint(part.Position)
            if visible then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestModel = model
                end
            end
        end

        return bestModel
    end

    local function acquireTarget()
        if currentTarget and not isAlive(currentTarget) then
            currentTarget = nil
            currentAimPart = nil
            return
        end

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
    -- AIM (mouse)
    ------------------------------------------------------
    local function aimAtWorldPosition(worldPos, strength)
        local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
        if not onScreen then return end

        local cx = Camera.ViewportSize.X/2
        local cy = Camera.ViewportSize.Y/2

        local dx = screenPos.X - cx
        local dy = screenPos.Y - cy

        local alpha = (strength / 10) ^ 3
        mousemoverel(dx * alpha, dy * alpha)
    end

    ------------------------------------------------------
    -- INPUT
    ------------------------------------------------------
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

                        if currentTarget and not isAlive(currentTarget) then
                            currentTarget = nil
                            currentAimPart = nil
                            return
                        end

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

                if renderConn then renderConn:Disconnect() end
                renderConn = nil
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
