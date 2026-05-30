-- ReactiveEventEngine.luau
-- Evaluates contextual situations based on memory flags, artist traits, and game state.

local SharedModules = script.Parent.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local ReactiveEventEngine = {}

-- Database of contextual events
local EVENTS = {
    {
        Id = "artist_breakdown",
        Title = "ARTIST BREAKDOWN",
        Description = "An artist is buckling under extreme stress and acting erratically.",
        BaseWeight = 10,
        Cooldown = 600,
        Requirements = function(state, context)
            if not context.artistId then return false end
            local artist = nil
            for _, a in pairs(state.Artists) do
                if a.Id == context.artistId then artist = a break end
            end
            if not artist then return false end
            return artist.Stress >= 80
        end,
        GetWeight = function(state, context)
            local weight = 10
            local artist = nil
            for _, a in pairs(state.Artists) do
                if a.Id == context.artistId then artist = a break end
            end
            if artist and artist.Traits then
                for _, t in ipairs(artist.Traits) do
                    if t == "UnstableGenius" then weight = weight * 2.0 end
                    if t == "DramaMagnet" then weight = weight * 1.5 end
                    if t == "Loyal" then weight = weight * 0.5 end
                end
            end
            if PlayerDataManager.GetMemoryFlagRaw("viral_pressure") then
                weight = weight * 1.5
            end
            return weight
        end,
        Consequences = {
            -- Instead of hardcoding all UI, we return data that can be used by the event system
            -- or directly mutate state
            Type = "Negative",
            Options = {
                {
                    Text = "Send to Rehab ($2000)",
                    Expected = {"-Money", "+Stress relief"},
                    Effect = function(artistId)
                        return {
                            Title = "REHABILITATION",
                            Description = "The artist is recovering but the label took a financial hit.",
                            ResultType = "Neutral",
                            StatChanges = { Money = -2000 },
                            SpecialEvents = {"Artist stress completely cleared"},
                            artistId = artistId,
                            artistUpdate = { Stress = 0 }
                        }
                    end
                },
                {
                    Text = "Ignore It",
                    Expected = {"-Reputation", "-Loyalty"},
                    Effect = function(artistId)
                        return {
                            Title = "PUBLIC MELTDOWN",
                            Description = "The situation worsened publicly. Reputation damaged.",
                            ResultType = "Negative",
                            StatChanges = { Reputation = -15 },
                            SpecialEvents = {"Artist loyalty decreased"},
                            artistId = artistId,
                            artistUpdate = { Loyalty = -20 }
                        }
                    end
                }
            }
        }
    },
    {
        Id = "sellout_backlash",
        Title = "SELLOUT BACKLASH",
        Description = "Underground fans are loudly protesting your recent mainstream direction.",
        BaseWeight = 15,
        Cooldown = 300,
        Requirements = function(state, context)
            return PlayerDataManager.GetMemoryFlagRaw("sellout_arc") ~= nil
        end,
        GetWeight = function(state, context)
            local weight = 15
            if PlayerDataManager.GetMemoryFlagRaw("underground_roots") then
                weight = weight * 2.0 -- Worse if you betrayed your roots
            end
            return weight
        end,
        Consequences = {
            Type = "Risk",
            Options = {
                {
                    Text = "Ignore Them",
                    Expected = {"-Underground", "+Haters"},
                    Effect = function()
                        return {
                            Title = "FANS IGNORED",
                            Description = "Underground fans feel ignored and become haters.",
                            ResultType = "Negative",
                            CommunityChanges = { UndergroundAudience = -15, Haters = 10 },
                            SpecialEvents = {"Lost core fan support"}
                        }
                    end
                },
                {
                    Text = "Apologize Publicly",
                    Expected = {"-Hype", "+Reputation"},
                    Effect = function()
                        return {
                            Title = "PUBLIC APOLOGY",
                            Description = "You saved some face, but killed the hype.",
                            ResultType = "Neutral",
                            StatChanges = { Hype = -10, Reputation = 5 },
                            SpecialEvents = {"Hype died down"}
                        }
                    end
                }
            }
        }
    },
    {
        Id = "beef_escalation",
        Title = "BEEF ESCALATION",
        Description = "A rival label's artist just dropped a brutal diss track.",
        BaseWeight = 10,
        Cooldown = 600,
        Requirements = function(state, context)
            return PlayerDataManager.GetMemoryFlagRaw("industry_beef") ~= nil
        end,
        GetWeight = function(state, context)
            local weight = 10
            if PlayerDataManager.GetMemoryFlagRaw("heated_beef") then
                weight = weight * 3.0
            end
            return weight
        end,
        Consequences = {
            Type = "Risk",
            Options = {
                {
                    Text = "Respond with Diss Track",
                    Expected = {"+Hype", "+Stress"},
                    Effect = function()
                        return {
                            Title = "DISS TRACK",
                            Description = "The feud explodes! Massive hype but high stress.",
                            ResultType = "Positive",
                            StatChanges = { Hype = 30, Stress = 15 },
                            SpecialEvents = {"Beef escalated into a public spectacle"}
                        }
                    end
                },
                {
                    Text = "Take High Road",
                    Expected = {"+Reputation", "-Hype"},
                    Effect = function()
                        return {
                            Title = "HIGH ROAD",
                            Description = "Industry respects you, but fans are bored.",
                            ResultType = "Neutral",
                            StatChanges = { Reputation = 10, Hype = -10 },
                            SpecialEvents = {"Beef cooled down"}
                        }
                    end
                }
            }
        }
    }
}

