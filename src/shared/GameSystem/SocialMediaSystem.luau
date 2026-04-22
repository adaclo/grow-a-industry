local SocialMediaSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = script.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))
local StatsCalculator = require(SharedModules:WaitForChild("StatsCalculator"))

local COOLDOWNS = {
    YouTube = 60,
    TikTok = 30,
    BTS = 120,
    Leak = 300,
    Twitter = 45,
    Promotion = 600,
    RespondHate = 90
}

local lastUsed = {}

function SocialMediaSystem.GetCooldown(actionId)
    local last = lastUsed[actionId] or 0
    local remaining = math.max(0, (last + (COOLDOWNS[actionId] or 0)) - os.time())
    return remaining
end

function SocialMediaSystem.PerformAction(actionId)
    local cooldown = SocialMediaSystem.GetCooldown(actionId)
    if cooldown > 0 then
        return {Success = false, Error = string.format("Action on cooldown! Wait %d seconds.", cooldown)}
    end

    local state = PlayerDataManager.GetState()
    local totalStats = StatsCalculator.GetTotalStats()
    local myStats = state.Stats
    local communities = state.Communities
    
    local roll = math.random(1, 100)
    local results = {Success = true, Stats = {}}
    
    lastUsed[actionId] = os.time()

    if actionId == "YouTube" then
        results.Title = "Upload Beat to YouTube"
        if roll > 90 then
            results.Outcome = "Underground Blowup"
            results.Description = "An underground collective found your beat and it's gaining traction!"
            results.ResultType = "Positive"
            table.insert(results.Stats, {Name = "Followers", Value = math.random(200, 500)})
            table.insert(results.Stats, {Name = "Money", Value = math.random(50, 150)})
            PlayerDataManager.UpdateCommunity("UndergroundAudience", 150)
        elseif roll > 20 then
            results.Outcome = "Steady Views"
            results.Description = "The algorithm picked up your beat. Some new listeners are trickling in."
            results.ResultType = "Positive"
            table.insert(results.Stats, {Name = "Followers", Value = math.random(20, 100)})
            table.insert(results.Stats, {Name = "Money", Value = math.random(10, 30)})
            PlayerDataManager.UpdateCommunity("CasualListeners", 50)
        else
            results.Outcome = "Beat Copied"
            results.Description = "A larger producer 'borrowed' your melody. You gained some views but lost credit."
            results.ResultType = "Negative"
            table.insert(results.Stats, {Name = "Followers", Value = math.random(5, 20)})
            table.insert(results.Stats, {Name = "Reputation", Value = -5})
        end

    elseif actionId == "TikTok" then
        results.Title = "Upload TikTok Producing"
        local viralBonus = (myStats.Followers / 1000) * 5
        if (roll + viralBonus) > 95 then
            results.Outcome = "Viral Trend"
            results.Description = "Your process video started a new trend! You're all over the FYP."
            results.ResultType = "Positive"
            table.insert(results.Stats, {Name = "Followers", Value = math.random(1000, 5000)})
            table.insert(results.Stats, {Name = "Stress", Value = 5})
            PlayerDataManager.UpdateCommunity("CasualListeners", 1000)
        elseif roll > 30 then
            results.Outcome = "Good Engagement"
            results.Description = "People love seeing how you make hits. Decent growth today."
            results.ResultType = "Positive"
            table.insert(results.Stats, {Name = "Followers", Value = math.random(100, 400)})
            table.insert(results.Stats, {Name = "Stress", Value = 2})
        else
            results.Outcome = "Flop"
            results.Description = "The video didn't catch on. Just some extra stress for nothing."
            results.ResultType = "Negative"
            table.insert(results.Stats, {Name = "Stress", Value = 10})
        end

    elseif actionId == "BTS" then
        results.Title = "Behind The Scenes"
        local prestigeBonus = totalStats.StudioPrestige or 0
        if (roll + prestigeBonus) > 80 then
            results.Outcome = "Professional Look"
            results.Description = "Your studio setup looks incredible! Fans are impressed by your dedication."
            results.ResultType = "Positive"
            table.insert(results.Stats, {Name = "Reputation", Value = 15})
            table.insert(results.Stats, {Name = "Followers", Value = math.random(100, 300)})
            PlayerDataManager.UpdateCommunity("LoyalFans", 100)
            PlayerDataManager.UpdateCommunity("UndergroundAudience", 50)
        else
            results.Outcome = "Authentic Vibe"
            results.Description = "Fans appreciate the raw look into your creative process."
            results.ResultType = "Positive"
            table.insert(results.Stats, {Name = "Reputation", Value = 5})
            PlayerDataManager.UpdateCommunity("LoyalFans", 30)
        end

    elseif actionId == "Leak" then
        results.Title = "Leak Snippet"
        if roll > 90 then
            results.Outcome = "Massive Hype"
            results.Description = "The snippet is everywhere! The streets are waiting for the full drop."
            results.ResultType = "Positive"
            table.insert(results.Stats, {Name = "Hype", Value = 40})
            table.insert(results.Stats, {Name = "Followers", Value = math.random(500, 1500)})
        elseif roll > 30 then
            results.Outcome = "Snippet Season"
            results.Description = "Your fans are screen-recording the snippet. Hype is building up."
            results.ResultType = "Positive"
            table.insert(results.Stats, {Name = "Hype", Value = 15})
            table.insert(results.Stats, {Name = "Followers", Value = math.random(50, 200)})
        else
            results.Outcome = "Song Leaked"
            results.Description = "Oh no! Someone found the full file. The hype is dead, and fans are disappointed."
            results.ResultType = "Negative"
            table.insert(results.Stats, {Name = "Hype", Value = -20})
            table.insert(results.Stats, {Name = "Reputation", Value = -10})
        end

    elseif actionId == "Twitter" then
        results.Title = "Twitter Beef"
        if roll > 80 then
            results.Outcome = "Trending Topic"
            results.Description = "You ratio'd a major artist! You're the talk of the town."
            results.ResultType = "Positive"
            table.insert(results.Stats, {Name = "Followers", Value = math.random(2000, 8000)})
            table.insert(results.Stats, {Name = "Reputation", Value = -5})
            PlayerDataManager.UpdateCommunity("Haters", 500)
        elseif roll > 40 then
            results.Outcome = "Heated Thread"
            results.Description = "The drama is bringing in numbers, but your mentions are a mess."
            results.ResultType = "Neutral"
            table.insert(results.Stats, {Name = "Followers", Value = math.random(500, 1500)})
            table.insert(results.Stats, {Name = "Stress", Value = 15})
            PlayerDataManager.UpdateCommunity("Haters", 200)
        else
            results.Outcome = "Cancelled?"
            results.Description = "You went too far. Your reputation is taking a hit and everyone is mad."
            results.ResultType = "Negative"
            table.insert(results.Stats, {Name = "Reputation", Value = -20})
            table.insert(results.Stats, {Name = "Followers", Value = -math.random(100, 500)})
            PlayerDataManager.UpdateCommunity("Haters", 1000)
        end

    elseif actionId == "Promotion" then
        results.Title = "Buy Promotion"
        local cost = 200 + (myStats.Followers * 0.1)
        if myStats.Money < cost then
            return {Success = false, Error = "Not enough money for promotion!"}
        end
        
        PlayerDataManager.UpdateStat("Money", -cost)
        results.Description = "You paid for a massive ad campaign and playlist placements."
        results.ResultType = "Positive"
        
        if roll > 20 then
            results.Outcome = "Mainstream Push"
            table.insert(results.Stats, {Name = "Followers", Value = math.random(1000, 3000)})
            table.insert(results.Stats, {Name = "Hype", Value = 20})
            PlayerDataManager.UpdateCommunity("MainstreamAudience", 1000)
        else
            results.Outcome = "Industry Plant Allegations"
            results.Description = "People noticed the forced promotion. You gained followers but lost respect."
            results.ResultType = "Neutral"
            table.insert(results.Stats, {Name = "Followers", Value = math.random(500, 1500)})
            table.insert(results.Stats, {Name = "Reputation", Value = -15})
            PlayerDataManager.UpdateCommunity("Haters", 300)
        end

    elseif actionId == "RespondHate" then
        results.Title = "Respond to Hate"
        local successChance = 50 - (myStats.Stress / 2) + (myStats.Reputation / 4)
        if roll < successChance then
            results.Outcome = "Classy Response"
            results.Description = "You handled the haters with grace. Your fans love you even more."
            results.ResultType = "Positive"
            table.insert(results.Stats, {Name = "Reputation", Value = 10})
            PlayerDataManager.UpdateCommunity("LoyalFans", 100)
            PlayerDataManager.UpdateCommunity("Haters", -200)
        else
            results.Outcome = "Lost It"
            results.Description = "You let the haters get to you. You looks desperate and stressed."
            results.ResultType = "Negative"
            table.insert(results.Stats, {Name = "Reputation", Value = -10})
            table.insert(results.Stats, {Name = "Stress", Value = 20})
            PlayerDataManager.UpdateCommunity("Haters", 300)
        end
    end

    -- Apply Stat Changes
    for _, stat in pairs(results.Stats) do
        PlayerDataManager.UpdateStat(stat.Name, stat.Value)
    end

    return results
end

return SocialMediaSystem
