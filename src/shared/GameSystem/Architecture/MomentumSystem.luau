-- MomentumSystem.luau
-- Reads PlayerDataManager.Momentum and re-registers modifiers into ModifierSystem
-- Called by StateResolver after every SONG_RELEASED event.

local SharedModules    = script.Parent.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))
local ModifierSystem    = require(script.Parent:WaitForChild("ModifierSystem"))

local MomentumSystem = {}

-- Source ID prefixes (used for Clear/Register pairs)
local SRC = {
	HIT_CHANCE   = "momentum_hit_chance",
	HIT_REVENUE  = "momentum_hit_revenue",
	FLOP_NEG     = "momentum_flop_neg",
	FLOP_REVENUE = "momentum_flop_revenue",
	MEM_VIRAL    = "memory_viral",
	MEM_BEEF     = "memory_beef",
	MEM_FLOPPED  = "memory_flopped",
}

-- Thresholds (keep small to avoid frustration)
local HIT_HITCHANCE_PER  = 5   -- HitChance Add per consecutive hit
local HIT_HITCHANCE_MAX  = 20
local HIT_REVENUE_PER    = 0.1  -- SongRevenue Multiply per hit
local HIT_REVENUE_MAX    = 0.4
local FLOP_NEG_PER       = 8   -- NegativeChance Add per flop
local FLOP_NEG_MAX       = 32
local FLOP_REVENUE_PER   = 0.1  -- SongRevenue Multiply penalty
local FLOP_REVENUE_MAX   = 0.3

-- Called by StateResolver after SONG_RELEASED is applied
-- outcomeType: "Hit" | "Flop" | "Neutral"  (determined from payload)
function MomentumSystem.OnSongReleased(payload)
	local outcome = payload.Outcome or ""
	local outcomeType = "Neutral"

	if outcome == "Hit Song" or outcome == "Viral Song" or outcome == "Cult Classic" then
		outcomeType = "Hit"
	elseif payload.ResultType == "Negative" then
		outcomeType = "Flop"
	end

	print(string.format("[MomentumSystem] Song outcome: '%s' → classified as '%s'", outcome, outcomeType))
	PlayerDataManager.UpdateMomentum(outcomeType)
	MomentumSystem.RefreshMomentumModifiers()
end

-- Re-registers momentum modifiers based on current streak state
function MomentumSystem.RefreshMomentumModifiers()
	-- Clear all momentum modifiers first
	for _, src in pairs({SRC.HIT_CHANCE, SRC.HIT_REVENUE, SRC.FLOP_NEG, SRC.FLOP_REVENUE}) do
		ModifierSystem.Clear(src)
	end

	local m = PlayerDataManager.GetMomentum()

	-- Hit streak bonuses
	if m.ConsecHits >= 2 then
		local bonus = math.min(m.ConsecHits * HIT_HITCHANCE_PER, HIT_HITCHANCE_MAX)
		ModifierSystem.Register("HitChance", SRC.HIT_CHANCE, bonus, "Add")
		print(string.format("[MomentumSystem] Hit streak x%d → HitChance +%d", m.ConsecHits, bonus))
	end
	if m.ConsecHits >= 3 then
		local bonus = math.min(m.ConsecHits * HIT_REVENUE_PER, HIT_REVENUE_MAX)
		ModifierSystem.Register("SongRevenue", SRC.HIT_REVENUE, bonus, "Multiply")
		print(string.format("[MomentumSystem] Hit streak x%d → SongRevenue *+%.2f", m.ConsecHits, bonus))
	end

	-- Flop streak penalties
	if m.ConsecFlops >= 2 then
		local penalty = math.min(m.ConsecFlops * FLOP_NEG_PER, FLOP_NEG_MAX)
		ModifierSystem.Register("NegativeChance", SRC.FLOP_NEG, penalty, "Add")
		print(string.format("[MomentumSystem] Flop streak x%d → NegativeChance +%d", m.ConsecFlops, penalty))
	end
	if m.ConsecFlops >= 3 then
		local penalty = -math.min(m.ConsecFlops * FLOP_REVENUE_PER, FLOP_REVENUE_MAX)
		ModifierSystem.Register("SongRevenue", SRC.FLOP_REVENUE, penalty, "Multiply")
		print(string.format("[MomentumSystem] Flop streak x%d → SongRevenue *%.2f", m.ConsecFlops, penalty))
	end
end

-- Re-registers memory-based modifiers (call after any flag changes)
function MomentumSystem.RefreshMemoryModifiers()
	ModifierSystem.Clear(SRC.MEM_VIRAL)
	ModifierSystem.Clear(SRC.MEM_BEEF)
	ModifierSystem.Clear(SRC.MEM_FLOPPED)

	if PlayerDataManager.GetMemoryFlag("had_viral") then
		ModifierSystem.Register("ViralChance", SRC.MEM_VIRAL, 3, "Add")
		print("[MomentumSystem] Memory 'had_viral' active → ViralChance +3")
	end

	if PlayerDataManager.GetMemoryFlag("industry_beef") then
		ModifierSystem.Register("ArtistAttraction", SRC.MEM_BEEF, -0.15, "Multiply")
		print("[MomentumSystem] Memory 'industry_beef' active → ArtistAttraction -0.15")
	end

	local flopped = PlayerDataManager.GetMemoryFlag("times_flopped") or 0
	if flopped >= 3 then
		ModifierSystem.Register("NegativeChance", SRC.MEM_FLOPPED, 5, "Add")
		print(string.format("[MomentumSystem] Memory 'times_flopped'=%d → NegativeChance +5", flopped))
	end
end

function MomentumSystem.Init()
	print("[MomentumSystem] Initialized.")
	-- Restore any modifiers from existing state (relevant once persistence is added)
	MomentumSystem.RefreshMomentumModifiers()
	MomentumSystem.RefreshMemoryModifiers()
end

return MomentumSystem
