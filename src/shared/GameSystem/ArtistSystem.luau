local ArtistSystem = {
	COOLDOWNS = {
		Talk          = 30,
		RecordSong    = 120,
		SocialMedia   = 60,
		GiveBonus     = 180,
		Rest          = 300,
		BetterContract = 600
	}
}

-- Single source of truth: maps every UI action ID to the key stored in artist.Cooldowns.
local ACTION_TO_COOLDOWN_KEY = {
	TalkToArtist = "Talk",
	GiveBonus    = "GiveBonus",
	RecordSong   = "RecordSong",
	RestArtist   = "Rest",
	DropArtist   = "Drop",
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules     = script.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))
local ArtistGenerator   = require(SharedModules:WaitForChild("ArtistGenerator"))
local EventBus          = require(SharedModules:WaitForChild("Architecture"):WaitForChild("EventBus"))

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

function ArtistSystem.CheckCooldown(artist, actionId)
	if not artist.Cooldowns then return true end
	local endTime = artist.Cooldowns[actionId] or 0
	return os.time() >= endTime
end

-- Cooldown writes bypass EventBus — they are timing / entity-lifecycle state,
-- not gameplay consequences that need to be audited by StateResolver.
function ArtistSystem.SetCooldown(artistId, actionId, duration)
	local cooldownKey = ACTION_TO_COOLDOWN_KEY[actionId] or actionId
	local endTime     = os.time() + duration
	local state       = PlayerDataManager.GetState()
	for _, artist in pairs(state.Artists) do
		if artist.Id == artistId then
			if not artist.Cooldowns then artist.Cooldowns = {} end
			artist.Cooldowns[cooldownKey] = endTime
			PlayerDataManager.UpdateArtist(artistId, {Cooldowns = artist.Cooldowns})
			print("[ArtistSystem] SetCooldown", actionId, "key:", cooldownKey,
				"ends in", duration, "s | endTime:", endTime)
			return
		end
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- PerformAction
-- All gameplay stat / artist-data mutations now go through EventBus.
-- PlayerDataManager is never directly mutated here for game effects.
-- ─────────────────────────────────────────────────────────────────────────────

