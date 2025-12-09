return function(Sage)
    ------------------------------------------------------------
    -- UI SETUP
    ------------------------------------------------------------
    local section = Sage.Tools:Section({
        Title = "Remote Detector",
    })

    ------------------------------------------------------------
    -- SERVICES
    ------------------------------------------------------------
    local Players            = game:GetService("Players")
    local ReplicatedStorage  = game:GetService("ReplicatedStorage")
    local ReplicatedFirst    = game:GetService("ReplicatedFirst")
    local Workspace          = game:GetService("Workspace")

    local LocalPlayer = Players.LocalPlayer

    ------------------------------------------------------------
    -- INTERNAL STATE
    ------------------------------------------------------------
    local seen = {}
    local remoteButtons = {}

    ------------------------------------------------------------
    -- REGISTER REMOTE
    ------------------------------------------------------------
    local function registerRemote(remote)
        if seen[remote] then return end
        seen[remote] = true

        local fullName = remote:GetFullName()

        remoteButtons[remote] = section:Button({
            Title = fullName,
            Callback = function()
                -- SAFELY fire remotes
                if remote:IsA("RemoteEvent") then
                    remote:FireServer()
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer()
                end
            end,
        })
    end

    ------------------------------------------------------------
    -- SHALLOW SCAN (one layer)
    ------------------------------------------------------------
    local function shallowScan(container)
        if not container then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                registerRemote(child)
            end
        end
    end

    ------------------------------------------------------------
    -- DEEP SCAN STEP
    ------------------------------------------------------------
    local function deepScanStep(container, queue)
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                registerRemote(child)
            end

            -- Search deeper in reasonable container types
            if child:IsA("Folder")
            or child:IsA("ModuleScript")
            or child:IsA("ScreenGui")
            or child:IsA("LocalScript")
            or child:IsA("Model")
            or child:IsA("Frame")
            then
                table.insert(queue, child)
            end
        end
    end

    ------------------------------------------------------------
    -- FAST SCAN (quick top-level discovery)
    ------------------------------------------------------------
    local function fastScan()
        shallowScan(ReplicatedStorage)

        local priority = {
            Modules = true,
            Shared  = true,
            Remotes = true,
            Events  = true,
        }

        for folderName in pairs(priority) do
            local folder = ReplicatedStorage:FindFirstChild(folderName)
            if folder then
                local queue = { folder }
                while #queue > 0 do
                    local item = table.remove(queue, 1)
                    deepScanStep(item, queue)
                end
            end
        end

        shallowScan(ReplicatedFirst)
        shallowScan(LocalPlayer:FindFirstChild("PlayerGui"))

        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        shallowScan(char)
    end

    ------------------------------------------------------------
    -- SLOW SCAN (background deep search)
    ------------------------------------------------------------
    local function slowScan()
        local queue = {
            Workspace,
            LocalPlayer:WaitForChild("PlayerGui"),
            LocalPlayer:WaitForChild("PlayerScripts"),
            LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        }

        task.spawn(function()
            while #queue > 0 do
                local container = table.remove(queue, 1)
                deepScanStep(container, queue)
                task.wait() -- small delay to avoid lag
            end
        end)
    end

    ------------------------------------------------------------
    -- RUN SCANS
    ------------------------------------------------------------
    fastScan()
    slowScan()
end
