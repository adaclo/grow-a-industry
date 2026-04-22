local ArtistSystem = {
    COOLDOWNS = {
        Talk = 30,
        RecordSong = 120,
        SocialMedia = 60,
        GiveBonus = 180,
        Rest = 300,
        BetterContract = 600
    }
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = script.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))
local ArtistGenerator = require(SharedModules:WaitForChild("ArtistGenerator"))

function ArtistSystem.CheckCooldown(artist, actionId)
    if not artist.Cooldowns then return true end
    local endTime = artist.Cooldowns[actionId] or 0
    return tick() >= endTime
end

function ArtistSystem.SetCooldown(artistId, actionId, duration)
    local state = PlayerDataManager.GetState()
    for _, artist in pairs(state.Artists) do
        if artist.Id == artistId then
            artist.Cooldowns[actionId] = tick() + duration
            PlayerDataManager.UpdateArtist(artistId, {Cooldowns = artist.Cooldowns})
            return
        end
    end
end

function ArtistSystem.PerformAction(actionId, targetId)
    local state = PlayerDataManager.GetState()
    local myStats = {
        Fame = state.Stats.Fame,
        Followers = state.Stats.Followers,
        Reputation = state.Stats.Reputation,
        Money = state.Stats.Money,
        StudioLevel = PlayerDataManager.CalculateStudioLevel()
    }
    
    local results = {
        Success = true,
        Title = "Artist Action",
        Outcome = "Neutral",
        Description = "Nothing happened.",
        ResultType = "Neutral"
    }

    local roll = math.random(1, 100)
    local roster = state.Artists

    -- Slot Check for Signings
    if actionId:find("Sign") or actionId == "DMFamous" then
        local maxSlots = myStats.StudioLevel
        if #roster >= maxSlots then
            return {
                Success = false, 
                Error = string.format("STUDIO FULL! Level %d supports %d artists. Upgrade your studio!", myStats.StudioLevel, maxSlots)
            }
        end
    end

    if actionId == "DMFamous" then
        results.Title = "DM Famous Artist"
        local successChance = 10 + (myStats.Fame / 2) + (myStats.StudioLevel * 5)
        if roll < successChance then
            local artist = ArtistGenerator.Generate("Mainstream")
            results.Outcome = "Replied!"
            results.Description = string.format("%s replied to your DM! They are interested in a contract.", artist.Name)
            results.ResultType = "Positive"
            PlayerDataManager.AddArtist(artist)
        else
            results.Outcome = "Left on Read"
            results.Description = "The artist didn't reply. Your studio might be too small or your fame too low."
            results.ResultType = "Negative"
        end

    elseif actionId == "SignUnderground" then
        results.Title = "Sign Underground Artist"
        local successChance = 75 + (myStats.Reputation / 2)
        -- Underground artists reject very mainstream players (Perception > 80)
        if state.Perception > 80 then successChance -= 30 end
        
        if roll < successChance then
            local artist = ArtistGenerator.Generate("Underground")
            results.Outcome = "Success"
            results.Description = string.format("You signed %s! They're ready to grind.", artist.Name)
            results.ResultType = "Positive"
            PlayerDataManager.AddArtist(artist)
            PlayerDataManager.UpdateCommunity("UndergroundAudience", 150)
            PlayerDataManager.UpdatePerception(-5)
        else
            results.Outcome = "Rejection"
            results.Description = "The artist decided to stay independent. They don't feel your label's vibe."
            results.ResultType = "Negative"
        end

    elseif actionId == "SignMainstream" then
        results.Title = "Sign Mainstream Artist"
        -- Requirements Check
        if myStats.StudioLevel < 2 or myStats.Fame < 15 or myStats.Followers < 500 then
            return {Success = false, Error = "REQUIREMENTS NOT MET! Need Studio Lvl 2, 15 Fame, and 500 Followers."}
        end
        
        local successChance = 45 + (myStats.Followers / 5000)
        if roll < successChance then
            local artist = ArtistGenerator.Generate("Mainstream")
            results.Outcome = "Contract Signed"
            results.Description = string.format("Massive win! %s has joined your label.", artist.Name)
            results.ResultType = "Positive"
            PlayerDataManager.AddArtist(artist)
            PlayerDataManager.UpdatePerception(5)
        else
            results.Outcome = "Negotiation Failed"
            results.Description = "The artist's manager asked for too much. Negotiation stalled."
            results.ResultType = "Negative"
        end

    elseif actionId == "GiveBonus" then
        results.Title = "Financial Bonus"
        local cost = 1000
        if myStats.Money < cost then return {Success = false, Error = "NOT ENOUGH MONEY!"} end
        
        local artist = nil
        for _, a in pairs(roster) do if a.Id == targetId then artist = a break end end
        if not artist then return {Success = false, Error = "Artist not found!"} end
        
        PlayerDataManager.UpdateStat("Money", -cost)
        artist.Loyalty = math.clamp(artist.Loyalty + 15, 0, 100)
        artist.Ego = math.clamp(artist.Ego + 5, 0, 100)
        artist.Mood = "Happy"
        
        PlayerDataManager.UpdateArtist(targetId, {Loyalty = artist.Loyalty, Ego = artist.Ego, Mood = artist.Mood})
        ArtistSystem.SetCooldown(targetId, "GiveBonus", ArtistSystem.COOLDOWNS.GiveBonus)
        
        results.Outcome = "Happy Artist"
        results.Description = string.format("You gave %s a $1,000 bonus. They are more loyal but their ego grew.", artist.Name)
        results.ResultType = "Positive"

    elseif actionId == "TalkToArtist" then
        results.Title = "One-on-One Talk"
        local artist = nil
        for _, a in pairs(roster) do if a.Id == targetId then artist = a break end end
        if not artist then return {Success = false, Error = "Artist not found!"} end
        
        if not ArtistSystem.CheckCooldown(artist, "Talk") then return {Success = false, Error = "Artist is busy!"} end
        
        artist.Loyalty = math.clamp(artist.Loyalty + 5, 0, 100)
        artist.Ego = math.clamp(artist.Ego - 5, 0, 100)
        artist.Stress = math.clamp(artist.Stress - 10, 0, 100)
        artist.Mood = "Motivated"
        
        PlayerDataManager.UpdateArtist(targetId, {Loyalty = artist.Loyalty, Ego = artist.Ego, Stress = artist.Stress, Mood = artist.Mood})
        ArtistSystem.SetCooldown(targetId, "Talk", ArtistSystem.COOLDOWNS.Talk)
        
        results.Outcome = "Productive Talk"
        results.Description = string.format("You talked with %s. They feel heard and less stressed.", artist.Name)
        results.ResultType = "Positive"

    elseif actionId == "RecordSong" then
        results.Title = "Recording Session"
        local artist = nil
        for _, a in pairs(roster) do if a.Id == targetId then artist = a break end end
        if not artist then return {Success = false, Error = "Artist not found!"} end
        if artist.IsPending then return {Success = false, Error = "Artist is still getting settled!"} end
        if not ArtistSystem.CheckCooldown(artist, "RecordSong") then return {Success = false, Error = "Studio is busy!"} end

        artist.Stress = math.clamp(artist.Stress + 20, 0, 100)
        local quality = (artist.Talent * 0.7) + (math.random(1, 30))
        
        if quality > 90 then
            results.Outcome = "CHART TOPPER"
            results.Description = string.format("%s recorded a HIT! Fame and money are pouring in.", artist.Name)
            PlayerDataManager.UpdateStat("Money", 5000)
            PlayerDataManager.UpdateStat("Fame", 10)
        elseif quality < 30 then
            results.Outcome = "FLOP"
            results.Description = string.format("The song failed to gain traction. %s feels discouraged.", artist.Name)
            artist.Mood = "Burned Out"
        else
            results.Outcome = "Solid Release"
            results.Description = string.format("%s released a decent song. Good for the brand.", artist.Name)
            PlayerDataManager.UpdateStat("Money", 1000)
        end
        
        PlayerDataManager.UpdateArtist(targetId, {Stress = artist.Stress, Mood = artist.Mood})
        ArtistSystem.SetCooldown(targetId, "RecordSong", ArtistSystem.COOLDOWNS.RecordSong)

    elseif actionId == "RestArtist" then
        results.Title = "Rest & Recovery"
        local artist = nil
        for _, a in pairs(roster) do if a.Id == targetId then artist = a break end end
        if not artist then return {Success = false, Error = "Artist not found!"} end

        artist.Stress = 0
        artist.Mood = "Neutral"
        PlayerDataManager.UpdateArtist(targetId, {Stress = 0, Mood = "Neutral"})
        ArtistSystem.SetCooldown(targetId, "Rest", ArtistSystem.COOLDOWNS.Rest)
        
        results.Outcome = "Reset"
        results.Description = string.format("%s is taking a break. They will be back refreshed.", artist.Name)
        results.ResultType = "Positive"

    elseif actionId == "DropArtist" then
        results.Title = "Drop Artist"
        local artist = nil
        for _, a in pairs(roster) do if a.Id == targetId then artist = a break end end
        if not artist then return {Success = false, Error = "Artist not found!"} end
        
        if roll < 20 then
            results.Outcome = "Ugly Breakup"
            results.Description = string.format("%s is furious! They leaked a demo before leaving.", artist.Name)
            PlayerDataManager.UpdateStat("Reputation", -10)
        else
            results.Outcome = "Contract Terminated"
            results.Description = string.format("You parted ways with %s.", artist.Name)
        end
        PlayerDataManager.RemoveArtist(targetId)
    end

    return results