-- Keep track of cooldowns internally
local cooldowns = {}

function ReactiveEventEngine.Evaluate(triggerContext)
    -- triggerContext e.g. { Action = "SONG_RELEASED", Payload = payload, artistId = "A-1234" }
    print(string.format("[ReactiveEventEngine] Evaluating triggers for action: %s", tostring(triggerContext.Action)))
    
    local state = PlayerDataManager.GetState()
    local currentTime = os.time()
    
    local candidates = {}
    local totalWeight = 0
    
    for _, event in ipairs(EVENTS) do
        local isOnCooldown = cooldowns[event.Id] and (currentTime < cooldowns[event.Id])
        if isOnCooldown then
            print(string.format("[ReactiveEventEngine] Event '%s' rejected (on cooldown)", event.Id))
            continue
        end
        
        local meetsReq = event.Requirements(state, triggerContext)
        if not meetsReq then
            print(string.format("[ReactiveEventEngine] Event '%s' rejected (requirements not met)", event.Id))
            continue
        end
        
        local w = event.GetWeight(state, triggerContext)
        if w > 0 then
            table.insert(candidates, {Event = event, Weight = w})
            totalWeight = totalWeight + w
            print(string.format("[ReactiveEventEngine] Event '%s' is a candidate (Weight: %.2f)", event.Id, w))
        else
            print(string.format("[ReactiveEventEngine] Event '%s' rejected (weight 0)", event.Id))
        end
    end
    
    if #candidates == 0 then
        print("[ReactiveEventEngine] No events triggered.")
        return nil
    end
    
    -- In an action-driven context, we might not always want an event to fire.
    -- We can set a base chance depending on the action. For instance, SONG_RELEASED has a 20% chance to trigger an event, scaled by weights.
    -- For now, if there's a valid candidate, we just pick one based on weights. (Later we can add a 'None' weight to represent peace).
    
    -- Add a "No Event" probability to prevent spam. E.g., Weight of 50 for nothing happening.
    local NO_EVENT_WEIGHT = 50
    totalWeight = totalWeight + NO_EVENT_WEIGHT
    
    local roll = math.random() * totalWeight
    print(string.format("[ReactiveEventEngine] Rolled %.2f / %.2f", roll, totalWeight))
    
    local current = 0
    local selectedEvent = nil
    
    for _, cand in ipairs(candidates) do
        current = current + cand.Weight
        if roll <= current then
            selectedEvent = cand.Event
            break
        end
    end
    
    if not selectedEvent then
        print("[ReactiveEventEngine] Selected: NONE (peaceful tick)")
        return nil
    end
    
    print(string.format("[ReactiveEventEngine] >>> TRIGGERED EVENT: %s <<<", selectedEvent.Id))
    cooldowns[selectedEvent.Id] = currentTime + (selectedEvent.Cooldown or 300)
    
    -- Broadcast the event for UI or system processing
    local EventBus = require(script.Parent:WaitForChild("EventBus"))
    -- Clone selectedEvent structure so we can pass triggerContext as Context safely
    local eventPayload = {
        Id = selectedEvent.Id,
        Title = selectedEvent.Title,
        Description = selectedEvent.Description,
        Consequences = selectedEvent.Consequences,
        Context = triggerContext
    }
    EventBus.Emit("REACTIVE_EVENT_TRIGGERED", { EventData = eventPayload, Context = triggerContext })
    
    return selectedEvent
end

return ReactiveEventEngine
