--// LocalScript

local HttpService = game:GetService('HttpService')

-- GitHub API endpoint for the Games folder
local apiURL = 'https://api.github.com/repos/Pacifisity/LuaU/contents/Games'

-- Fetch directory contents
local success, data = pcall(function()
    return HttpService:JSONDecode(game:HttpGet(apiURL))
end)

if not success or type(data) ~= 'table' then
    warn('Failed to retrieve scripts from GitHub.')
    return
end

local gameId = tostring(game.GameId)

local matchedScriptURL = nil

-- Search for a script whose filename matches the current game
for _, item in ipairs(data) do
    if item.type == 'file' and item.name then
        local fileName = item.name:match('^(%d+)$') -- pure numeric filenames

        if fileName == gameId then
            matchedScriptURL = item.download_url
            break
        end
    end
end

--=============================================================
-- FALLBACK
--=============================================================
if not matchedScriptURL then

    local defaultUI = "https://raw.githubusercontent.com/Pacifisity/LuaU/refs/heads/main/Sage.lua"

    local ok, runUI = pcall(function()
        return loadstring(game:HttpGet(defaultUI))
    end)

    if ok and runUI then
        runUI()
    else
        warn("Failed to load default Sage UI.")
    end

    return
end
--=============================================================


-- Load and execute the matched script
local ok, loaded = pcall(function()
    return loadstring(game:HttpGet(matchedScriptURL))
end)

if not ok or not loaded then
    warn('Failed to load game script')
    return
end

print('Loaded game script', game.GameId)
loaded()
