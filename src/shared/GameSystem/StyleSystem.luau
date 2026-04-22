local StyleSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = script.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

function StyleSystem.UpdateStyleFromHistory()
    local state = PlayerDataManager.GetState()
    local history = state.History or {}
    
    if #history == 0 then return end
    
    local counts = {
        Commercial = 0,
        Experimental = 0,
        Underground = 0
    }
    
    for _, song in pairs(history) do
        -- logic to determine style based on genre and perception
        if song.Mainstreamness > 70 then
            counts.Commercial += 1
        elseif song.Mainstreamness < 30 then
            counts.Underground += 1
        else
            counts.Experimental += 1
        end
    end
    
    local currentStyle = "Experimental"
    if counts.Commercial > counts.Experimental and counts.Commercial > counts.Underground then
        currentStyle = "Commercial"
    elseif counts.Underground > counts.Experimental and counts.Underground > counts.Commercial then
        currentStyle = "Underground"
    end
    
    if state.Stats.Style ~= currentStyle then
        PlayerDataManager.UpdateStat("Style", currentStyle) -- This might need a custom updater if Stat is not in table
        -- Actually, Style is in state.Stats.Style now
    end
end

return StyleSystem
