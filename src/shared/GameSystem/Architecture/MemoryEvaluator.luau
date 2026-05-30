-- MemoryEvaluator.luau
-- Evaluates game history and actions to set or decay Memory Flags.
-- Triggered by StateResolver after meaningful state changes.

local SharedModules = script.Parent.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local MemoryEvaluator = {}

-- Helper to check if the last N songs match a condition
local function getLastSongs(n)
    local history = PlayerDataManager.GetState().History or {}
    local result = {}
    local len = #history
    for i = 1, math.min(n, len) do
        table.insert(result, history[len - i + 1])
    end
    return result
end

function MemoryEvaluator.EvaluateSongRelease(payload)
    print("[MemoryEvaluator] Evaluating SONG_RELEASED consequences...")
    local state = PlayerDataManager.GetState()

    -- 1. viral_pressure
    if (payload.FollowersGained or 0) > 2000 then
        PlayerDataManager.SetMemoryFlag("viral_pressure", {
            Value = true,
            TicksRemaining = 15, -- Decays after 15 ticks of PressureSystem
            Severity = 1,
            Source = "SongRelease"
        })
        -- Ensure permanent flag exists as well
        PlayerDataManager.SetMemoryFlag("had_viral", { Value = true })
    end

    -- 2. first_hit
    if not PlayerDataManager.GetMemoryFlag("first_hit") and (payload.ResultType == "Positive" or payload.Outcome == "Hit Song") then
        PlayerDataManager.SetMemoryFlag("first_hit", { Value = true })
    end

    -- 3. sellout_arc
    -- Condition: Perception > 80 (Mainstream) and last 3 songs were mainstream genres (Pop/Trap)
    if state.Perception >= 80 then
        local last3 = getLastSongs(3)
        if #last3 >= 3 then
            local allMainstream = true
            for _, song in ipairs(last3) do
                if song.Genre ~= "Pop" and song.Genre ~= "Trap" then
                    allMainstream = false
                    break
                end
            end
            if allMainstream then
                PlayerDataManager.SetMemoryFlag("sellout_arc", {
                    Value = true,
                    TicksRemaining = 30, -- Long decay
                    Severity = 1
                })
            end
        end
    end

    -- 4. underground_roots
    -- Condition: Perception < 20 and first 3 songs were experimental/indie
    if state.Perception <= 20 and not PlayerDataManager.GetMemoryFlag("underground_roots") then
        local history = state.History
        if #history >= 3 then
            local allUnderground = true
            for i = 1, 3 do
                local g = history[i].Genre
                if g == "Pop" or g == "Trap" then allUnderground = false end
            end
            if allUnderground then
                PlayerDataManager.SetMemoryFlag("underground_roots", { Value = true })
            end
        end
    end
end

function MemoryEvaluator.EvaluateArtistDropped(payload)
    print("[MemoryEvaluator] Evaluating ARTIST_DROPPED consequences...")
    if payload.outcome == "Ugly Breakup" then
        PlayerDataManager.SetMemoryFlag("industry_beef", {
            Value = true,
            Severity = 2,
            Source = "ArtistDropped"
        })
        PlayerDataManager.SetMemoryFlag("heated_beef", {
            Value = true,
            TicksRemaining = 20,
            Severity = 2
        })
    end
end
 
function MemoryEvaluator.EvaluateSocialAction(payload)
    print("[MemoryEvaluator] Evaluating SOCIAL_ACTION_PERFORMED consequences...")
    if payload.actionId == "Twitter" and payload.outcome == "Cancelled?" then
        PlayerDataManager.SetMemoryFlag("industry_beef", {
            Value = true,
            Severity = 1,
            Source = "TwitterBeef"
        })
        PlayerDataManager.SetMemoryFlag("heated_beef", {
            Value = true,
            TicksRemaining = 15,
            Severity = 1
        })
    end
end

function MemoryEvaluator.DecayFlags()
    -- Called by PressureSystem every X seconds
    local memory = PlayerDataManager.GetAllMemoryFlags()
    for key, data in pairs(memory) do
        if type(data) == "table" and data.TicksRemaining then
            data.TicksRemaining = data.TicksRemaining - 1
            if data.TicksRemaining <= 0 then
                -- Remove the flag or set Value = false
                print(string.format("[MemoryEvaluator] Flag '%s' has decayed completely.", key))
                PlayerDataManager.SetMemoryFlag(key, { Value = false, TicksRemaining = 0 })
            else
                -- Just update it
                PlayerDataManager.SetMemoryFlag(key, data)
            end
        end
    end
end

return MemoryEvaluator
