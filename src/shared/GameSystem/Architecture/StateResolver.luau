local SharedModules = script.Parent.Parent
local EventBus = require(script.Parent:WaitForChild("EventBus"))
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local StateResolver = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Generic payload applier
-- Supported payload fields:
--   statChanges       : { StatName = deltaNumber, ... }
--   communityChanges  : { CommunityName = deltaNumber, ... }
--   perceptionChange  : number
--   artistUpdate      : { field = value, ... }   (applied via UpdateArtist)
--   artistId          : string  (required when artistUpdate or removeArtist)
--   addArtist         : artistData table
--   removeArtist      : boolean
-- ─────────────────────────────────────────────────────────────────────────────
local function applyPayload(eventName, payload)
	print(string.format("[StateResolver] Applying '%s'", eventName))

	if payload.statChanges then
		for stat, amount in pairs(payload.statChanges) do
			print(string.format("[StateResolver]   UpdateStat(%s, %s)", stat, tostring(amount)))
			PlayerDataManager.UpdateStat(stat, amount)
		end
	end

	if payload.communityChanges then
		for community, amount in pairs(payload.communityChanges) do
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

	print(string.format("[StateResolver] Finished applying '%s'", eventName))
end

-- ─────────────────────────────────────────────────────────────────────────────
function StateResolver.Init()
	print("[StateResolver] Initializing...")

	-- ── Legacy generic stat patch ──────────────────────────────────────────
	EventBus.Subscribe("STAT_CHANGE_REQUESTED", function(payload)
		print(string.format("[StateResolver] Received STAT_CHANGE_REQUESTED: %s %s",
			payload.Stat, tostring(payload.Amount)))
		PlayerDataManager.UpdateStat(payload.Stat, payload.Amount)
	end)

	-- ── SongSystem event ──────────────────────────────────────────────────
	EventBus.Subscribe("SONG_RELEASED", function(payload)
		print("[StateResolver] Applying SONG_RELEASED...")
		PlayerDataManager.UpdateStat("Money",     payload.MoneyGained     or 0)
		PlayerDataManager.UpdateStat("Fame",      payload.FameGained      or 0)
		PlayerDataManager.UpdateStat("Followers", payload.FollowersGained or 0)
		PlayerDataManager.UpdateStat("Reputation",payload.RepChange       or 0)
		PlayerDataManager.UpdateStat("Stress",    payload.StressChange    or 0)

		if payload.CommunityChanges then
			for community, amount in pairs(payload.CommunityChanges) do
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
		print("[StateResolver] Finished applying SONG_RELEASED.")
	end)

	-- ── ArtistSystem events (all use generic applyPayload) ────────────────
	local ARTIST_EVENTS = {
		"ARTIST_SIGNED",
		"ARTIST_TALKED",
		"ARTIST_BONUS_PAID",
		"ARTIST_RESTED",
		"ARTIST_RECORDED",
		"ARTIST_DROPPED",
		"ARTIST_EVENT_TRIGGERED",
	}

	for _, eventName in pairs(ARTIST_EVENTS) do
		local name = eventName -- capture for closure
		EventBus.Subscribe(name, function(payload)
			applyPayload(name, payload)
		end)
	end

	print("[StateResolver] All event listeners registered.")
end

return StateResolver
