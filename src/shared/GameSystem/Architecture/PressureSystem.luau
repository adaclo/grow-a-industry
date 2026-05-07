local EventBus = require(script.Parent:WaitForChild("EventBus"))

local PressureSystem = {}
local lastTick = os.time()
local RENT_INTERVAL = 300 -- 5 minutes for skeleton test

function PressureSystem.Init()
    print("[PressureSystem] Initialized skeleton.")
end

function PressureSystem.Tick()
    local currentTime = os.time()
    
    if currentTime - lastTick >= RENT_INTERVAL then
        lastTick = currentTime
        print("[PressureSystem] Rent due! (Skeleton - disabled for now)")
        -- Disabled for safety right now, but architecture is ready:
        -- EventBus.Emit("STAT_CHANGE_REQUESTED", {Stat = "Money", Amount = -100, Reason = "Rent"})
    end
end

return PressureSystem
