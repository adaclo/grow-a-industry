-- Config.luau
-- Single source of truth for all debug flags and tunable runtime values.
-- Systems should require this module instead of hardcoding test/production values.

local Config = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Debug / Test flags
-- Set TestMode = false for production pacing.
-- ─────────────────────────────────────────────────────────────────────────────
Config.Debug = {
	TestMode = true, -- true = accelerated timers for development

	-- PressureSystem intervals (seconds)
	RentInterval            = 60,  -- how often rent is charged
	HypeDecayInterval       = 45,  -- how often Hype decays
	PassiveEventInterval    = 60,  -- passive reactive event polling (production)
	PassiveEventIntervalTest = 15, -- same, test mode
}

return Config