end

function ArtistSystem.Tick()
    local state = PlayerDataManager.GetState()
    local currentTime = tick()
    local changed = false
    
    for _, artist in pairs(state.Artists) do
        if artist.IsPending and currentTime >= (artist.PendingTime or 0) then
            artist.IsPending = false
            changed = true
        end
    end
    
    if changed then
        local clone = {}
        for k,v in pairs(state.Artists) do clone[k] = v end
        PlayerDataManager.UpdateArtist(nil, {}) -- Trigger UI refresh
    end
end

function ArtistSystem.GetActionState(actionId, artistId)
    local state = PlayerDataManager.GetState()
    local myStats = {
        Fame = state.Stats.Fame,
        Followers = state.Stats.Followers,
        Reputation = state.Stats.Reputation,
        StudioLevel = state.StudioLevel or 1
    }
    
    -- Global Actions
    if actionId == "SignMainstream" then
        if myStats.StudioLevel < 2 then return "LOCKED", "Studio Lvl 2+" end
        if myStats.Fame < 15 then return "LOCKED", "Fame 15+" end
        if myStats.Followers < 500 then return "LOCKED", "500+ Followers" end
        if #state.Artists >= myStats.StudioLevel then return "FULL", "Upgrade Studio" end
        return "READY"
    end
    
    if actionId == "SignUnderground" or actionId == "DMFamous" then
        if #state.Artists >= myStats.StudioLevel then return "FULL", "Upgrade Studio" end
        return "READY"
    end

    -- Artist Specific Actions
    if artistId then
        local artist = nil
        for _, a in pairs(state.Artists) do if a.Id == artistId then artist = a break end end
        if not artist then return "ERROR" end
        
        if artist.IsPending then return "PENDING", math.ceil(math.max(0, artist.PendingTime - tick())) .. "s" end
        
        local endTime = artist.Cooldowns[actionId] or 0
        if tick() < endTime then
            return "COOLDOWN", math.ceil(endTime - tick()) .. "s"
        end
        
        return "READY"
    end
    
    return "READY"
end

return ArtistSystem
