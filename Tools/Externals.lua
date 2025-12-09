return function(window)

    print("TEST TOOL LOADED")

    -- make sure Tools tab exists
    if not window.Tools then
        warn("NO Tools TAB FOUND IN WINDOW")
        return
    end

    -- create a section
    local section = window.Tools:Section({
        Title = "Externals"
    })

    print("SECTION CREATED:", section)

    -- add a button
    section:Button({
        Title = "Infinite Yield",
        Callback = function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
        end
    })
end
