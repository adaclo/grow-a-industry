local PlayerDataManager = {}

local state = {
    Stats = {
        Money = 750,
        Fame = 0,
        Followers = 100,
        Reputation = 50,
        Stress = 10,
        Hype = 0,
        Style = "Underground", -- Initial Style
        RosterTension = 0, -- 0-100 Tension metric
        LabelIdentity = "Starting Out"
    },
    Levels = {
        Computer = 1,
        Microphone = 1,
        Speakers = 1,
        DecoUpgrades = 1
    },
    Communities = {
        MainstreamAudience = 100,
        UndergroundAudience = 20,
        LoyalFans = 5,
        Haters = 0,
        CasualListeners = 50
    },
    Genres = {
        Pop = 0,
        Trap = 0,
        Electronic = 0,
        Indie = 0,
        Hyperpop = 0,
        Rock = 0
    },
    Perception = 50, -- 0 = Pure Underground, 100 = Pure Mainstream
    StudioLevel = 1,
    Artists = {},
    History = {},
    ActiveChains = {},
    Controversies = {},

    -- Simulation depth fields
    Memory = {},  -- label-level flags: { [key] = value }
    Momentum = {
        Streak     = 0,
        StreakType = nil,
        ConsecHits  = 0,
        ConsecFlops = 0,
        LastOutcome = nil,
    },
    Trends = {
        Pop        = {Phase = "Rising",    Ticks = 0},
        Trap       = {Phase = "Peak",      Ticks = 0},
        Electronic = {Phase = "Declining", Ticks = 0},
        Indie      = {Phase = "Rising",    Ticks = 0},
        Hyperpop   = {Phase = "Dead",      Ticks = 0},
        Rock       = {Phase = "Declining", Ticks = 0},
    },
}

-- BindableEvent to let UI know when stats change
local StateChanged = Instance.new("BindableEvent")
PlayerDataManager.StateChanged = StateChanged.Event

function PlayerDataManager.GetState()
    return state
end

function PlayerDataManager.GetStat(statName: string)
    return state.Stats[statName] or 0
end

