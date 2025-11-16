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
        local fileName = item.name:match('^(%d+)$') -- extract pure numeric filenames only

        if fileName == gameId then
            matchedScriptURL = item.download_url -- GitHub raw file URL
            break
        end
    end
end

if not matchedScriptURL then
    warn('No script found for this game.')
    return
end

-- Load and execute the script
local ok, loaded = pcall(function()
    return loadstring(game:HttpGet(matchedScriptURL))
end)

if not ok or not loaded then
    warn('Failed to load game script')
    return
end

print('Loaded game script')
loaded()
