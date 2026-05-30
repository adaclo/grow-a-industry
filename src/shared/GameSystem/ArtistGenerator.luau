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

local TRAITS = {
    "Perfectionist",
    "CloutChaser",
    "Loyal",
    "DramaMagnet",
    "UnstableGenius"
}

local function getTraits()
    local roll = math.random(1, 100)
    local numTraits = 0
    if roll <= 5 then
        numTraits = 0
    elseif roll <= 75 then
        numTraits = 1
    else
        numTraits = 2
    end

    if numTraits == 0 then return {} end

    local selected = {}
    local firstTrait = TRAITS[math.random(#TRAITS)]
    table.insert(selected, firstTrait)

    if numTraits == 2 then
        local validSecondTraits = {}
        for _, t in ipairs(TRAITS) do
            if t ~= firstTrait then
                -- Define contradictory pairs that should be avoided entirely
                -- Let's say Perfectionist + CloutChaser is weird, but allowed.
                -- User rules: Loyal + UnstableGenius (rare), DramaMagnet + UnstableGenius (rare). 
                -- We'll just allow all except we can filter out if we want them to be strictly non-contradictory.
                -- Let's define strict contradictions:
                local isContradictory = false
                if (firstTrait == "Loyal" and t == "DramaMagnet") then isContradictory = true end
                -- But user said: "Loyal + DramaMagnet is acceptable".
                -- "Do not allow contradictory traits at the same time."
                -- Let's assume no hard contradictions among these 5, except maybe Loyal + CloutChaser is acceptable.
                -- I'll just avoid duplicating and maybe avoid "Loyal" + "UnstableGenius" 90% of the time.
                if (firstTrait == "Loyal" and t == "UnstableGenius") or (firstTrait == "UnstableGenius" and t == "Loyal") then
                    if math.random() > 0.1 then isContradictory = true end -- 10% chance
                end
                if (firstTrait == "DramaMagnet" and t == "UnstableGenius") or (firstTrait == "UnstableGenius" and t == "DramaMagnet") then
                    if math.random() > 0.2 then isContradictory = true end -- 20% chance
                end

                if not isContradictory then
                    table.insert(validSecondTraits, t)
                end
            end
        end
        if #validSecondTraits > 0 then
            table.insert(selected, validSecondTraits[math.random(#validSecondTraits)])
        end
    end

    return selected
end

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
        Traits = getTraits(),
        Cooldowns = {},
        IsPending = true,
        PendingTime = os.time() + 60, -- 60 seconds of pending (os.time() for consistency)
        -- Hidden Relationship / Psychology Metrics
        Trust = math.random(30, 60),
        Resentment = 0,
        Dependency = 0,
        Ambition = math.random(40, 80),
        CreativeAlignment = math.random(50, 100),
        Opinions = {},
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
