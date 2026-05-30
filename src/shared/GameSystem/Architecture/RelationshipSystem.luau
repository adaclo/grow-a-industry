-- RelationshipSystem.luau
-- Manages hidden psychological metrics (Trust, Resentment, Dependency, Ambition, CreativeAlignment)
-- Subscribes to EventBus and emits READABILITY_NOTIFICATION when significant changes happen.

local SharedModules     = script.Parent.Parent
local EventBus          = require(script.Parent:WaitForChild("EventBus"))
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local RelationshipSystem = {}

-- Utility to safely modify and clamp artist hidden stats
local function updateArtistHiddenStat(artist, statName, delta)
    if not artist[statName] then artist[statName] = 0 end
    local oldVal = artist[statName]
    artist[statName] = math.clamp(artist[statName] + delta, 0, 100)
    
    -- Only return true if the value meaningfully changed thresholds
    if delta > 0 and oldVal < 70 and artist[statName] >= 70 then
        return "High"
    elseif delta < 0 and oldVal > 30 and artist[statName] <= 30 then
        return "Low"
    end
    return nil
end

local function notify(text, typeStr)
    EventBus.Emit("READABILITY_NOTIFICATION", { Text = text, Type = typeStr or "Neutral" })
end

local function updateOpinion(artistA, artistB, delta)
    if not artistA.Opinions then artistA.Opinions = {} end
    
    local oldData = artistA.Opinions[artistB.Id]
    local oldScore = oldData and oldData.Score or 0
    local newScore = math.clamp(oldScore + delta, -100, 100)
    
    local category = "Neutral"
    if newScore > 50 then category = "Friendly"
    elseif newScore < -75 then category = "Rivalry"
    elseif newScore < -25 then category = "Tense" end
    
    artistA.Opinions[artistB.Id] = { Score = newScore, Category = category }
    
    local oldCategory = oldData and oldData.Category or "Neutral"
    if oldCategory ~= category then
        if category == "Rivalry" then
            notify(string.format("A rivalry has formed between %s and %s.", artistA.Name, artistB.Name), "Negative")
        elseif category == "Friendly" then
            notify(string.format("%s and %s have become friends.", artistA.Name, artistB.Name), "Positive")
        end
    end
end

function RelationshipSystem.Init()
    EventBus.Subscribe("ARTIST_TALKED", function(payload)
        local state = PlayerDataManager.GetState()
        local artist = nil
        for _, a in pairs(state.Artists) do if a.Id == payload.artistId then artist = a break end end
        if not artist then return end

        local trustChange = updateArtistHiddenStat(artist, "Trust", 5)
        local resentChange = updateArtistHiddenStat(artist, "Resentment", -10)
        
        if trustChange == "High" then
            notify(string.format("%s completely trusts you now.", artist.Name), "Positive")
        elseif resentChange == "Low" then
            notify(string.format("%s let go of their grudges.", artist.Name), "Positive")
        end
    end)

    EventBus.Subscribe("ARTIST_BONUS_PAID", function(payload)
        local state = PlayerDataManager.GetState()
        local artist = nil
        for _, a in pairs(state.Artists) do if a.Id == payload.artistId then artist = a break end end
        if not artist then return end

        updateArtistHiddenStat(artist, "Trust", 10)
        local depChange = updateArtistHiddenStat(artist, "Dependency", 15)
        updateArtistHiddenStat(artist, "Resentment", -5)

        if depChange == "High" then
            notify(string.format("%s is becoming overly dependent on bonuses.", artist.Name), "Negative")
        end
        
        -- Jealousy mechanic: others gain a bit of resentment and lower opinion of the favored artist
        for _, other in pairs(state.Artists) do
            if other.Id ~= artist.Id then
                if updateArtistHiddenStat(other, "Resentment", 3) == "High" then
                    notify(string.format("%s is feeling jealous of the favoritism.", other.Name), "Negative")
                end
                updateOpinion(other, artist, -10)
            end
        end
    end)

    EventBus.Subscribe("ARTIST_RECORDED", function(payload)
        local state = PlayerDataManager.GetState()
        local artist = nil
        for _, a in pairs(state.Artists) do if a.Id == payload.artistId then artist = a break end end
        if not artist then return end

        if payload.outcome == "FLOP" then
            local resentChange = updateArtistHiddenStat(artist, "Resentment", 5)
            if resentChange == "High" then
                notify(string.format("%s blames the label for the flop.", artist.Name), "Negative")
            end
        elseif payload.outcome == "CHART TOPPER" then
            updateArtistHiddenStat(artist, "Ambition", 10)
            updateArtistHiddenStat(artist, "Trust", 5)
        end
    end)

    EventBus.Subscribe("ARTIST_RESTED", function(payload)
        local state = PlayerDataManager.GetState()
        local artist = nil
        for _, a in pairs(state.Artists) do if a.Id == payload.artistId then artist = a break end end
        if not artist then return end
        
        local resentChange = updateArtistHiddenStat(artist, "Resentment", -5)
        updateArtistHiddenStat(artist, "Trust", 2)
        if resentChange == "Low" then
            notify(string.format("%s feels much better after resting.", artist.Name), "Positive")
        end
    end)

    EventBus.Subscribe("SONG_RELEASED", function(payload)
        local state = PlayerDataManager.GetState()
        local artist = nil
        for _, a in pairs(state.Artists) do if a.Id == payload.ArtistId then artist = a break end end
        if not artist then return end
        
        -- Creative Alignment check based on label perception
        if state.Perception >= 70 and artist.Tier == "Underground" then
            if updateArtistHiddenStat(artist, "CreativeAlignment", -5) == "Low" then
                notify(string.format("%s feels like a sellout at this mainstream label.", artist.Name), "Negative")
            end
        elseif state.Perception <= 30 and artist.Tier == "Mainstream" then
            if updateArtistHiddenStat(artist, "CreativeAlignment", -5) == "Low" then
                notify(string.format("%s is frustrated by the lack of mainstream push.", artist.Name), "Negative")
            end
        end
    end)

    EventBus.Subscribe("PASSIVE_TICK", function()
        local state = PlayerDataManager.GetState()
        local ArtistSystem = require(SharedModules:WaitForChild("ArtistSystem"))
        
        -- Slow drift of opinions
        for i, a1 in ipairs(state.Artists) do
            for j, a2 in ipairs(state.Artists) do
                if i ~= j then
                    local delta = 0
                    if a1.Tier == a2.Tier then delta = delta + 1 end
                    if ArtistSystem.HasTrait(a2, "DramaMagnet") then delta = delta - 2 end
                    if ArtistSystem.HasTrait(a1, "Loyal") then delta = delta + 1 end
                    
                    if delta ~= 0 then
                        updateOpinion(a1, a2, delta)
                    end
                end
            end
        end
    end)
    
    print("[RelationshipSystem] Initialized.")
end

return RelationshipSystem
