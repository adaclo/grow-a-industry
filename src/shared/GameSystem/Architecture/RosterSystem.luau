-- RosterSystem.luau
-- Manages label-wide roster tension based on aggregate relationships and trait clashes.
-- Updates RosterTension conservatively.

local SharedModules     = script.Parent.Parent
local EventBus          = require(script.Parent:WaitForChild("EventBus"))
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local RosterSystem = {}

local function notify(text, typeStr)
    EventBus.Emit("READABILITY_NOTIFICATION", { Text = text, Type = typeStr or "Neutral" })
end

function RosterSystem.Init()
    -- Re-evaluate Roster Tension conservatively during passive ticks
    EventBus.Subscribe("PASSIVE_TICK", function()
        local state = PlayerDataManager.GetState()
        local roster = state.Artists
        if #roster == 0 then return end
        
        local totalResentment = 0
        local totalEgo = 0
        local hasDramaMagnet = false
        local styleClash = false
        
        local hasMainstream = false
        local hasUnderground = false

        for _, artist in pairs(roster) do
            totalResentment = totalResentment + (artist.Resentment or 0)
            totalEgo = totalEgo + (artist.Ego or 0)
            
            if artist.Tier == "Mainstream" then hasMainstream = true end
            if artist.Tier == "Underground" then hasUnderground = true end
            
            if artist.Traits then
                for _, trait in ipairs(artist.Traits) do
                    if trait == "DramaMagnet" then hasDramaMagnet = true end
                end
            end
        end
        
        local avgResentment = totalResentment / #roster
        local avgEgo = totalEgo / #roster
        if hasMainstream and hasUnderground then styleClash = true end
        
        -- Calculate target tension based on current conditions
        local targetTension = 0
        targetTension = targetTension + (avgResentment * 0.5)
        targetTension = targetTension + (avgEgo * 0.2)
        if hasDramaMagnet then targetTension = targetTension + 20 end
        if styleClash then targetTension = targetTension + 15 end
        
        targetTension = math.clamp(targetTension, 0, 100)
        
        local currentTension = state.Stats.RosterTension or 0
        -- Drift current tension towards target tension slowly (conservative updates)
        if currentTension < targetTension then
            PlayerDataManager.UpdateRosterTension(1)
        elseif currentTension > targetTension then
            PlayerDataManager.UpdateRosterTension(-1)
        end
        
        local newTension = state.Stats.RosterTension
        -- Readability notifications on tension threshold crosses
        if currentTension < 50 and newTension >= 50 then
            notify("Roster tension is rising.", "Negative")
        elseif currentTension >= 80 and newTension < 80 then
            notify("The roster is calming down a bit.", "Positive")
        elseif currentTension < 80 and newTension >= 80 then
            notify("Tension is critical! Conflicts are likely.", "Negative")
        end
    end)

    print("[RosterSystem] Initialized.")
end

return RosterSystem