function PlayerDataManager.UpdateStat(statName: string, amount: number)
    if state.Stats[statName] then
        state.Stats[statName] += amount
        -- Clamping logical minimums (e.g. stress can't be negative, rep max is 100 or 1000)
        if state.Stats[statName] < 0 then
            state.Stats[statName] = 0
        end
        StateChanged:Fire(statName, state.Stats[statName])
    else
        warn("PlayerDataManager: Attempted to update invalid stat ->", statName)
    end
end

function PlayerDataManager.UpdateLevel(upgradeId: string, level: number)
    if state.Levels[upgradeId] then
        state.Levels[upgradeId] = level
        StateChanged:Fire("Level_" .. upgradeId, level)
    else
        warn("PlayerDataManager: Attempted to update invalid upgrade ->", upgradeId)
    end
end

function PlayerDataManager.UpdateCommunity(name: string, amount: number)
    if state.Communities[name] then
        state.Communities[name] = math.max(0, state.Communities[name] + amount)
        StateChanged:Fire("Community_" .. name, state.Communities[name])
    end
end

function PlayerDataManager.UpdateGenre(name: string, amount: number)
    if state.Genres[name] then
        state.Genres[name] += amount
        StateChanged:Fire("Genre_" .. name, state.Genres[name])
    end
end

function PlayerDataManager.UpdatePerception(amount: number)
    state.Perception = math.clamp(state.Perception + amount, 0, 100)
    StateChanged:Fire("Perception", state.Perception)
end

function PlayerDataManager.UpdateRosterTension(amount: number)
    if state.Stats.RosterTension then
        state.Stats.RosterTension = math.clamp(state.Stats.RosterTension + amount, 0, 100)
        StateChanged:Fire("RosterTension", state.Stats.RosterTension)
    end
end

function PlayerDataManager.UpdateLabelIdentity(newIdentity: string)
    if state.Stats.LabelIdentity ~= newIdentity then
        state.Stats.LabelIdentity = newIdentity
        StateChanged:Fire("LabelIdentity", newIdentity)
    end
end

-- ── Narrative Chains ────────────────────────────────────────────────────────
function PlayerDataManager.AddNarrativeChain(chainId: string, data)
    state.ActiveChains[chainId] = data
    StateChanged:Fire("ActiveChains", state.ActiveChains)
end

function PlayerDataManager.UpdateNarrativeChain(chainId: string, data)
    if state.ActiveChains[chainId] then
        for k, v in pairs(data) do
            state.ActiveChains[chainId][k] = v
        end
        StateChanged:Fire("ActiveChains", state.ActiveChains)
    end
end

function PlayerDataManager.RemoveNarrativeChain(chainId: string)
    if state.ActiveChains[chainId] then
        state.ActiveChains[chainId] = nil
        StateChanged:Fire("ActiveChains", state.ActiveChains)
    end
end

-- ── Controversies ───────────────────────────────────────────────────────────
function PlayerDataManager.AddControversy(controversyData)
    state.Controversies[controversyData.Id] = controversyData
    StateChanged:Fire("Controversies", state.Controversies)
end

function PlayerDataManager.UpdateControversy(id: string, data)
    if state.Controversies[id] then
        for k, v in pairs(data) do
            state.Controversies[id][k] = v
        end
        StateChanged:Fire("Controversies", state.Controversies)
    end
end

function PlayerDataManager.RemoveControversy(id: string)
    if state.Controversies[id] then
        state.Controversies[id] = nil
        StateChanged:Fire("Controversies", state.Controversies)
    end
end

function PlayerDataManager.GetControversy(id: string)
    return state.Controversies[id]
end

function PlayerDataManager.AddArtist(artistData)
    table.insert(state.Artists, artistData)
    local clone = {}
    for k,v in pairs(state.Artists) do clone[k] = v end
    StateChanged:Fire("Artists", clone)
end

function PlayerDataManager.RemoveArtist(artistId)
    for i, artist in pairs(state.Artists) do
        if artist.Id == artistId then
            table.remove(state.Artists, i)
            local clone = {}
            for k,v in pairs(state.Artists) do clone[k] = v end
            StateChanged:Fire("Artists", clone)
            return true
        end
    end
    return false
end

function PlayerDataManager.CalculateStudioLevel()
    local levels = state.Levels
    local points = 0
    
    local keys = {"Computer", "Microphone", "Speakers", "DecoUpgrades"}
    for _, key in pairs(keys) do
        local lvl = levels[key] or 1
        if lvl == 2 then points += 1
        elseif lvl >= 3 then points += 2 end
    end
    
    local newLevel = 1
    if points >= 8 then newLevel = 5
    elseif points >= 6 then newLevel = 4
    elseif points >= 4 then newLevel = 3
    elseif points >= 2 then newLevel = 2 end
    
    if state.StudioLevel ~= newLevel then
        state.StudioLevel = newLevel
        StateChanged:Fire("StudioLevel", newLevel)
    end
    return newLevel
end

function PlayerDataManager.UpdateArtist(artistId, data)
    for i, artist in pairs(state.Artists) do
        if artist.Id == artistId then
            for k, v in pairs(data) do
                artist[k] = v
            end
            local clone = {}
            for k2,v2 in pairs(state.Artists) do clone[k2] = v2 end
            StateChanged:Fire("Artists", clone)
            return true
        end
    end
    return false
end

function PlayerDataManager.AddHistory(songData)
    table.insert(state.History, songData)
    StateChanged:Fire("History", state.History)
end

-- ── Memory flags ──────────────────────────────────────────────────────────────
function PlayerDataManager.SetMemoryFlag(key, value)
    state.Memory[key] = value
    local displayVal = value
    if type(value) == "table" then
        displayVal = string.format("{Value=%s, Ticks=%s}", tostring(value.Value), tostring(value.TicksRemaining or "nil"))
    end
    print(string.format("[PlayerDataManager] Memory: %s = %s", key, tostring(displayVal)))
    StateChanged:Fire("Memory_" .. key, value)
end

function PlayerDataManager.GetMemoryFlag(key)
    local val = state.Memory[key]
    if type(val) == "table" then
        return val.Value
    end
    return val
end

function PlayerDataManager.GetMemoryFlagRaw(key)
    return state.Memory[key]
end

function PlayerDataManager.GetAllMemoryFlags()
    return state.Memory
end

-- ── Momentum ──────────────────────────────────────────────────────────────────
function PlayerDataManager.UpdateMomentum(outcomeType)
    local m = state.Momentum
    m.LastOutcome = outcomeType
    if outcomeType == "Hit" then
        m.ConsecHits  = m.ConsecHits + 1
        m.ConsecFlops = 0
        m.Streak      = m.ConsecHits
        m.StreakType  = "Hit"
    elseif outcomeType == "Flop" then
        m.ConsecFlops = m.ConsecFlops + 1
        m.ConsecHits  = 0
        m.Streak      = -m.ConsecFlops
        m.StreakType  = "Flop"
    else -- Neutral breaks both streaks
        m.ConsecHits  = 0
        m.ConsecFlops = 0
        m.Streak      = 0
        m.StreakType  = nil
    end
    print(string.format("[PlayerDataManager] Momentum: %s | Hits=%d Flops=%d Streak=%d",
        outcomeType, m.ConsecHits, m.ConsecFlops, m.Streak))
    StateChanged:Fire("Momentum", m)
end

function PlayerDataManager.GetMomentum()
    return state.Momentum
end

-- ── Trends ────────────────────────────────────────────────────────────────────
local TREND_PHASE_ORDER = {"Dead", "Rising", "Peak", "Declining"}

function PlayerDataManager.AdvanceTrend(genreName)
    local trend = state.Trends[genreName]
    if not trend then return end
    local idx = 1
    for i, phase in ipairs(TREND_PHASE_ORDER) do
        if phase == trend.Phase then idx = i break end
    end
    trend.Phase = TREND_PHASE_ORDER[(idx % #TREND_PHASE_ORDER) + 1]
    trend.Ticks = trend.Ticks + 1
    StateChanged:Fire("Trend_" .. genreName, trend)
end

function PlayerDataManager.GetTrend(genreName)
    return state.Trends[genreName]
end

return PlayerDataManager
