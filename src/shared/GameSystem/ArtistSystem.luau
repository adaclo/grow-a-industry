local ArtistSystem = {
	COOLDOWNS = {
		Talk          = 30,
		RecordSong    = 120,
		SocialMedia   = 60,
		GiveBonus     = 180,
		Rest          = 300,
		BetterContract = 600,
		DMFamous      = 60,
		SignUnderground = 120,
		SignMainstream = 240,
		DuoNew        = 120,
		StudioRest    = 60,
		StudioVacation = 300,
		StudioBreak   = 600
	}
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules     = script.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))
local ArtistGenerator   = require(SharedModules:WaitForChild("ArtistGenerator"))
local EventBus          = require(SharedModules:WaitForChild("Architecture"):WaitForChild("EventBus"))

function ArtistSystem.SetStudioCooldown(actionId, duration)
	local state = PlayerDataManager.GetState()
	if not state.StudioCooldowns then state.StudioCooldowns = {} end
	state.StudioCooldowns[actionId] = os.time() + duration
end

function ArtistSystem.GetStudioCooldown(actionId)
	local state = PlayerDataManager.GetState()
	if not state.StudioCooldowns then return 0 end
	return state.StudioCooldowns[actionId] or 0
end

-- Single source of truth: maps every UI action ID to the key stored in artist.Cooldowns.
local ACTION_TO_COOLDOWN_KEY = {
	TalkToArtist = "Talk",
	GiveBonus    = "GiveBonus",
	RecordSong   = "RecordSong",
	RestArtist   = "Rest",
	DropArtist   = "Drop",
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

function ArtistSystem.CheckCooldown(artist, actionId)
	if not artist.Cooldowns then return true end
	local endTime = artist.Cooldowns[actionId] or 0
	return os.time() >= endTime
end

function ArtistSystem.HasTrait(artist, traitName)
    if not artist.Traits then return false end
    for _, t in ipairs(artist.Traits) do
        if t == traitName then return true end
    end
    return false
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
		ArtistSystem.SetStudioCooldown(actionId, ArtistSystem.COOLDOWNS.DMFamous)
		results.Title = "DM Famous Artist"
		local successChance = 10 + (myStats.Fame / 2) + (myStats.StudioLevel * 5)
		if roll < successChance then
			local artist = ArtistGenerator.Generate("Mainstream")
			local payload = {
				Success = true,
				Title = "DM FAMOUS ARTIST",
				Description = string.format("%s replied to your DM! They are interested in a contract.", artist.Name),
				ResultType = "Positive",
				addArtist = artist,
				signType = "Famous",
				SpecialEvents = {"New famous artist joined the label"}
			}
			require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)
			print("[ArtistSystem] Emitting ARTIST_SIGNED (DMFamous)")
			EventBus.Emit("ARTIST_SIGNED", payload)
			return payload
		else
			local payload = {
				Success = true,
				Title = "DM FAMOUS ARTIST",
				Description = "The artist didn't reply. Your studio might be too small or your fame too low.",
				ResultType = "Negative",
				Outcome = "Left on Read",
				SpecialEvents = {}
			}
			require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)
			return payload
		end

	-- ── SignUnderground ───────────────────────────────────────────────────────
	elseif actionId == "SignUnderground" then
		ArtistSystem.SetStudioCooldown(actionId, ArtistSystem.COOLDOWNS.SignUnderground)
		results.Title = "Sign Underground Artist"
		local successChance = 75 + (myStats.Reputation / 2)
		if state.Perception > 80 then successChance -= 30 end

		if roll < successChance then
			local artist = ArtistGenerator.Generate("Underground")
			local payload = {
				Success = true,
				Title = "SIGN UNDERGROUND ARTIST",
				Description = string.format("You signed %s! They're ready to grind.", artist.Name),
				ResultType = "Positive",
				addArtist = artist,
				signType = "Underground",
				CommunityChanges = {UndergroundAudience = 150},
				PerceptionChange = -5,
				SpecialEvents = {"New underground artist joined the label"}
			}
			require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)
			print("[ArtistSystem] Emitting ARTIST_SIGNED (Underground)")
			EventBus.Emit("ARTIST_SIGNED", payload)
			return payload
		else
			local payload = {
				Success = true,
				Title = "SIGN UNDERGROUND ARTIST",
				Description = "The artist decided to stay independent. They don't feel your label's vibe.",
				ResultType = "Negative",
				Outcome = "Rejection",
				SpecialEvents = {}
			}
			require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)
			return payload
		end

	-- ── DuoNew ────────────────────────────────────────────────────────────────
	elseif actionId == "DuoNew" then
		ArtistSystem.SetStudioCooldown(actionId, ArtistSystem.COOLDOWNS.DuoNew)
		results.Title = "Sign New Duo"
		local successChance = 30 + (myStats.Followers / 1000)
		
		if roll < successChance then
			local artist = ArtistGenerator.Generate("New")
			artist.Name = artist.Name .. " (Duo)"
			local payload = {
				Success = true,
				Title = "DUO SIGNED",
				Description = string.format("You signed the rising duo %s!", artist.Name),
				ResultType = "Positive",
				addArtist = artist,
				signType = "Duo",
				SpecialEvents = {"A new duo joined the label"}
			}
			require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)
			EventBus.Emit("ARTIST_SIGNED", payload)
			return payload
		else
			local payload = {
				Success = true,
				Title = "DUO SIGNED",
				Description = "The duo split up before you could sign them.",
				ResultType = "Negative",
				Outcome = "Disbanded",
				SpecialEvents = {}
			}
			require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)
			return payload
		end

	-- ── StudioRest ──────────────────────────────────────────────────────────
	elseif actionId == "StudioRest" then
		ArtistSystem.SetStudioCooldown(actionId, ArtistSystem.COOLDOWNS.StudioRest)
		local stressReduction = -15
		local currentStress = PlayerDataManager.GetStat("Stress")
		local desc = "You took a short break and cleared your head."
		if currentStress < 15 then
			desc = "You're already feeling relaxed. The break was nice anyway."
			stressReduction = -math.min(5, currentStress)
		end
		local payload = {
			Success = true,
			Title = "REST",
			Description = desc,
			ResultType = "Positive",
			StatChanges = {Stress = stressReduction},
			SpecialEvents = {}
		}
		require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)
		EventBus.Emit("ARTIST_RESTED", payload)
		return payload

	-- ── StudioVacation ─────────────────────────────────────────────────────
	elseif actionId == "StudioVacation" then
		local myMoney = PlayerDataManager.GetStat("Money")
		if myMoney < 500 then
			return {Success = false, Error = "Not enough money! Vacation costs $500."}
		end
		ArtistSystem.SetStudioCooldown(actionId, ArtistSystem.COOLDOWNS.StudioVacation)
		local payload = {
			Success = true,
			Title = "VACATION",
			Description = "You took a vacation and came back refreshed and inspired.",
			ResultType = "Positive",
			StatChanges = {Stress = -40, Money = -500},
			SpecialEvents = {"Vacation vibes restored your creativity."}
		}
		require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)
		EventBus.Emit("ARTIST_RESTED", payload)
		return payload

	-- ── StudioBreak ────────────────────────────────────────────────────────
	elseif actionId == "StudioBreak" then
		ArtistSystem.SetStudioCooldown(actionId, ArtistSystem.COOLDOWNS.StudioBreak)
		local payload = {
			Success = true,
			Title = "TAKE A BREAK",
			Description = "You stepped away from the studio completely. The pressure is fading.",
			ResultType = "Positive",
			StatChanges = {Stress = -60},
			SpecialEvents = {"Extended break fully recharged your mental energy."}
		}
		require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)
		EventBus.Emit("ARTIST_RESTED", payload)
		return payload

	-- ── SignMainstream ────────────────────────────────────────────────────────
	elseif actionId == "SignMainstream" then
		if myStats.StudioLevel < 2 or myStats.Fame < 15 or myStats.Followers < 500 then
			return {Success = false, Error = "REQUIREMENTS NOT MET! Need Studio Lvl 2, 15 Fame, and 500 Followers."}
		end
		ArtistSystem.SetStudioCooldown(actionId, ArtistSystem.COOLDOWNS.SignMainstream)
		results.Title = "Sign Mainstream Artist"

		local successChance = 45 + (myStats.Followers / 5000)
		if roll < successChance then
			local artist = ArtistGenerator.Generate("Mainstream")
			local payload = {
				Success = true,
				Title = "SIGN MAINSTREAM ARTIST",
				Description = string.format("Massive win! %s has joined your label.", artist.Name),
				ResultType = "Positive",
				addArtist = artist,
				signType = "Mainstream",
				PerceptionChange = 5,
				SpecialEvents = {"New mainstream artist joined the label"}
			}
			require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)
			print("[ArtistSystem] Emitting ARTIST_SIGNED (Mainstream)")
			EventBus.Emit("ARTIST_SIGNED", payload)
			return payload
		else
			local payload = {
				Success = true,
				Title = "SIGN MAINSTREAM ARTIST",
				Description = "The artist's manager asked for too much. Negotiation stalled.",
				ResultType = "Negative",
				Outcome = "Negotiation Failed",
				SpecialEvents = {}
			}
			require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)
			return payload
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

		local payload = {
			Success = true,
			Title = "FINANCIAL BONUS",
			Description = string.format("You gave %s a $1,000 bonus.", artist.Name),
			ResultType = "Positive",
			StatChanges = {Money = -cost},
			SpecialEvents = {"Loyalty increased", "Ego increased"},
			artistId = targetId,
			artistUpdate = {Loyalty = newLoyalty, Ego = newEgo, Mood = "Happy"}
		}
		
		require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)

		print("[ArtistSystem] Emitting ARTIST_BONUS_PAID")
		EventBus.Emit("ARTIST_BONUS_PAID", payload)
		return payload

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

		local payload = {
			Success = true,
			Title = "ONE-ON-ONE TALK",
			Description = string.format("You talked with %s. They feel heard and less stressed.", artist.Name),
			ResultType = "Positive",
			SpecialEvents = {"Loyalty increased", "Ego decreased", "Stress decreased"},
			artistId = targetId,
			artistUpdate = {Loyalty = newLoyalty, Ego = newEgo, Stress = newStress, Mood = "Motivated"}
		}
		
		require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)

		print("[ArtistSystem] Emitting ARTIST_TALKED")
		EventBus.Emit("ARTIST_TALKED", payload)
		return payload

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
        
        local cooldownMult = 1.0

        if ArtistSystem.HasTrait(artist, "Perfectionist") then
            quality = quality + 15
            cooldownMult = 1.5
            newStress = math.clamp(newStress - 5, 0, 100) -- they like recording
        end
        if ArtistSystem.HasTrait(artist, "UnstableGenius") then
            -- Massive variance
            quality = quality + math.random(-35, 45)
        end

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

		local payload = {
			Success = true,
			Title = "RECORDING SESSION",
			Description = results.Description .. "\n\nOutcome: " .. results.Outcome,
			ResultType = results.ResultType,
			StatChanges = statChanges,
			SpecialEvents = {"Artist stress increased"},
			artistId = targetId,
			artistUpdate = {Stress = newStress, Mood = newMood}
		}

		ArtistSystem.SetCooldown(targetId, "RecordSong", ArtistSystem.COOLDOWNS.RecordSong * cooldownMult)

		require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)

		print("[ArtistSystem] Emitting ARTIST_RECORDED (outcome: " .. results.Outcome .. ")")
		EventBus.Emit("ARTIST_RECORDED", payload)
		return payload

	-- ── RestArtist ────────────────────────────────────────────────────────────
	elseif actionId == "RestArtist" then
		results.Title = "Rest & Recovery"
		local artist = nil
		for _, a in pairs(roster) do if a.Id == targetId then artist = a break end end
		if not artist then return {Success = false, Error = "Artist not found!"} end

		ArtistSystem.SetCooldown(targetId, "RestArtist", ArtistSystem.COOLDOWNS.Rest)

		local payload = {
			Success = true,
			Title = "REST & RECOVERY",
			Description = string.format("%s is taking a break. They will be back refreshed.", artist.Name),
			ResultType = "Positive",
			SpecialEvents = {"Stress completely removed"},
			artistId = targetId,
			artistUpdate = {Stress = 0, Mood = "Neutral"}
		}

		require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)

		print("[ArtistSystem] Emitting ARTIST_RESTED")
		EventBus.Emit("ARTIST_RESTED", payload)
		return payload

	-- ── DropArtist ────────────────────────────────────────────────────────────
	elseif actionId == "DropArtist" then
		results.Title = "Drop Artist"
		local artist = nil
		for _, a in pairs(roster) do if a.Id == targetId then artist = a break end end
		if not artist then return {Success = false, Error = "Artist not found!"} end

		local statChanges = {}
        local breakupChance = 20
        if ArtistSystem.HasTrait(artist, "Loyal") then breakupChance = breakupChance / 2 end
        if ArtistSystem.HasTrait(artist, "DramaMagnet") then breakupChance = breakupChance * 2 end
        
		if roll < breakupChance then
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

		local payload = {
			Success = true,
			Title = "DROP ARTIST",
			Description = results.Description .. "\n\nOutcome: " .. results.Outcome,
			ResultType = results.ResultType,
			StatChanges = statChanges,
			artistId = targetId,
			removeArtist = true,
			SpecialEvents = {}
		}
		if roll < breakupChance then
			table.insert(payload.SpecialEvents, "The artist leaked a demo on their way out.")
		end

		require(script.Parent:WaitForChild("PayloadLogger")).Log(payload)

		print("[ArtistSystem] Emitting ARTIST_DROPPED (outcome: " .. results.Outcome .. ")")
		EventBus.Emit("ARTIST_DROPPED", payload)
		return payload
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
		
		local cd = ArtistSystem.GetStudioCooldown(actionId) - os.time()
		if cd > 0 then return "COOLDOWN", math.ceil(cd) .. "s" end
		return "READY"
	end

	if actionId == "SignUnderground" or actionId == "DMFamous" or actionId == "DuoNew" then
		if #state.Artists >= myStats.StudioLevel then return "FULL", "Upgrade Studio" end
		
		local cd = ArtistSystem.GetStudioCooldown(actionId) - os.time()
		if cd > 0 then return "COOLDOWN", math.ceil(cd) .. "s" end
		return "READY"
	end

	if actionId == "StudioRest" or actionId == "StudioVacation" or actionId == "StudioBreak" then
		if actionId == "StudioVacation" then
			local money = PlayerDataManager.GetStat("Money")
			if money < 500 then return "LOCKED", "Need $500" end
		end
		local cd = ArtistSystem.GetStudioCooldown(actionId) - os.time()
		if cd > 0 then return "COOLDOWN", math.ceil(cd) .. "s" end
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
