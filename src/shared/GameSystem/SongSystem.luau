local SongSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = script.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

-- Configuration for outcome buckets
local OUTCOMES = {
    SUCCESS_SMALL = {Name = "Small Success", Type = "Neutral"},
    SUCCESS_MODERATE = {Name = "Moderate Success", Type = "Positive"},
    SUCCESS_HIT = {Name = "Hit Song", Type = "Positive"},
    SUCCESS_VIRAL = {Name = "Viral Song", Type = "Positive"},
    SUCCESS_CULT = {Name = "Cult Classic", Type = "Positive"},
    EVENT_BAD_REVIEW = {Name = "Bad Review", Type = "Negative"},
    EVENT_LEAK = {Name = "Song Leak", Type = "Negative"},
    EVENT_COPYRIGHT = {Name = "Copyright Strike", Type = "Negative"},
    EVENT_STOLEN = {Name = "Beat Stolen", Type = "Negative"},
    EVENT_COPIED = {Name = "Rival Copied Style", Type = "Negative"},
    EVENT_SOLD_OUT = {Name = "Fans Say You Sold Out", Type = "Negative"},
    EVENT_LOYALTY = {Name = "Underground Support", Type = "Positive"},
    EVENT_STYLE_REJECT = {Name = "Fans Reject Style Change", Type = "Negative"},
    EVENT_BURNOUT = {Name = "Producer Burnout", Type = "Negative"}
}

local PRODUCTION_TIERS = {
    {Name = "Bedroom Demo", BaseCost = 0, RewardMult = 0.15, StressMult = 0.3, ViralBonus = 5},
    {Name = "Cheap Production", BaseCost = 100, RewardMult = 0.5, StressMult = 0.6, ViralBonus = 0},
    {Name = "Professional", BaseCost = 500, RewardMult = 1.0, StressMult = 1.0, ViralBonus = 0},
    {Name = "Premium", BaseCost = 1000, RewardMult = 2.0, StressMult = 1.5, ViralBonus = -5},
}

SongSystem.PRODUCTION_TIERS = PRODUCTION_TIERS


function SongSystem.GetArtistIdentity()
    local state = PlayerDataManager.GetState()
    local genres = state.Genres
    local perception = state.Perception -- 0-100 (Underground to Mainstream)
    
    -- Find top genre
    local topGenre = "Producer"
    local maxVal = -1
    for name, val in pairs(genres) do
        if val > maxVal then
            maxVal = val
            topGenre = name
        end
    end
    
    if maxVal == 0 then topGenre = "General" end

    -- Determine Prefix based on perception
    local prefix = "Underground"
    if perception > 75 then
        prefix = "Mainstream"
    elseif perception > 60 then
        prefix = "Pop"
    elseif perception > 40 then
        prefix = "Independent"
    elseif perception > 25 then
        prefix = "Niche"
    end
    
    -- Special tags based on history/stats
    local totalHits = 0
    for _, song in pairs(state.History) do
        if song.Outcome == "Hit Song" or song.Outcome == "Viral Song" then
            totalHits += 1
        end
    end
    
    if totalHits > 5 then
        return "Viral Hitmaker"
    end
    
    return prefix .. " " .. topGenre .. " " .. (perception > 50 and "Artist" or "Producer")
end

function SongSystem.GetAvailableTier(sliders)
    local budget = sliders.Budget or 0
    if budget >= 0.75 then return PRODUCTION_TIERS[4]
    elseif budget >= 0.4 then return PRODUCTION_TIERS[3]
    elseif budget >= 0.15 then return PRODUCTION_TIERS[2]
    else return PRODUCTION_TIERS[1]
    end
end

function SongSystem.CalculateEstimate(sliders)
    local tier = SongSystem.GetAvailableTier(sliders)
    local cost = tier.BaseCost + (sliders.Promotion * 500)
    local stress = math.floor((5 + (sliders.Promotion * 20)) * tier.StressMult)
    local risk = (sliders.Originality * 50) + (sliders.Budget * 20)
    local reward = ((sliders.Budget * 40) + (sliders.Promotion * 40) + (sliders.Commercial * 20)) * tier.RewardMult
    return {
        Cost = math.floor(cost),
        Stress = stress,
        Risk = math.floor(risk),
        RewardPotential = math.floor(reward),
        TierName = tier.Name
    }
