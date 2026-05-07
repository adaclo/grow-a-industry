local ArtistEvents = {}

local SharedModules     = script.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))
local EventBus          = require(SharedModules:WaitForChild("Architecture"):WaitForChild("EventBus"))

-- Each event defines:
--   Trigger(artist) → boolean
--   statChanges     → { StatName = delta }  (optional)
--   artistChanges   → function(artist) → { field = value }  (optional, computed at trigger time)
--   Message         → function(artist) → string

local EVENTS = {
	{
		Name    = "Song Leak",
		Trigger = function(artist) return artist.Risk > 50 and math.random() < 0.1 end,
		statChanges  = {Hype = -20, Reputation = -10},
		Message = function(artist)
			return string.format(
				"%s leaked an unreleased song! Your fans are hearing unfinished work.", artist.Name)
		end
	},
	{
		Name    = "Viral Moment",
		Trigger = function(artist) return artist.Talent > 80 and math.random() < 0.05 end,
		statChanges  = nil, -- computed dynamically below
		Message = function(artist)
			return string.format("%s went viral on TikTok! You're gaining massive traction.", artist.Name)
		end
	},
	{
		Name    = "Studio Drama",
		Trigger = function(artist) return artist.Ego > 80 and math.random() < 0.1 end,
		statChanges  = {Stress = 20},
		Message = function(artist)
			return string.format("%s is causing a scene in the studio. Your stress level is rising.", artist.Name)
		end
	},
	{
		Name    = "Artist Burnout",
		Trigger = function(artist) return artist.Loyalty < 30 and math.random() < 0.05 end,
		-- No global stat change; only the artist's Talent drops (handled via artistUpdate)
		Message = function(artist)
			return string.format(
				"%s is feeling burned out. Their productivity and talent are taking a hit.", artist.Name)
		end
	},
	{
		Name    = "Mainstream Push",
		Trigger = function(artist) return artist.Popularity > 70 and math.random() < 0.05 end,
		statChanges  = {Money = 500},
		Message = function(artist)
			return string.format("%s secured a brand deal! You got a cut of the profit.", artist.Name)
		end
	}
}

function ArtistEvents.Tick()
	local state   = PlayerDataManager.GetState()
	local artists = state.Artists

	if #artists == 0 then return nil end

	local artist = artists[math.random(#artists)]

	for _, event in pairs(EVENTS) do
		if event.Trigger(artist) then
			local desc = event.Message(artist)

			-- Build payload
			local payload = {
				eventName   = event.Name,
				statChanges = event.statChanges or {},
			}

			-- Dynamic cases
			if event.Name == "Viral Moment" then
				local gain = math.random(500, 2000)
				payload.statChanges = {Followers = gain}
			elseif event.Name == "Artist Burnout" then
				-- Artist Talent drops — routed as an artistUpdate
				local newTalent = math.max(0, (artist.Talent or 50) - 10)
				payload.artistId     = artist.Id
				payload.artistUpdate = {Talent = newTalent}
			end

			print("[ArtistEvents] Emitting ARTIST_EVENT_TRIGGERED:", event.Name)
			EventBus.Emit("ARTIST_EVENT_TRIGGERED", payload)

			return {
				Title       = event.Name,
				Description = desc,
				Outcome     = event.Name,
				ResultType  = "Neutral",
				Stats       = {}
			}
		end
	end

	return nil
end

return ArtistEvents
