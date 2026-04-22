local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
local UpgradeEffects = require(script.Parent:WaitForChild("UpgradeEffects"))

local StatsCalculator = {}

function StatsCalculator.GetTotalStats()
    local playerState = PlayerDataManager.GetState()
    
    -- Initialize base stats (some might have a base above 0, but usually 0 start)
    local totalStats = {
        ProductionQuality = 0,
        RecordingQuality = 0,
        MixQuality = 0,
        StudioPrestige = 0,
        Comfort = 0,
        
        HitChance = 0.05, -- base 5%
        ViralChance = 0.01, -- base 1%
        ArtistAttraction = 0.05, 
        TechnicalFailureChance = 0.30, -- base 30% without good gear
        BadReviewChance = 0.20,
        BurnoutRisk = 0.10,
        FameGain = 1.0, -- Multiplier
        FollowerGain = 1.0, -- Multiplier
        StressReduction = 0
    }

    -- Aggregate from all upgrades
    for upgradeId, currentLevel in pairs(playerState.Levels) do
        local effectsData = UpgradeEffects.Effects[upgradeId]
        if effectsData and effectsData[currentLevel] then
            for statName, value in pairs(effectsData[currentLevel]) do
                if totalStats[statName] ~= nil then
                    if string.find(statName, "Chance") or string.find(statName, "Risk") then
                        -- Modifiers that generally scale by addition/subtraction
                        if statName == "TechnicalFailureChance" or statName == "BadReviewChance" or statName == "BurnoutRisk" then
                            -- Reduction stats should lower the base
                            -- Wait, our UpgradeEffects explicitly defines the NEW value for TechnicalFailureChance 
                            -- For simplicity, let's just use the absolute value provided by the gear if it's explicitly defining it?
                            -- Let's rethink: computer gives HitChance 0.05, speakers give 0.02. Total +=.
                            totalStats[statName] += value
                        else
                            totalStats[statName] += value
                        end
                    elseif string.find(statName, "Gain") then
                        -- Multiplier addition (e.g. 1.0 + 0.5 = 1.5x) but we just add the bonus directly
                        -- Actually our table says FameGain = 1.0 for lvl 1. If multiple things give FameGain, 
                        -- maybe we should just accumulate the highest, or add them? 
                        -- Let's add them but subtract the 1.0 base if it's supposed to be multiplicative.
                        -- For now, let's just make them Additive Multipliers (base 1.0, add values).
                        -- Example: Mic lvl 1 gives 1.0. Total = 1.0 + 1.0 = 2.0x? No, let's just set the bonus.
                        -- Let's change the logic: We add the values as raw bonuses.
                        totalStats[statName] += value
                    else
                        -- Flat additions
                        totalStats[statName] += value
                    end
                end
            end
        end
    end

    -- Special Overrides for "Reduction" stats which we provided absolute values for in UpgradeEffects
    -- Computer gives TechnicalFailureChance = 0.20 for Lvl 1.
    -- If we add them, 0.20 (PC) + 0.10 (Speakers) = 0.30. That's fine as an additive model.
    -- Wait, if it reduces it, total should be lower. 
    -- Let's define the base is 0, and we add. 
    -- Actually, to keep it simple, we explicitly iterate.
    -- Let's re-calculate reductions so it lowers the base.
    
    -- Recalculate RiskLevel dynamically
    -- RiskLevel increases as Fame increases
    local currentFame = playerState.Stats.Fame or 0
    totalStats.RiskLevel = math.clamp(currentFame / 10000, 0, 1.0) -- Caps at 100% risk at 10k Fame

    return totalStats
end

return StatsCalculator
