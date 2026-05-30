-- StateResolver.luau
-- Central hub: listens to all EventBus events and applies mutations to PlayerDataManager.
-- Also triggers cascades: MomentumSystem, TrendSystem, memory flags.

local SharedModules     = script.Parent.Parent
local EventBus          = require(script.Parent:WaitForChild("EventBus"))
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))
local MomentumSystem    = require(script.Parent:WaitForChild("MomentumSystem"))
local TrendSystem       = require(script.Parent:WaitForChild("TrendSystem"))
local MemoryEvaluator   = require(script.Parent:WaitForChild("MemoryEvaluator"))
local ReactiveEventEngine = require(script.Parent:WaitForChild("ReactiveEventEngine"))
local RelationshipSystem = require(script.Parent:WaitForChild("RelationshipSystem"))
local RosterSystem       = require(script.Parent:WaitForChild("RosterSystem"))
local NarrativeChainSystem = require(script.Parent:WaitForChild("NarrativeChainSystem"))
local LabelIdentitySystem  = require(script.Parent:WaitForChild("LabelIdentitySystem"))
local ControversySystem    = require(script.Parent:WaitForChild("ControversySystem"))

local StateResolver = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Generic payload applier
-- Supported fields:
--   statChanges       { StatName = delta }
--   communityChanges  { CommunityName = delta }
--   perceptionChange  number
--   artistId          string
--   artistUpdate      { field = value }
--   addArtist         artistData table
--   removeArtist      boolean
-- ─────────────────────────────────────────────────────────────────────────────
local function applyPayload(eventName, payload)
	print(string.format("[StateResolver] Applying '%s'", eventName))

	local sChanges = payload.StatChanges or payload.statChanges
	if sChanges then
		for stat, amount in pairs(sChanges) do
			print(string.format("[StateResolver]   UpdateStat(%s, %s)", stat, tostring(amount)))
			PlayerDataManager.UpdateStat(stat, amount)
		end
	end

	local cChanges = payload.CommunityChanges or payload.communityChanges
	if cChanges then
		for community, amount in pairs(cChanges) do
			print(string.format("[StateResolver]   UpdateCommunity(%s, %s)", community, tostring(amount)))
			PlayerDataManager.UpdateCommunity(community, amount)
		end
	end

	if payload.perceptionChange then
		print(string.format("[StateResolver]   UpdatePerception(%s)", tostring(payload.perceptionChange)))
		PlayerDataManager.UpdatePerception(payload.perceptionChange)
	end

	if payload.artistUpdate and payload.artistId then
		print(string.format("[StateResolver]   UpdateArtist(%s)", tostring(payload.artistId)))
		PlayerDataManager.UpdateArtist(payload.artistId, payload.artistUpdate)
	end

	if payload.addArtist then
		print(string.format("[StateResolver]   AddArtist(%s)", tostring(payload.addArtist.Name)))
		PlayerDataManager.AddArtist(payload.addArtist)
	end

	if payload.removeArtist and payload.artistId then
		print(string.format("[StateResolver]   RemoveArtist(%s)", tostring(payload.artistId)))
		PlayerDataManager.RemoveArtist(payload.artistId)
	end

	print(string.format("[StateResolver] Finished '%s'", eventName))
end

