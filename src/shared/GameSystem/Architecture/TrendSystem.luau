-- TrendSystem.luau
-- Manages genre trend phases and translates them into ModifierSystem registrations.
-- Phase cycle: Dead → Rising → Peak → Declining → Dead
-- Only the genre targeted in the current song release has its modifiers applied.

local SharedModules     = script.Parent.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))
local ModifierSystem    = require(script.Parent:WaitForChild("ModifierSystem"))

local TrendSystem = {}

local SRC_HITCHANCE = "trend_genre_hitchance"
local SRC_REVENUE   = "trend_genre_revenue"

-- Modifier values per trend phase (kept conservative)
local PHASE_MODS = {
	Rising   = {HitChance = 5,   SongRevenue = 0.05},
	Peak     = {HitChance = 12,  SongRevenue = 0.15},
	Declining = {HitChance = -5, SongRevenue = -0.05},
	Dead     = {HitChance = -15, SongRevenue = -0.15},
}

-- Apply modifiers for the genre the player just targeted.
-- Called by StateResolver after SONG_RELEASED.
function TrendSystem.ApplyGenreModifiers(genreName)
	if not genreName or genreName == "" then return end

	-- Clear previous song's genre modifiers
	ModifierSystem.Clear(SRC_HITCHANCE)
	ModifierSystem.Clear(SRC_REVENUE)

	local trend = PlayerDataManager.GetTrend(genreName)
	if not trend then
		print(string.format("[TrendSystem] Genre '%s' has no trend data — no modifiers applied", genreName))
		return
	end

	local mods = PHASE_MODS[trend.Phase]
	if not mods then return end

	ModifierSystem.Register("HitChance",   SRC_HITCHANCE, mods.HitChance,   "Add")
	ModifierSystem.Register("SongRevenue", SRC_REVENUE,   mods.SongRevenue, "Multiply")

	print(string.format("[TrendSystem] Genre '%s' @ %s → HitChance %+d, SongRevenue %+.2f",
		genreName, trend.Phase, mods.HitChance, mods.SongRevenue))
end

-- Advance one random genre's trend phase.
-- Called by PressureSystem on TrendAdvanceInterval.
function TrendSystem.AdvanceRandomTrend()
	local state  = PlayerDataManager.GetState()
	local genres = {}
	for name, _ in pairs(state.Trends) do
		table.insert(genres, name)
	end
	if #genres == 0 then return end

	local genreName = genres[math.random(#genres)]
	PlayerDataManager.AdvanceTrend(genreName)
	local newPhase = PlayerDataManager.GetTrend(genreName).Phase
	print(string.format("[TrendSystem] '%s' advanced → %s", genreName, newPhase))
end

function TrendSystem.Init()
	print("[TrendSystem] Initialized.")
	-- Print starting phases for visibility
	local state = PlayerDataManager.GetState()
	for name, trend in pairs(state.Trends) do
		print(string.format("[TrendSystem]   %s → %s", name, trend.Phase))
	end
end

return TrendSystem
