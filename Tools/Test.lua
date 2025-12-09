return function(window)

    print("TEST TOOL LOADED")

    -- make sure Tools tab exists
    if not window.Tools then
        warn("NO Tools TAB FOUND IN WINDOW")
        return
    end

    -- create a section
    local section = window.Tools:Section({
        Title = "TEST SECTION"
    })

    print("SECTION CREATED:", section)

    -- add a button
    section:Button({
        Title = "Test Button",
        Callback = function()
            print("Test Button Pressed")
        end
    })
end