function ArtistSystem.PerformAction(actionId, targetId)
	local state   = PlayerDataManager.GetState()
	local myStats = {
		Fame       = state.Stats.Fame,
		Followers  = state.Stats.Followers,
		Reputation = state.Stats.Reputation,
		Money      = state.Stats.Money,
		StudioLevel = PlayerDataManager.CalculateStudioLevel()
	}

	local results = {
		Success     = true,
		Title       = "Artist Action",
		Outcome     = "Neutral",
		Description = "Nothing happened.",
		ResultType  = "Neutral"
	}

	local roll   = math.random(1, 100)
	local roster = state.Artists

	-- ── Slot check for signing actions ──────────────────────────────────────
	if actionId:find("Sign") or actionId == "DMFamous" then
		local maxSlots = myStats.StudioLevel
		if #roster >= maxSlots then
			return {
				Success = false,
				Error   = string.format(
					"STUDIO FULL! Level %d supports %d artists. Upgrade your studio!",
					myStats.StudioLevel, maxSlots)
			}
		end
	end

	-- ── DMFamous ─────────────────────────────────────────────────────────────
	if actionId == "DMFamous" then
		results.Title = "DM Famous Artist"
		local successChance = 10 + (myStats.Fame / 2) + (myStats.StudioLevel * 5)
		if roll < successChance then
			local artist = ArtistGenerator.Generate("Mainstream")
			results.Outcome     = "Replied!"
			results.Description = string.format(
				"%s replied to your DM! They are interested in a contract.", artist.Name)
			results.ResultType  = "Positive"
			print("[ArtistSystem] Emitting ARTIST_SIGNED (DMFamous)")
			EventBus.Emit("ARTIST_SIGNED", {
				addArtist = artist,
				signType  = "Famous"
			})
		else
			results.Outcome     = "Left on Read"
			results.Description = "The artist didn't reply. Your studio might be too small or your fame too low."
			results.ResultType  = "Negative"
		end

	-- ── SignUnderground ───────────────────────────────────────────────────────
	elseif actionId == "SignUnderground" then
		results.Title = "Sign Underground Artist"
		local successChance = 75 + (myStats.Reputation / 2)
		if state.Perception > 80 then successChance -= 30 end

		if roll < successChance then
			local artist = ArtistGenerator.Generate("Underground")
			results.Outcome     = "Success"
			results.Description = string.format("You signed %s! They're ready to grind.", artist.Name)
			results.ResultType  = "Positive"
			print("[ArtistSystem] Emitting ARTIST_SIGNED (Underground)")
			EventBus.Emit("ARTIST_SIGNED", {
				addArtist        = artist,
				signType         = "Underground",
				communityChanges = {UndergroundAudience = 150},
				perceptionChange = -5
			})
		else
			results.Outcome     = "Rejection"
			results.Description = "The artist decided to stay independent. They don't feel your label's vibe."
			results.ResultType  = "Negative"
		end

	-- ── SignMainstream ────────────────────────────────────────────────────────
	elseif actionId == "SignMainstream" then
		results.Title = "Sign Mainstream Artist"
		if myStats.StudioLevel < 2 or myStats.Fame < 15 or myStats.Followers < 500 then
			return {Success = false, Error = "REQUIREMENTS NOT MET! Need Studio Lvl 2, 15 Fame, and 500 Followers."}
		end

		local successChance = 45 + (myStats.Followers / 5000)
		if roll < successChance then
			local artist = ArtistGenerator.Generate("Mainstream")
			results.Outcome     = "Contract Signed"
			results.Description = string.format("Massive win! %s has joined your label.", artist.Name)
			results.ResultType  = "Positive"
			print("[ArtistSystem] Emitting ARTIST_SIGNED (Mainstream)")
			EventBus.Emit("ARTIST_SIGNED", {
				addArtist        = artist,
				signType         = "Mainstream",
				perceptionChange = 5
			})
		else
			results.Outcome     = "Negotiation Failed"
			results.Description = "The artist's manager asked for too much. Negotiation stalled."
			results.ResultType  = "Negative"
		end

	-- ── GiveBonus ─────────────────────────────────────────────────────────────
	elseif actionId == "GiveBonus" then
		results.Title = "Financial Bonus"
		local cost = 1000
		if myStats.Money < cost then return {Success = false, Error = "NOT ENOUGH MONEY!"} end

		local artist = nil
		for _, a in pairs(roster) do if a.Id == targetId then artist = a break end end
		if not artist then return {Success = false, Error = "Artist not found!"} end

		local newLoyalty = math.clamp(artist.Loyalty + 15, 0, 100)
		local newEgo     = math.clamp(artist.Ego     +  5, 0, 100)

		ArtistSystem.SetCooldown(targetId, "GiveBonus", ArtistSystem.COOLDOWNS.GiveBonus)

		results.Outcome     = "Happy Artist"
		results.Description = string.format(
			"You gave %s a $1,000 bonus. They are more loyal but their ego grew.", artist.Name)
		results.ResultType  = "Positive"

		print("[ArtistSystem] Emitting ARTIST_BONUS_PAID")
		EventBus.Emit("ARTIST_BONUS_PAID", {
			artistId     = targetId,
			artistUpdate = {Loyalty = newLoyalty, Ego = newEgo, Mood = "Happy"},
			statChanges  = {Money = -cost}
		})

	-- ── TalkToArtist ─────────────────────────────────────────────────────────
	elseif actionId == "TalkToArtist" then
		results.Title = "One-on-One Talk"
		local artist = nil
		for _, a in pairs(roster) do if a.Id == targetId then artist = a break end end
		if not artist then return {Success = false, Error = "Artist not found!"} end

		if not ArtistSystem.CheckCooldown(artist, "Talk") then
			return {Success = false, Error = "Artist is busy!"}
		end

		local newLoyalty = math.clamp(artist.Loyalty + 5,  0, 100)
		local newEgo     = math.clamp(artist.Ego     - 5,  0, 100)
		local newStress  = math.clamp(artist.Stress  - 10, 0, 100)

		ArtistSystem.SetCooldown(targetId, "TalkToArtist", ArtistSystem.COOLDOWNS.Talk)

		results.Outcome     = "Productive Talk"
		results.Description = string.format(
			"You talked with %s. They feel heard and less stressed.", artist.Name)
		results.ResultType  = "Positive"

		print("[ArtistSystem] Emitting ARTIST_TALKED")
		EventBus.Emit("ARTIST_TALKED", {
			artistId     = targetId,
			artistUpdate = {Loyalty = newLoyalty, Ego = newEgo, Stress = newStress, Mood = "Motivated"}
		})

	-- ── RecordSong ───────────────────────────────────────────────────────────
	elseif actionId == "RecordSong" then
		results.Title = "Recording Session"
		local artist = nil
		for _, a in pairs(roster) do if a.Id == targetId then artist = a break end end
		if not artist then return {Success = false, Error = "Artist not found!"} end
		if artist.IsPending then return {Success = false, Error = "Artist is still getting settled!"} end
		if not ArtistSystem.CheckCooldown(artist, "RecordSong") then
			return {Success = false, Error = "Studio is busy!"}
		end

		local newStress = math.clamp(artist.Stress + 20, 0, 100)
		local quality   = (artist.Talent * 0.7) + math.random(1, 30)
		local newMood   = artist.Mood
		local statChanges = {}

		if quality > 90 then
			results.Outcome     = "CHART TOPPER"
			results.Description = string.format(
				"%s recorded a HIT! Fame and money are pouring in.", artist.Name)
			results.ResultType  = "Positive"
			statChanges = {Money = 5000, Fame = 10}
		elseif quality < 30 then
			results.Outcome     = "FLOP"
			results.Description = string.format(
				"The song failed to gain traction. %s feels discouraged.", artist.Name)
			results.ResultType  = "Negative"
			newMood = "Burned Out"
		else
			results.Outcome     = "Solid Release"
			results.Description = string.format(
				"%s released a decent song. Good for the brand.", artist.Name)
			results.ResultType  = "Positive"
			statChanges = {Money = 1000}
		end

		ArtistSystem.SetCooldown(targetId, "RecordSong", ArtistSystem.COOLDOWNS.RecordSong)

		print("[ArtistSystem] Emitting ARTIST_RECORDED (outcome: " .. results.Outcome .. ")")
		EventBus.Emit("ARTIST_RECORDED", {
			artistId     = targetId,
			outcome      = results.Outcome,
			artistUpdate = {Stress = newStress, Mood = newMood},
			statChanges  = statChanges
		})

	-- ── RestArtist ────────────────────────────────────────────────────────────
	elseif actionId == "RestArtist" then
		results.Title = "Rest & Recovery"
		local artist = nil
		for _, a in pairs(roster) do if a.Id == targetId then artist = a break end end
		if not artist then return {Success = false, Error = "Artist not found!"} end

		ArtistSystem.SetCooldown(targetId, "RestArtist", ArtistSystem.COOLDOWNS.Rest)

		results.Outcome     = "Reset"
		results.Description = string.format(
			"%s is taking a break. They will be back refreshed.", artist.Name)
		results.ResultType  = "Positive"

		print("[ArtistSystem] Emitting ARTIST_RESTED")
		EventBus.Emit("ARTIST_RESTED", {
			artistId     = targetId,
			artistUpdate = {Stress = 0, Mood = "Neutral"}
		})

	-- ── DropArtist ────────────────────────────────────────────────────────────
	elseif actionId == "DropArtist" then
		results.Title = "Drop Artist"
		local artist = nil
		for _, a in pairs(roster) do if a.Id == targetId then artist = a break end end
		if not artist then return {Success = false, Error = "Artist not found!"} end

		local statChanges = {}
		if roll < 20 then
			results.Outcome     = "Ugly Breakup"
			results.Description = string.format(
				"%s is furious! They leaked a demo before leaving.", artist.Name)
			results.ResultType  = "Negative"
			statChanges = {Reputation = -10}
		else
			results.Outcome     = "Contract Terminated"
			results.Description = string.format("You parted ways with %s.", artist.Name)
			results.ResultType  = "Neutral"
		end

		print("[ArtistSystem] Emitting ARTIST_DROPPED (outcome: " .. results.Outcome .. ")")
		EventBus.Emit("ARTIST_DROPPED", {
			artistId     = targetId,
			outcome      = results.Outcome,
			statChanges  = statChanges,
			removeArtist = true
		})
	end

	return results
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Tick — only handles IsPending lifecycle (entity state, not a game effect)
-- ─────────────────────────────────────────────────────────────────────────────