end

function SongSystem.ReleaseSong(sliders, targetGenre)
    local state = PlayerDataManager.GetState()
    local myStats = state.Stats
    local estimates = SongSystem.CalculateEstimate(sliders)
    local tier = SongSystem.GetAvailableTier(sliders)
    
    local EventBus = require(script.Parent:WaitForChild("Architecture"):WaitForChild("EventBus"))
    local ModifierSystem = require(script.Parent:WaitForChild("Architecture"):WaitForChild("ModifierSystem"))
    
    -- Check money
    if myStats.Money < estimates.Cost then
        return {Success = false, Error = "Not enough money!"}
    end

    -- 1. Calculate Base Modifiers & Stress
    local fameMod = math.clamp(myStats.Fame / 10000, 0, 10)
    local baseStressAdd = estimates.Stress + fameMod
    local finalStressAdd = ModifierSystem.Calculate("ArtistStress", baseStressAdd)
    local currentStress = PlayerDataManager.GetStat("Stress") + finalStressAdd
    
    -- Roll for Outcome
    local roll = math.random(1, 100)
    
    -- 2. Threshold Modifiers
    local negativeThreshold = ModifierSystem.Calculate("NegativeChance", 15 + (currentStress / 5))
    local hitThreshold = ModifierSystem.Calculate("HitChance", 85 - (currentStress / 10) + (sliders.Budget * 15) + (sliders.Promotion * 10))
    local viralThreshold = ModifierSystem.Calculate("ViralChance", 95 - (currentStress / 15) + (sliders.Originality * 10) + (sliders.Promotion * 5)) + tier.ViralBonus
    
    -- Consistency Penalty logic
    local identityMismatch = 0
    if sliders.Commercial > 0.7 and state.Perception < 30 then
        identityMismatch = 20 -- Mainstream song from underground artist
    elseif sliders.Commercial < 0.3 and state.Perception > 70 then
        identityMismatch = 20 -- Experimental song from commercial artist
    end
    
    -- Adjust thresholds based on mismatch
    hitThreshold += (identityMismatch / 2)
    viralThreshold += (identityMismatch / 2)

    local outcome = OUTCOMES.SUCCESS_SMALL
    local moneyGained = 0
    local fameGained = 0
    local followersGained = 0
    local repChange = 0
    local desc = ""
    local communityChanges = {}

    if roll < negativeThreshold then
        -- Negative Outcome
        local pool = {OUTCOMES.EVENT_BAD_REVIEW, OUTCOMES.EVENT_LEAK, OUTCOMES.EVENT_COPYRIGHT, OUTCOMES.EVENT_STOLEN}
        -- Add "Sold Out" if too popular and too commercial
        if myStats.Fame > 5000 and sliders.Commercial > 0.8 then
            table.insert(pool, OUTCOMES.EVENT_SOLD_OUT)
        end
        -- Add burnout if high stress
        if currentStress > 70 then
            table.insert(pool, OUTCOMES.EVENT_BURNOUT)
        end
        
        outcome = pool[math.random(#pool)]
        moneyGained = -estimates.Cost * 0.2
        repChange = -10
        desc = "Something went wrong in the industry..."
        
        if outcome == OUTCOMES.EVENT_SOLD_OUT then
            communityChanges["Haters"] = 100
            communityChanges["LoyalFans"] = -20
        end
    elseif tier.Name == "Bedroom Demo" and roll > 93 then
        outcome = OUTCOMES.SUCCESS_VIRAL
        moneyGained = math.random(200, 800)
        fameGained = math.random(100, 500)
        followersGained = math.random(500, 2000)
        repChange = 20
        desc = "Your bedroom demo went viral! DIY authenticity wins."
        table.insert(specialEvents, "DIY Viral Moment")
    elseif roll > viralThreshold then
        outcome = OUTCOMES.SUCCESS_VIRAL
        moneyGained = math.random(500, 2000) * (1 + sliders.Promotion)
        fameGained = math.random(500, 1500)
        followersGained = math.random(2000, 5000)
        repChange = 15
        desc = "The internet is obsessed! You're everywhere."
    elseif roll > hitThreshold then
        outcome = OUTCOMES.SUCCESS_HIT
        moneyGained = math.random(800, 2500) * (1 + sliders.Budget)
        fameGained = math.random(300, 800)
        followersGained = math.random(500, 1500)
        repChange = 10
        desc = "A certified charts killer!"
    elseif sliders.Originality > 0.7 and roll > (hitThreshold - 20) then
        outcome = OUTCOMES.SUCCESS_CULT
        moneyGained = math.random(100, 500)
        fameGained = math.random(50, 200)
        followersGained = math.random(100, 300)
        repChange = 25 -- High Rep for Cult Classics
        desc = "Niche communities are hailing this as a masterpiece."
        communityChanges["LoyalFans"] = 200
    else
        outcome = OUTCOMES.SUCCESS_MODERATE
        local baseMoney = math.max(100, estimates.Cost)
        moneyGained = math.random(baseMoney * 0.5, baseMoney * 1.5)
        fameGained = math.random(10, 100)
        followersGained = math.random(50, 200)
        repChange = 2
        desc = "Solid performance. Your fanbase is growing steadily."
    end

    -- Backlash System: High Fame + High Commercial = More Haters
    if myStats.Fame > 10000 and sliders.Commercial > 0.7 then
        local hateIncrease = math.floor(myStats.Fame / 1000) * sliders.Commercial
        communityChanges["Haters"] = (communityChanges["Haters"] or 0) + hateIncrease
    end

    -- Community System Updates
    if sliders.Commercial > 0.6 then
        communityChanges["MainstreamAudience"] = (communityChanges["MainstreamAudience"] or 0) + (followersGained * 0.8)
        communityChanges["CasualListeners"] = (communityChanges["CasualListeners"] or 0) + (followersGained * 0.5)
    else
        communityChanges["UndergroundAudience"] = (communityChanges["UndergroundAudience"] or 0) + (followersGained * 0.8)
        communityChanges["LoyalFans"] = (communityChanges["LoyalFans"] or 0) + (followersGained * 0.3)
    end

    -- Perception Update
    local pChange = (sliders.Commercial - 0.5) * 10
    
    -- 3. Final Multipliers from Modifiers
    moneyGained = ModifierSystem.Calculate("SongRevenue", moneyGained)
    
    -- Apply Tier Multipliers
    moneyGained = moneyGained * tier.RewardMult
    fameGained = fameGained * tier.RewardMult
    followersGained = followersGained * tier.RewardMult
    
    -- Calculate net money
    local netMoneyGained = moneyGained - estimates.Cost

    local specialEvents = {}
    if outcome == OUTCOMES.EVENT_SOLD_OUT then
        table.insert(specialEvents, "Underground fans hated this commercial direction.")
    elseif outcome == OUTCOMES.SUCCESS_CULT then
        table.insert(specialEvents, "Niche communities are obsessed with this release.")
    end
    if identityMismatch > 0 then
        table.insert(specialEvents, "Fans were confused by the sudden change in style.")
    end
    if finalStressAdd > 15 then
        table.insert(specialEvents, "The stressful production took a toll on the artist.")
    end

    -- 4. Build Final Payload
    local finalResult = {
        Success = true,
        Title = "SONG RELEASED",
        Description = string.format("%s\n\nOutcome: %s | Production: %s", desc, outcome.Name, tier.Name),
        ResultType = outcome.Type,
        StatChanges = {
            Money = math.floor(netMoneyGained),
            Fame = math.floor(fameGained),
            Followers = math.floor(followersGained),
            Stress = math.floor(finalStressAdd),
            Reputation = math.floor(repChange),
        },
        CommunityChanges = communityChanges,
        SpecialEvents = specialEvents,
        PerceptionChange = pChange,
        GenreUpdate = targetGenre,
        TierName = tier.Name,
        HistoryData = {
            Sliders = sliders,
            Genre = targetGenre,
            Outcome = outcome.Name,
            Timestamp = os.time()
        }
    }
    
    local PayloadLogger = require(script.Parent:WaitForChild("PayloadLogger"))
    PayloadLogger.Log(finalResult)
    
    print("[SongSystem] Outcome generated. Emitting SONG_RELEASED...")
    EventBus.Emit("SONG_RELEASED", finalResult)

    -- Return directly to UI to preserve backwards compatibility
    return finalResult
end

return SongSystem
