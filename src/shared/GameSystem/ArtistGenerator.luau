local ArtistGenerator = {}

local STYLES = {
    "Mainstream Pop",
    "Underground Trap",
    "Experimental Electronic",
    "Indie Rock",
    "Hyperpop",
    "Viral Rap",
    "Lo-fi Producer",
    "Alternative Artist"
}

local FIRST_NAMES = {"Lil", "Young", "Big", "DJ", "MC", "Saint", "Kid", "Bad", "Good", "Dark", "Neon", "Cyber"}
local LAST_NAMES = {"Vibe", "Drop", "Beat", "Flow", "Soul", "Wave", "Glitch", "Echo", "Static", "Cloud", "Ghost", "Zero"}

function ArtistGenerator.Generate(tier)
    -- tier: "Underground", "Mainstream", "Famous", "New"
    local name = FIRST_NAMES[math.random(#FIRST_NAMES)] .. " " .. LAST_NAMES[math.random(#LAST_NAMES)]
    local style = STYLES[math.random(#STYLES)]
    
    local stats = {
        Id = "A-" .. math.random(1000, 9999),
        Name = name,
        Style = style,
        Tier = tier,
        Popularity = math.random(10, 30),
        Loyalty = math.random(40, 70),
        Ego = math.random(20, 60),
        Talent = math.random(30, 80),
        Risk = math.random(10, 50),
        Stress = 0,
        Cooldowns = {},
        IsPending = true,
        PendingTime = tick() + 60, -- 60 seconds of pending
    }

    if tier == "Mainstream" then
        stats.Popularity = math.random(50, 85)
        stats.Ego = math.random(50, 90)
        stats.ContractCost = math.random(5000, 20000)
    elseif tier == "Underground" then
        stats.Popularity = math.random(5, 25)
        stats.Talent = math.random(60, 95)
        stats.ContractCost = math.random(500, 2500)
    end

    -- Derive secondary stats
    stats.FollowersContribution = math.floor(stats.Popularity * 10)
    stats.DramaChance = stats.Ego / 100
    stats.TheftChance = (stats.Risk / 100) * (1 - (stats.Loyalty / 100))
    stats.BurnoutChance = (100 - stats.Loyalty) / 200
    
    stats.Mood = "Motivated"
    stats.History = {
        {Type = "Success", Desc = "Signed to the label."},
    }

    local descriptions = {
        "A quiet but gifted creator.",
        "Always looking for the next spotlight.",
        "Loyal to the craft, but risky to manage.",
        "A mainstream powerhouse in the making.",
        "Gritty underground energy with massive potential.",
        "Unpredictable and brilliant."
    }
    stats.Description = descriptions[math.random(#descriptions)]

    return stats
end

return ArtistGenerator