function ArtistSystem.Tick()
	local state       = PlayerDataManager.GetState()
	local currentTime = os.time()
	local changed     = false

	for _, artist in pairs(state.Artists) do
		if artist.IsPending and currentTime >= (artist.PendingTime or 0) then
			artist.IsPending = false
			PlayerDataManager.UpdateArtist(artist.Id, {IsPending = false})
			changed = true
		end
	end

	if changed then
		-- Fire a no-op update to trigger UI refresh
		PlayerDataManager.UpdateArtist(nil, {})
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- GetActionState — read-only, no changes needed
-- ─────────────────────────────────────────────────────────────────────────────

function ArtistSystem.GetActionState(actionId, artistId)
	local state   = PlayerDataManager.GetState()
	local myStats = {
		Fame        = state.Stats.Fame,
		Followers   = state.Stats.Followers,
		Reputation  = state.Stats.Reputation,
		StudioLevel = state.StudioLevel or 1
	}

	-- Global actions
	if actionId == "SignMainstream" then
		if myStats.StudioLevel < 2  then return "LOCKED", "Studio Lvl 2+" end
		if myStats.Fame         < 15 then return "LOCKED", "Fame 15+"       end
		if myStats.Followers    < 500 then return "LOCKED", "500+ Followers" end
		if #state.Artists >= myStats.StudioLevel then return "FULL", "Upgrade Studio" end
		return "READY"
	end

	if actionId == "SignUnderground" or actionId == "DMFamous" then
		if #state.Artists >= myStats.StudioLevel then return "FULL", "Upgrade Studio" end
		return "READY"
	end

	-- Artist-specific actions
	if artistId then
		local artist = nil
		for _, a in pairs(state.Artists) do if a.Id == artistId then artist = a break end end
		if not artist then return "ERROR" end

		if artist.IsPending then
			local pendingRemaining = (artist.PendingTime or 0) - os.time()
			if pendingRemaining > 0 then
				print("[ArtistSystem] STATE:", actionId, "PENDING", math.ceil(pendingRemaining) .. "s")
				return "PENDING", math.ceil(pendingRemaining) .. "s"
			else
				artist.IsPending = false
				PlayerDataManager.UpdateArtist(artist.Id, {IsPending = false})
				print("[ArtistSystem] IsPending CLEARED for", artist.Id, "-> falling through to READY")
			end
		end

		local cooldownKey = ACTION_TO_COOLDOWN_KEY[actionId] or actionId
		local endTime     = artist.Cooldowns and (artist.Cooldowns[cooldownKey] or 0) or 0
		local remaining   = endTime - os.time()
		if remaining > 0 then
			print("[ArtistSystem] STATE:", actionId, "COOLDOWN", math.ceil(remaining) .. "s")
			return "COOLDOWN", math.ceil(remaining) .. "s"
		elseif endTime ~= 0 then
			artist.Cooldowns[cooldownKey] = nil
			print("[ArtistSystem] Cooldown EXPIRED and cleared:", actionId, "key:", cooldownKey)
		end

		print("[ArtistSystem] STATE:", actionId, "READY")
		return "READY"
	end

	return "READY"
end

return ArtistSystem
