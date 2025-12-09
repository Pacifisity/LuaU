return function(window)

    if not window.Tools then
        warn("NO Tools TAB FOUND IN WINDOW")
        return
    end

    ------------------------------------------------------------
    -- CREATE VISUALS SECTION
    ------------------------------------------------------------
    local section = window.Tools:Section({
        Title = "Visuals"
    })

    ------------------------------------------------------------
    -- INTERNAL STATE (no globals, fully local)
    ------------------------------------------------------------
    local running = false
    local updateThread = nil
    local renderConn = nil

    ------------------------------------------------------------
    -- TOGGLE
    ------------------------------------------------------------
    section:Toggle({
        Title = "Aimbot (Hold Right-Click)",
        Default = false,

        Callback = function(state)
            if state then
                ------------------------------------------------------------
                -- START AIMBOT
                ------------------------------------------------------------
                running = true

                local Players = game:GetService("Players")
                local RunService = game:GetService("RunService")
                local UserInputService = game:GetService("UserInputService")
                local Workspace = game:GetService("Workspace")

                local LocalPlayer = Players.LocalPlayer
                local Camera = Workspace.CurrentCamera

                local REFRESH_RATE = 0.1
                local SCREEN_CENTER_RADIUS = 150

                local visiblePlayers = {}
                local isHoldingRightClick = false

                ------------------------------------------------------------
                -- VISIBILITY CHECKS
                ------------------------------------------------------------
                local function isPartVisible(part)
                    if not part or not part:IsA("BasePart") then return false end
                    local origin = Camera.CFrame.Position
                    local direction = part.Position - origin

                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Blacklist
                    params.FilterDescendantsInstances = { LocalPlayer.Character }

                    local result = Workspace:Raycast(origin, direction, params)
                    if not result then return true end

                    return result.Instance == part
                end

                local function getVisibleParts(character)
                    local t = {}
                    for _, p in ipairs(character:GetDescendants()) do
                        if p:IsA("BasePart") and isPartVisible(p) then
                            t[#t+1] = p
                        end
                    end
                    return t
                end

                local function getAimPart(character)
                    local visible = getVisibleParts(character)
                    if #visible == 0 then return nil end

                    local head = character:FindFirstChild("Head")
                    local chest = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")

                    if head and table.find(visible, head) then return head end
                    if chest and table.find(visible, chest) then return chest end
                    return visible[math.random(1, #visible)]
                end

                local function getPartPosition(part)
                    if part:IsA("BasePart") then return part.Position end
                    if part:IsA("Model") then return part:GetPivot().Position end
                end

                local function updateVisiblePlayers()
                    visiblePlayers = {}
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character then
                            if #getVisibleParts(plr.Character) > 0 then
                                visiblePlayers[plr] = true
                            end
                        end
                    end
                end

                local function getClosestVisiblePlayer()
                    local shortest = SCREEN_CENTER_RADIUS
                    local closest = nil

                    for plr in pairs(visiblePlayers) do
                        local aim = getAimPart(plr.Character)
                        if aim then
                            local pos = getPartPosition(aim)
                            if pos then
                                local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
                                if onScreen then
                                    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude

                                    if dist < shortest then
                                        shortest = dist
                                        closest = plr
                                    end
                                end
                            end
                        end
                    end

                    return closest
                end

                ------------------------------------------------------------
                -- INPUT HOOK
                ------------------------------------------------------------
                UserInputService.InputBegan:Connect(function(i, gp)
                    if not gp and i.UserInputType == Enum.UserInputType.MouseButton2 then
                        isHoldingRightClick = true
                    end
                end)

                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton2 then
                        isHoldingRightClick = false
                    end
                end)

                ------------------------------------------------------------
                -- BACKGROUND LOOP
                ------------------------------------------------------------
                updateThread = task.spawn(function()
                    while running do
                        updateVisiblePlayers()
                        task.wait(REFRESH_RATE)
                    end
                end)

                ------------------------------------------------------------
                -- CAMERA AIM LOOP
                ------------------------------------------------------------
                renderConn = RunService.RenderStepped:Connect(function()
                    if not running or not isHoldingRightClick then return end

                    local target = getClosestVisiblePlayer()
                    if target and target.Character then
                        local aimPart = getAimPart(target.Character)
                        if aimPart then
                            local pos = getPartPosition(aimPart)
                            if pos then
                                Camera.CFrame = CFrame.new(Camera.CFrame.Position, pos)
                            end
                        end
                    end
                end)

            else
                ------------------------------------------------------------
                -- STOP AIMBOT
                ------------------------------------------------------------
                running = false

                if renderConn then
                    renderConn:Disconnect()
                    renderConn = nil
                end
            end
        end
    })

end