-- ─────────────────────────────────────────────────────────────────────────────
function StateResolver.Init()
	print("[StateResolver] Initializing...")
	
	RelationshipSystem.Init()
	RosterSystem.Init()
    NarrativeChainSystem.Init()
    LabelIdentitySystem.Init()
    ControversySystem.Init()

	-- ── Legacy generic stat patch ──────────────────────────────────────────
	EventBus.Subscribe("STAT_CHANGE_REQUESTED", function(payload)
		print(string.format("[StateResolver] STAT_CHANGE_REQUESTED: %s %s",
			payload.Stat, tostring(payload.Amount)))
		PlayerDataManager.UpdateStat(payload.Stat, payload.Amount)
	end)

	-- ── SongSystem ────────────────────────────────────────────────────────
	EventBus.Subscribe("SONG_RELEASED", function(payload)
		print("[StateResolver] Applying SONG_RELEASED...")

		-- 1. Apply stat mutations
		local sChanges = payload.StatChanges or payload.statChanges
		if sChanges then
			for stat, amount in pairs(sChanges) do
				PlayerDataManager.UpdateStat(stat, amount)
			end
		else
			-- Legacy fallback
			PlayerDataManager.UpdateStat("Money",      payload.MoneyGained     or 0)
			PlayerDataManager.UpdateStat("Fame",       payload.FameGained      or 0)
			PlayerDataManager.UpdateStat("Followers",  payload.FollowersGained or 0)
			PlayerDataManager.UpdateStat("Reputation", payload.RepChange       or 0)
			PlayerDataManager.UpdateStat("Stress",     payload.StressChange    or 0)
		end

		local cChanges = payload.CommunityChanges or payload.communityChanges
		if cChanges then
			for community, amount in pairs(cChanges) do
				PlayerDataManager.UpdateCommunity(community, amount)
			end
		end
		if payload.PerceptionChange then
			PlayerDataManager.UpdatePerception(payload.PerceptionChange)
		end
		if payload.GenreUpdate then
			PlayerDataManager.UpdateGenre(payload.GenreUpdate, 1)
		end
		if payload.HistoryData then
			PlayerDataManager.AddHistory(payload.HistoryData)
		end

		-- 2. Momentum cascade (Phase 1)
		MomentumSystem.OnSongReleased(payload)

		-- 3. Trend cascade (Phase 2)
		TrendSystem.ApplyGenreModifiers(payload.GenreUpdate)

		-- 4. Memory flag cascades (Phase 4) ──────────────────────────────
		MemoryEvaluator.EvaluateSongRelease(payload)
		MomentumSystem.RefreshMemoryModifiers()

		-- 5. Action-driven Reactive Event Evaluation
		ReactiveEventEngine.Evaluate({Action = "SONG_RELEASED", Payload = payload, artistId = payload.ArtistId})

		print("[StateResolver] Finished SONG_RELEASED.")
	end)

	-- ── ArtistSystem events (generic) ─────────────────────────────────────
	local GENERIC_ARTIST_EVENTS = {
		"ARTIST_SIGNED",
		"ARTIST_TALKED",
		"ARTIST_BONUS_PAID",
		"ARTIST_RESTED",
		"ARTIST_RECORDED",
		"ARTIST_EVENT_TRIGGERED",
	}
	for _, eventName in pairs(GENERIC_ARTIST_EVENTS) do
		local name = eventName
		EventBus.Subscribe(name, function(payload)
			applyPayload(name, payload)
			ReactiveEventEngine.Evaluate({Action = name, Payload = payload, artistId = payload.artistId})
		end)
	end

	-- ── ARTIST_DROPPED — explicit handler for memory cascade ──────────────
	EventBus.Subscribe("ARTIST_DROPPED", function(payload)
		applyPayload("ARTIST_DROPPED", payload)

		-- Phase 4: Memory evaluation
		MemoryEvaluator.EvaluateArtistDropped(payload)
		MomentumSystem.RefreshMemoryModifiers()
		
		-- 5. Action-driven Reactive Event Evaluation
		ReactiveEventEngine.Evaluate({Action = "ARTIST_DROPPED", Payload = payload, artistId = payload.artistId})
	end)

	-- ── SOCIAL_ACTION_PERFORMED ───────────────────────────────────────────
	EventBus.Subscribe("SOCIAL_ACTION_PERFORMED", function(payload)
		applyPayload("SOCIAL_ACTION_PERFORMED", payload)

		-- Phase 4: Memory evaluation
		MemoryEvaluator.EvaluateSocialAction(payload)
		MomentumSystem.RefreshMemoryModifiers()

		-- 5. Action-driven Reactive Event Evaluation
		ReactiveEventEngine.Evaluate({Action = "SOCIAL_ACTION_PERFORMED", Payload = payload})
	end)

	-- ── REACTIVE_EVENT_CHOICE_RESOLVED ───────────────────────────────────
	EventBus.Subscribe("REACTIVE_EVENT_CHOICE_RESOLVED", function(payload)
		applyPayload("REACTIVE_EVENT_CHOICE_RESOLVED", payload)
		MomentumSystem.RefreshMemoryModifiers()
	end)

	print("[StateResolver] All event listeners registered.")
end

return StateResolver
