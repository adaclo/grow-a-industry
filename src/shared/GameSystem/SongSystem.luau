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

function SongSystem.CalculateEstimate(sliders)
    -- Sliders: Commercial (0=Exp, 1=Comm), Budget (0-1), Promotion (0-1), Originality (0=Safe, 1=Risky)
    local cost = 50 + (sliders.Budget * 1000) + (sliders.Promotion * 500)
    local stress = 5 + (sliders.Budget * 15) + (sliders.Promotion * 20)
    
    local risk = (sliders.Originality * 50) + (sliders.Budget * 20)
    local reward = (sliders.Budget * 40) + (sliders.Promotion * 40) + (sliders.Commercial * 20)
    
    return {
        Cost = math.floor(cost),
        Stress = math.floor(stress),
        Risk = math.floor(risk),
        RewardPotential = math.floor(reward)
    }
end

function SongSystem.ReleaseSong(sliders, targetGenre)
    local state = PlayerDataManager.GetState()
    local myStats = state.Stats
    local estimates = SongSystem.CalculateEstimate(sliders)
    
    -- Check money
    if myStats.Money < estimates.Cost then
        return {Success = false, Error = "Not enough money!"}
    end

    -- Initial deductions
    PlayerDataManager.UpdateStat("Money", -estimates.Cost)
    
    -- Stress increases faster with hits/fame (simulated)
    local fameMod = math.clamp(myStats.Fame / 10000, 0, 10)
    local finalStressAdd = estimates.Stress + fameMod
    PlayerDataManager.UpdateStat("Stress", finalStressAdd)
    
    -- Roll for Outcome
    local currentStress = PlayerDataManager.GetStat("Stress")
    local roll = math.random(1, 100)
    
    -- Higher stress increases negative probabilities
    local negativeThreshold = 15 + (currentStress / 5)
    local hitThreshold = 85 - (currentStress / 10) + (sliders.Budget * 15) + (sliders.Promotion * 10)
    local viralThreshold = 95 - (currentStress / 15) + (sliders.Originality * 10) + (sliders.Promotion * 5)
    
    local outcome = OUTCOMES.SUCCESS_SMALL
    local moneyGained = 0
    local fameGained = 0
    local followersGained = 0
    local repChange = 0
    local desc = ""

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
            PlayerDataManager.UpdateCommunity("Haters", 100)
            PlayerDataManager.UpdateCommunity("LoyalFans", -20)
        end
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
        PlayerDataManager.UpdateCommunity("LoyalFans", 200)
    else
        outcome = OUTCOMES.SUCCESS_MODERATE
        moneyGained = math.random(estimates.Cost * 0.5, estimates.Cost * 1.5)
        fameGained = math.random(10, 100)
        followersGained = math.random(50, 200)
        repChange = 2
        desc = "Solid performance. Your fanbase is growing steadily."
    end

    -- Backlash System: High Fame + High Commercial = More Haters
    if myStats.Fame > 10000 and sliders.Commercial > 0.7 then
        local hateIncrease = math.floor(myStats.Fame / 1000) * sliders.Commercial
        PlayerDataManager.UpdateCommunity("Haters", hateIncrease)
    end

    -- Community System Updates
    if sliders.Commercial > 0.6 then
        PlayerDataManager.UpdateCommunity("MainstreamAudience", followersGained * 0.8)
        PlayerDataManager.UpdateCommunity("CasualListeners", followersGained * 0.5)
    else
        PlayerDataManager.UpdateCommunity("UndergroundAudience", followersGained * 0.8)
        PlayerDataManager.UpdateCommunity("LoyalFans", followersGained * 0.3)
    end

    -- Perception Update
    local pChange = (sliders.Commercial - 0.5) * 10
    PlayerDataManager.UpdatePerception(pChange)
    
    -- Genre Identity Update
    if targetGenre then
        PlayerDataManager.UpdateGenre(targetGenre, 1)
    end

    -- Apply results
    PlayerDataManager.UpdateStat("Money", math.floor(moneyGained))
    PlayerDataManager.UpdateStat("Fame", math.floor(fameGained))
    PlayerDataManager.UpdateStat("Followers", math.floor(followersGained))
    PlayerDataManager.UpdateStat("Reputation", math.floor(repChange))

    local finalResult = {
        Success = true,
        Title = outcome.Name,
        Description = desc,
        Outcome = outcome.Name,
        ResultType = outcome.Type,
        MoneyGained = math.floor(moneyGained),
        FameGained = math.floor(fameGained),
        FollowersGained = math.floor(followersGained),
        StressChange = math.floor(finalStressAdd),
        RepChange = math.floor(repChange)
    }
    
    -- Save to history
    PlayerDataManager.AddHistory({
        Sliders = sliders,
        Genre = targetGenre,
        Outcome = outcome.Name,
        Timestamp = os.time()
    })

    return finalResult
end

return SongSystem
