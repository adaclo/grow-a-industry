-- SocialMediaSystem.luau
-- Calculates social media action outcomes and emits SOCIAL_ACTION_PERFORMED.
-- Does NOT mutate PlayerDataManager directly — all state changes flow through StateResolver.

local SocialMediaSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules     = script.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))
local StatsCalculator   = require(SharedModules:WaitForChild("StatsCalculator"))
local EventBus          = require(SharedModules:WaitForChild("Architecture"):WaitForChild("EventBus"))

-- ─────────────────────────────────────────────────────────────────────────────
-- Cooldowns (action timing only — bypasses EventBus, same rationale as ArtistSystem)
-- ─────────────────────────────────────────────────────────────────────────────
local COOLDOWNS = {
	YouTube     = 60,
	TikTok      = 30,
	BTS         = 120,
	Leak        = 300,
	Twitter     = 45,
	Promotion   = 600,
	RespondHate = 90
}

local lastUsed = {}

function SocialMediaSystem.GetCooldown(actionId)
	local last      = lastUsed[actionId] or 0
	local remaining = math.max(0, (last + (COOLDOWNS[actionId] or 0)) - os.time())
	return remaining
end

-- ─────────────────────────────────────────────────────────────────────────────
-- PerformAction
-- Builds an outcome payload and emits it — never writes state directly.
-- ─────────────────────────────────────────────────────────────────────────────
function SocialMediaSystem.PerformAction(actionId)
	local cooldown = SocialMediaSystem.GetCooldown(actionId)
	if cooldown > 0 then
		return { Success = false, Error = string.format("On cooldown! Wait %ds.", cooldown) }
	end

	local state       = PlayerDataManager.GetState()
	local totalStats  = StatsCalculator.GetTotalStats()
	local myStats     = state.Stats
	local roll        = math.random(1, 100)

	lastUsed[actionId] = os.time()

	-- Payload components (populated per action)
	local statChanges      = {}   -- { StatName = delta }
	local communityChanges = {}   -- { CommunityName = delta }
	local perceptionChange = nil
    local specialEvents    = {}

	-- UI result (display only — no mutations)
	local result = {
		Success    = true,
		Title      = "",
		Outcome    = "",
		Description = "",
		ResultType = "Neutral"
	}

	-- ── Helper: add a display stat entry without mutating anything ────────────
	local function addStat(name, value)
		statChanges[name] = (statChanges[name] or 0) + value
	end
	local function addCommunity(name, value)
		communityChanges[name] = (communityChanges[name] or 0) + value
	end

	-- ─────────────────────────────────────────────────────────────────────────
	if actionId == "YouTube" then
		result.Title = "Upload Beat to YouTube"
		if roll > 90 then
			result.Outcome     = "Underground Blowup"
			result.Description = "An underground collective found your beat and it's gaining traction!"
			result.ResultType  = "Positive"
			addStat("Followers", math.random(200, 500))
			addStat("Money",     math.random(50, 150))
			addCommunity("UndergroundAudience", 150)
		elseif roll > 20 then
			result.Outcome     = "Steady Views"
			result.Description = "The algorithm picked up your beat. Some new listeners are trickling in."
			result.ResultType  = "Positive"
			addStat("Followers", math.random(20, 100))
			addStat("Money",     math.random(10, 30))
			addCommunity("CasualListeners", 50)
		else
			result.Outcome     = "Beat Copied"
			result.Description = "A larger producer 'borrowed' your melody. You gained some views but lost credit."
			result.ResultType  = "Negative"
			addStat("Followers",  math.random(5, 20))
			addStat("Reputation", -5)
		end

	elseif actionId == "TikTok" then
		result.Title = "Upload TikTok Producing"
		local viralBonus = (myStats.Followers / 1000) * 5
		if (roll + viralBonus) > 95 then
			result.Outcome     = "Viral Trend"
			result.Description = "Your process video started a new trend! You're all over the FYP."
			result.ResultType  = "Positive"
			addStat("Followers", math.random(1000, 5000))
			addStat("Stress",    5)
			addCommunity("CasualListeners", 1000)
		elseif roll > 30 then
			result.Outcome     = "Good Engagement"
			result.Description = "People love seeing how you make hits. Decent growth today."
			result.ResultType  = "Positive"
			addStat("Followers", math.random(100, 400))
			addStat("Stress",    2)
		else
			result.Outcome     = "Flop"
			result.Description = "The video didn't catch on. Just some extra stress for nothing."
			result.ResultType  = "Negative"
			addStat("Stress", 10)
		end

	elseif actionId == "BTS" then
		result.Title = "Behind The Scenes"
		local prestigeBonus = totalStats.StudioPrestige or 0
		if (roll + prestigeBonus) > 80 then
			result.Outcome     = "Professional Look"
			result.Description = "Your studio setup looks incredible! Fans are impressed by your dedication."
			result.ResultType  = "Positive"
			addStat("Reputation", 15)
			addStat("Followers",  math.random(100, 300))
			addCommunity("LoyalFans",          100)
			addCommunity("UndergroundAudience", 50)
		else
			result.Outcome     = "Authentic Vibe"
			result.Description = "Fans appreciate the raw look into your creative process."
			result.ResultType  = "Positive"
			addStat("Reputation", 5)
			addCommunity("LoyalFans", 30)
		end

	elseif actionId == "Leak" then
		result.Title = "Leak Snippet"
		if roll > 90 then
			result.Outcome     = "Massive Hype"
			result.Description = "The snippet is everywhere! The streets are waiting for the full drop."
			result.ResultType  = "Positive"
			addStat("Hype",      40)
			addStat("Followers", math.random(500, 1500))
		elseif roll > 30 then
			result.Outcome     = "Snippet Season"
			result.Description = "Your fans are screen-recording the snippet. Hype is building up."
			result.ResultType  = "Positive"
			addStat("Hype",      15)
			addStat("Followers", math.random(50, 200))
		else
			result.Outcome     = "Song Leaked"
			result.Description = "Oh no! Someone found the full file. The hype is dead, and fans are disappointed."
			result.ResultType  = "Negative"
			addStat("Hype",       -20)
			addStat("Reputation", -10)
		end

	elseif actionId == "Twitter" then
		result.Title = "Twitter Beef"
		if roll > 80 then
			result.Outcome     = "Trending Topic"
			result.Description = "You ratio'd a major artist! You're the talk of the town."
			result.ResultType  = "Positive"
			addStat("Followers",  math.random(2000, 8000))
			addStat("Reputation", -5)
			addCommunity("Haters", 500)
		elseif roll > 40 then
			result.Outcome     = "Heated Thread"
			result.Description = "The drama is bringing in numbers, but your mentions are a mess."
			result.ResultType  = "Neutral"
			addStat("Followers", math.random(500, 1500))
			addStat("Stress",    15)
			addCommunity("Haters", 200)
		else
			result.Outcome     = "Cancelled?"
			result.Description = "You went too far. Your reputation is taking a hit and everyone is mad."
			result.ResultType  = "Negative"
			addStat("Reputation", -20)
			addStat("Followers",  -math.random(100, 500))
			addCommunity("Haters", 1000)
		end

	elseif actionId == "Promotion" then
		result.Title = "Buy Promotion"
		local cost = math.floor(200 + (myStats.Followers * 0.1))
		if myStats.Money < cost then
			return { Success = false, Error = "Not enough money for promotion!" }
		end
		-- Cost is deducted via statChanges
		addStat("Money", -cost)
		result.Description = "You paid for a massive ad campaign and playlist placements."
		result.ResultType  = "Positive"

		if roll > 20 then
			result.Outcome = "Mainstream Push"
			addStat("Followers", math.random(1000, 3000))
			addStat("Hype",      20)
			addCommunity("MainstreamAudience", 1000)
			perceptionChange = 3
		else
			result.Outcome     = "Industry Plant Allegations"
			result.Description = "People noticed the forced promotion. You gained followers but lost respect."
			result.ResultType  = "Neutral"
			addStat("Followers",  math.random(500, 1500))
			addStat("Reputation", -15)
			addCommunity("Haters", 300)
		end

	elseif actionId == "RespondHate" then
		result.Title = "Respond to Hate"
		local successChance = 50 - (myStats.Stress / 2) + (myStats.Reputation / 4)
		if roll < successChance then
			result.Outcome     = "Classy Response"
			result.Description = "You handled the haters with grace. Your fans love you even more."
			result.ResultType  = "Positive"
			addStat("Reputation", 10)
			addCommunity("LoyalFans", 100)
			addCommunity("Haters",    -200)
		else
			result.Outcome     = "Lost It"
			result.Description = "You let the haters get to you. You look desperate and stressed."
			result.ResultType  = "Negative"
			addStat("Reputation", -10)
			addStat("Stress",     20)
			addCommunity("Haters", 300)
		end
	end

    -- Format output description
    result.Description = result.Description .. "\n\nOutcome: " .. result.Outcome

    local payload = {
        Success = result.Success,
        Title = result.Title:upper(),
        Description = result.Description,
        ResultType = result.ResultType,
        StatChanges = statChanges,
        CommunityChanges = communityChanges,
        SpecialEvents = specialEvents,
        PerceptionChange = perceptionChange,
        
        -- EventBus metadata
        actionId = actionId,
        outcome = result.Outcome
    }
    
    require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)

	-- ── Emit to EventBus ──────────────────────────────────────────────────────
	print(string.format("[SocialMediaSystem] Emitting SOCIAL_ACTION_PERFORMED (%s | %s)", actionId, result.Outcome))
	EventBus.Emit("SOCIAL_ACTION_PERFORMED", payload)

	return payload
end

return SocialMediaSystem
