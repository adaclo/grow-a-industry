-- LabelIdentitySystem.luau
-- Manages the dynamic evolution of the label's identity/archetype based on history, stats, and roster.

local SharedModules     = script.Parent.Parent
local EventBus          = require(script.Parent:WaitForChild("EventBus"))
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local LabelIdentitySystem = {}

local ARCHETYPES = {
    "Starting Out",
    "Underground Collective",
    "Mainstream Empire",
    "Viral Factory",
    "Controversial Label",
    "Experimental Scene"
}

local function calculateScores(state)
    local scores = {
        ["Starting Out"] = 0,
        ["Underground Collective"] = 0,
        ["Mainstream Empire"] = 0,
        ["Viral Factory"] = 0,
        ["Controversial Label"] = 0,
        ["Experimental Scene"] = 0
    }
    
    -- If we have almost nothing, stay "Starting Out"
    if #state.Artists == 0 and state.Stats.Fame < 5 then
        scores["Starting Out"] = 100
        return scores
    end
    
    -- Underground Collective
    if state.Perception < 40 then scores["Underground Collective"] = scores["Underground Collective"] + 30 end
    scores["Underground Collective"] = scores["Underground Collective"] + (state.Communities.UndergroundAudience / 10)
    
    -- Mainstream Empire
    if state.Perception > 60 then scores["Mainstream Empire"] = scores["Mainstream Empire"] + 30 end
    scores["Mainstream Empire"] = scores["Mainstream Empire"] + (state.Communities.MainstreamAudience / 20)
    if state.Stats.Money > 10000 then scores["Mainstream Empire"] = scores["Mainstream Empire"] + 15 end
    
    -- Viral Factory
    if state.Stats.Hype > 50 then scores["Viral Factory"] = scores["Viral Factory"] + 25 end
    
    local ArtistSystem = require(SharedModules:WaitForChild("ArtistSystem"))
    for _, artist in pairs(state.Artists) do
        if ArtistSystem.HasTrait(artist, "CloutChaser") then scores["Viral Factory"] = scores["Viral Factory"] + 10 end
        if ArtistSystem.HasTrait(artist, "DramaMagnet") then scores["Controversial Label"] = scores["Controversial Label"] + 15 end
        if artist.Tier == "Mainstream" then scores["Mainstream Empire"] = scores["Mainstream Empire"] + 10 end
        if artist.Tier == "Underground" then scores["Underground Collective"] = scores["Underground Collective"] + 10 end
    end
    
    -- Controversial Label
    if state.Stats.Reputation < 30 then scores["Controversial Label"] = scores["Controversial Label"] + 20 end
    for _, cont in pairs(state.Controversies) do
        if cont.Status == "Active" then
            scores["Controversial Label"] = scores["Controversial Label"] + (cont.Severity / 2)
        end
    end
    
    -- Experimental Scene
    local genreCount = 0
    for _, v in pairs(state.Genres) do if v > 10 then genreCount = genreCount + 1 end end
    if genreCount >= 3 then scores["Experimental Scene"] = scores["Experimental Scene"] + (genreCount * 10) end
    if state.Perception > 30 and state.Perception < 70 then scores["Experimental Scene"] = scores["Experimental Scene"] + 15 end

    return scores
end

function LabelIdentitySystem.Init()
    EventBus.Subscribe("PASSIVE_TICK", function()
        local state = PlayerDataManager.GetState()
        local scores = calculateScores(state)
        
        local currentIdentity = state.Stats.LabelIdentity or "Starting Out"
        local currentScore = scores[currentIdentity] or 0
        
        local bestIdentity = currentIdentity
        local bestScore = currentScore
        
        for identity, score in pairs(scores) do
            if identity ~= currentIdentity then
                -- Hysteresis: only switch if the new score beats the current identity by at least 15 points
                if score > currentScore + 15 and score > bestScore then
                    bestScore = score
                    bestIdentity = identity
                end
            end
        end
        
        if bestIdentity ~= currentIdentity then
            PlayerDataManager.UpdateLabelIdentity(bestIdentity)
            EventBus.Emit("READABILITY_NOTIFICATION", {
                Text = string.format("Industry insiders are now viewing your label as a %s.", bestIdentity:upper()),
                Type = "NARRATIVE"
            })
        end
    end)
    
    print("[LabelIdentitySystem] Initialized.")
end

return LabelIdentitySystem
