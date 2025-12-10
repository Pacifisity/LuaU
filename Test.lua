-- ======================================================
--  SAGE UI TESTS
-- ======================================================

local Sage = loadstring(game:HttpGet("https://raw.githubusercontent.com/Pacifisity/LuaU/main/Sage.lua"))()

if not Sage or not Sage.Tools then
    warn("[Sage Tester] UI failed to load.")
    return
end

print("\n[Sage Tester] Ready.\n")

local tool = function(Sage)

    ------------------------------------------------------
    -- SERVICES
    ------------------------------------------------------
    local RunService = game:GetService("RunService")

    ------------------------------------------------------
    -- UI SECTION
    ------------------------------------------------------
    local section = Sage.Tools:Section({ Title = "[Dev]" })

    ------------------------------------------------------
    -- INTERNAL STATE
    ------------------------------------------------------
    local running      = false
    local renderConn   = nil
    local updateThread = nil

    ------------------------------------------------------
    -- CLEANUP
    ------------------------------------------------------
    local function cleanup()
        running = false
        if renderConn then renderConn:Disconnect() end
        renderConn = nil
        updateThread = nil
    end

    ------------------------------------------------------
    -- MAIN TOGGLE
    ------------------------------------------------------
    section:Toggle({
        Title = "Enable",
        Default = false,

        Callback = function(state)
            if state then
                running = true

                updateThread = task.spawn(function()
                    while running do
                        -- slow logic
                        task.wait(0.1)
                    end
                end)

                renderConn = RunService.RenderStepped:Connect(function()
                    if not running then return end
                    -- fast logic
                end)

            else
                cleanup()
            end
        end
    })

    ------------------------------------------------------
    -- OPTIONAL BUTTON
    ------------------------------------------------------
    section:Button({
        Title = "Cleanup",
        Callback = cleanup
    })

end

tool(Sage)
