local PlayerDataManager = {}

local state = {
    Stats = {
        Money = 750,
        Fame = 0,
        Followers = 100,
        Reputation = 50,
        Stress = 10,
        Hype = 0,
        Style = "Underground" -- Initial Style
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
    History = {}
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

return PlayerDataManager
