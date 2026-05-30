-- PressureSystem.luau
-- Passive simulation pressure: rent, hype decay, and (later) idle artist stress + trend advance.
-- All intervals and values are configurable via PressureSystem.Config.
-- Runs client-side via RunService.Heartbeat (single-player simulation only).

local RunService        = game:GetService("RunService")
local SharedModules     = script.Parent.Parent
local Config            = require(SharedModules:WaitForChild("Config"))
local EventBus          = require(script.Parent:WaitForChild("EventBus"))
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))
local ReactiveEventEngine = require(script.Parent:WaitForChild("ReactiveEventEngine"))
local MemoryEvaluator   = require(script.Parent:WaitForChild("MemoryEvaluator"))

local PressureSystem = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Config — all values tunable, no magic numbers elsewhere in this file
-- ─────────────────────────────────────────────────────────────────────────────
PressureSystem.Config = {
	Enabled = true,
	TestMode = Config.Debug.TestMode,  -- read from shared Config

	-- Intervals (seconds)
	RentInterval         = Config.Debug.RentInterval,   -- read from shared Config
	HypeDecayInterval    = Config.Debug.HypeDecayInterval,   -- read from shared Config
	IdleArtistInterval   = 60,   -- idle artist stress
	RelevanceDecayInterval = 120, -- relevance/fame decay
	
	-- Reactive events / Memory
	PassiveEventIntervalTest = Config.Debug.PassiveEventIntervalTest,
	PassiveEventIntervalNorm = Config.Debug.PassiveEventInterval,

	-- Rent
	RentBase           = 50,    -- base rent per tick
	RentPerStudioLevel = 25,    -- additional rent per studio level

	-- Hype decay
	HypeDecayPercent   = 0.10,  -- fraction of current Hype that decays each tick
	HypeDecayMin       = 1,     -- minimum decay when Hype > 0 (avoids float stalls)

	-- Idle artist (reserved for Phase 3 activation)
	IdleArtistStress   = 3,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal timer accumulators
-- ─────────────────────────────────────────────────────────────────────────────
local timers = {
	rent         = 0,
	hypeDecay    = 0,
	passiveEvent = 0,
	idle         = 0,
    relevance    = 0,
}

-- ─────────────────────────────────────────────────────────────────────────────
function PressureSystem.Init(trendSystemRef)
	-- Automatically sync config if TestMode changed
	PressureSystem.Config.TestMode = Config.Debug.TestMode
	PressureSystem.Config.RentInterval = Config.Debug.RentInterval
	PressureSystem.Config.HypeDecayInterval = Config.Debug.HypeDecayInterval
	PressureSystem.Config.PassiveEventIntervalTest = Config.Debug.PassiveEventIntervalTest
	PressureSystem.Config.PassiveEventIntervalNorm = Config.Debug.PassiveEventInterval

	local cfg = PressureSystem.Config
	if not cfg.Enabled then
		print("[PressureSystem] Disabled — no ticks will run.")
		return
	end

	-- Optional reference to TrendSystem for future trend advancement
	PressureSystem._trendSystem = trendSystemRef

	print(string.format(
		"[PressureSystem] Initialized | TestMode=%s | RentInterval=%ds | HypeDecayInterval=%ds",
		tostring(cfg.TestMode), cfg.RentInterval, cfg.HypeDecayInterval))

	RunService.Heartbeat:Connect(function(dt)
		PressureSystem._Tick(dt)
	end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal tick — called every frame via Heartbeat
-- ─────────────────────────────────────────────────────────────────────────────
function PressureSystem._Tick(dt)
	local cfg = PressureSystem.Config
	if not cfg.Enabled then return end

	timers.rent         = timers.rent         + dt
	timers.hypeDecay    = timers.hypeDecay    + dt
	timers.passiveEvent = timers.passiveEvent + dt
    timers.idle         = timers.idle         + dt
    timers.relevance    = timers.relevance    + dt

	-- ── Rent ──────────────────────────────────────────────────────────────
	if timers.rent >= cfg.RentInterval then
		timers.rent = 0
		local studioLevel = PlayerDataManager.CalculateStudioLevel()
		local rent = cfg.RentBase + (studioLevel * cfg.RentPerStudioLevel)
		print(string.format("[PressureSystem] Rent due: -$%d (Studio Lvl %d)", rent, studioLevel))
		EventBus.Emit("STAT_CHANGE_REQUESTED", {Stat = "Money", Amount = -rent})
		EventBus.Emit("READABILITY_NOTIFICATION", {Text = string.format("💸 Rent paid: -$%d", rent), Type = "Negative"})
	end

	-- ── Hype Decay ────────────────────────────────────────────────────────
	if timers.hypeDecay >= cfg.HypeDecayInterval then
		timers.hypeDecay = 0
		local currentHype = PlayerDataManager.GetStat("Hype")
		if currentHype > 0 then
			local decay = math.max(cfg.HypeDecayMin, math.floor(currentHype * cfg.HypeDecayPercent))
			print(string.format("[PressureSystem] Hype decay: -%d (was %d)", decay, currentHype))
			EventBus.Emit("STAT_CHANGE_REQUESTED", {Stat = "Hype", Amount = -decay})
			EventBus.Emit("READABILITY_NOTIFICATION", {Text = string.format("📉 Hype fading: -%d", decay), Type = "Negative"})
		end
	end

	-- ── Passive Events & Memory Decay ─────────────────────────────────────
	local passiveInterval = cfg.TestMode and cfg.PassiveEventIntervalTest or cfg.PassiveEventIntervalNorm
	if timers.passiveEvent >= passiveInterval then
		timers.passiveEvent = 0
		print("[PressureSystem] Running passive event polling & memory decay...")
		MemoryEvaluator.DecayFlags()
		ReactiveEventEngine.Evaluate({Action = "PASSIVE_TICK"})
	end

	-- ── Idle Artist Stress & Trait Pass ──────────────────────────────────
	if timers.idle >= cfg.IdleArtistInterval then
        timers.idle = 0
        local state = PlayerDataManager.GetState()
        local ArtistSystem = require(SharedModules:WaitForChild("ArtistSystem")) -- deferred require
        
        for _, artist in pairs(state.Artists) do
            local isCloutChaser = ArtistSystem.HasTrait(artist, "CloutChaser")
            local stressInc = isCloutChaser and 2 or 1
            
            local newStress = math.clamp((artist.Stress or 0) + stressInc, 0, 100)
            
            -- CloutChasers also gain resentment if ignored
            if isCloutChaser then
                artist.Resentment = math.clamp((artist.Resentment or 0) + 1, 0, 100)
            end
            
            PlayerDataManager.UpdateArtist(artist.Id, {Stress = newStress, Resentment = artist.Resentment})
        end
        print("[PressureSystem] IdleArtistStress applied to roster.")
    end

	-- ── Relevance Decay ──────────────────────────────────────────────────
	if timers.relevance >= cfg.RelevanceDecayInterval then
        timers.relevance = 0
        local state = PlayerDataManager.GetState()
        if state.Stats.Fame > 10 then
            -- Small slow decay to represent shifting attention
            EventBus.Emit("STAT_CHANGE_REQUESTED", {Stat = "Fame", Amount = -1})
            print("[PressureSystem] Relevance decayed (Fame -1)")
        end
    end

    -- Trigger PASSIVE_TICK for RosterSystem
    if timers.passiveEvent == 0 then -- Just fired
        EventBus.Emit("PASSIVE_TICK", {})
    end
end

return PressureSystem
