-- ControversySystem.luau
-- Manages public controversies and their lifecycle.

local SharedModules     = script.Parent.Parent
local EventBus          = require(script.Parent:WaitForChild("EventBus"))
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local ControversySystem = {}

local CONTROVERSY_TYPES = {
    TwitterBeef = {
        DecayRate = 2, -- severity drops by 2 every tick if ignored
    },
    SelloutBacklash = {
        DecayRate = 1,
    },
    ArtistLeak = {
        DecayRate = 3,
    }
}

function ControversySystem.Init()
    EventBus.Subscribe("PASSIVE_TICK", function()
        local state = PlayerDataManager.GetState()
        
        for id, data in pairs(state.Controversies) do
            if data.Status == "Active" then
                local def = CONTROVERSY_TYPES[data.Type]
                if def then
                    local newSeverity = data.Severity - def.DecayRate
                    
                    -- Check thresholds going up or down
                    if newSeverity <= 0 then
                        newSeverity = 0
                        data.Status = "Resolved"
                        EventBus.Emit("READABILITY_NOTIFICATION", {
                            Text = string.format("The %s controversy has finally blown over.", data.Type),
                            Type = "Positive"
                        })
                    end
                    
                    -- Update state
                    PlayerDataManager.UpdateControversy(id, { Severity = newSeverity, LastUpdatedTick = os.time() })
                    
                    -- Threshold notifications (if it was crossed downwards, or if we want to periodically remind)
                    -- For now, if we just decay, it will only cross downwards. 
                    -- Let's say if it crosses a threshold downwards, we notify relief.
                    if data.Severity >= 75 and newSeverity < 75 then
                        EventBus.Emit("READABILITY_NOTIFICATION", { Text = "The crisis is de-escalating to a mere public backlash.", Type = "NARRATIVE" })
                    elseif data.Severity >= 50 and newSeverity < 50 then
                        EventBus.Emit("READABILITY_NOTIFICATION", { Text = "The public backlash is fading into minor discussion.", Type = "NARRATIVE" })
                    elseif data.Severity >= 25 and newSeverity < 25 then
                        EventBus.Emit("READABILITY_NOTIFICATION", { Text = "People are starting to forget the controversy.", Type = "NARRATIVE" })
                    end
                end
            end
        end
    end)
    
    -- Expose a way to escalate/create controversies via EventBus
    EventBus.Subscribe("CONTROVERSY_ESCALATED", function(payload)
        local id = payload.Id
        local state = PlayerDataManager.GetState()
        local data = state.Controversies[id]
        
        if data then
            local oldSeverity = data.Severity
            local newSeverity = math.clamp(oldSeverity + payload.Amount, 0, 100)
            PlayerDataManager.UpdateControversy(id, { Severity = newSeverity, LastUpdatedTick = os.time() })
            
            -- Threshold upward notifications
            if oldSeverity < 25 and newSeverity >= 25 then
                EventBus.Emit("READABILITY_NOTIFICATION", { Text = "Minor discussion about a controversy has begun.", Type = "NARRATIVE" })
            elseif oldSeverity < 50 and newSeverity >= 50 then
                EventBus.Emit("READABILITY_NOTIFICATION", { Text = "The controversy has grown into a public backlash!", Type = "Negative" })
            elseif oldSeverity < 75 and newSeverity >= 75 then
                EventBus.Emit("READABILITY_NOTIFICATION", { Text = "CRISIS: The controversy is dominating industry news.", Type = "Negative" })
            elseif oldSeverity < 90 and newSeverity >= 90 then
                EventBus.Emit("READABILITY_NOTIFICATION", { Text = "MAJOR SCANDAL: The label's reputation is in severe danger!", Type = "Negative" })
            end
        else
            -- Create new
            PlayerDataManager.AddControversy({
                Id = id,
                Type = payload.Type,
                Severity = payload.Amount,
                SourceArtistId = payload.SourceArtistId,
                CreatedAtTick = os.time(),
                LastUpdatedTick = os.time(),
                Status = "Active"
            })
            EventBus.Emit("READABILITY_NOTIFICATION", { Text = string.format("A new %s controversy has emerged.", payload.Type), Type = "Negative" })
        end
    end)

    print("[ControversySystem] Initialized.")
end

return ControversySystem
