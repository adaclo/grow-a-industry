local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
local StatsCalculator = require(script.Parent:WaitForChild("StatsCalculator"))

local EventManager = {}

-- Event definitions with their base reward ranges
local Events = {
    Small = {
        {Name = "Small song release", Min = 50, Max = 120},
        {Name = "Beat sale", Min = 40, Max = 100},
        {Name = "Social media post", Min = 20, Max = 60},
        {Name = "Local collaboration", Min = 80, Max = 150},
        {Name = "Mixing session", Min = 60, Max = 120}
    },
    Medium = {
        {Name = "Small concert", Min = 200, Max = 400},
        {Name = "Basic videoclip", Min = 150, Max = 350},
        {Name = "Successful campaign", Min = 200, Max = 500},
        {Name = "Small sponsor", Min = 300, Max = 600},
        {Name = "Good song", Min = 400, Max = 800}
    },
    Large = {
        {Name = "Viral song", Min = 1500, Max = 4000},
        {Name = "Big festival", Min = 2000, Max = 5000},
        {Name = "Record label deal", Min = 3000, Max = 8000},
        {Name = "Famous artist", Min = 5000, Max = 10000},
        {Name = "Large sponsor", Min = 2000, Max = 6000},
        {Name = "Successful album", Min = 3000, Max = 7000}
    },
    Negative = {
        {Name = "Fake concerts", CostMultiplier = 0.5},
        {Name = "Unpaid performances", CostMultiplier = 0.2},
        {Name = "Artists stealing beats", CostMultiplier = 0.3},
        {Name = "Copyright strikes", CostMultiplier = 0.8},
        {Name = "Song takedowns", CostMultiplier = 0.4},
        {Name = "Rival producers copying songs", CostMultiplier = 0.3},
        {Name = "Equipment breaking", CostMultiplier = 0.6} -- Will scale off failure chance
    }
}

-- Trigger a random event based on current stats
function EventManager.TriggerRandomEvent()
    local stats = StatsCalculator.GetTotalStats()
    local playerState = PlayerDataManager.GetState()
    
    local roll = math.random()
    
    -- 1. Check for Negative Event (Driven by RiskLevel and FailureChance)
    local negativeChance = 0.05 + (stats.RiskLevel * 0.4) + stats.TechnicalFailureChance
    if roll < negativeChance then
        local evList = Events.Negative
        local ev = evList[math.random(1, #evList)]
        
        -- Calculate penalty (scales with money but has base penalty)
        local penalty = math.floor(100 + (playerState.Stats.Money * 0.1 * ev.CostMultiplier))
        PlayerDataManager.UpdateStat("Money", -penalty)
        return {Type = "Negative", Name = ev.Name, Amount = -penalty}
    end
    
    -- 2. Determine Positive Event Tier based on Fame and HitChance
    local isLarge = math.random() < (0.01 + (playerState.Stats.Fame / 50000) + (stats.HitChance * 0.2))
    local isMedium = math.random() < (0.1 + (playerState.Stats.Fame / 5000) + (stats.HitChance * 0.5))
    
    local evList
    if isLarge then
        evList = Events.Large
    elseif isMedium then
        evList = Events.Medium
    else
        evList = Events.Small
    end
    
    local ev = evList[math.random(1, #evList)]
    
    -- Calculate reward based on Quality Multipliers
    local qualityMultiplier = 1 + (stats.ProductionQuality / 100) + (stats.MixQuality / 100) + (stats.RecordingQuality / 100)
    local baseReward = math.random(ev.Min, ev.Max)
    local finalReward = math.floor(baseReward * qualityMultiplier)
    
    PlayerDataManager.UpdateStat("Money", finalReward)
    
    -- Gain Fame and Followers
    local fameGained = math.floor((finalReward / 10) * stats.FameGain)
    local followersGained = math.floor((finalReward / 5) * stats.FollowerGain)
    
    PlayerDataManager.UpdateStat("Fame", fameGained)
    PlayerDataManager.UpdateStat("Followers", followersGained)
    
    return {
        Type = "Positive",
        Tier = isLarge and "Large" or (isMedium and "Medium" or "Small"),
        Name = ev.Name,
        Amount = finalReward,
        Fame = fameGained,
        Followers = followersGained
    }
end

-- Process constant expenses (Can be called every minute or day cycle)
function EventManager.ProcessExpenses()
    local state = PlayerDataManager.GetState()
    
    -- Base expenses
    local rent = 100
    local electricity = 50
    -- Scales slightly with upgrades
    local upkeep = (state.Levels.Computer + state.Levels.Microphone + state.Levels.Speakers) * 20
    
    local totalExpenses = rent + electricity + upkeep
    PlayerDataManager.UpdateStat("Money", -totalExpenses)
    
    return totalExpenses
end

return EventManager
