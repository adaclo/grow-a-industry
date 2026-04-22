local ArtistEvents = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = script.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local EVENTS = {
    {
        Name = "Song Leak",
        Trigger = function(artist) return artist.Risk > 50 and math.random() < 0.1 end,
        Action = function(artist)
            PlayerDataManager.UpdateStat("Hype", -20)
            PlayerDataManager.UpdateStat("Reputation", -10)
            return string.format("%s leaked an unreleased song! Your fans are hearing unfinished work.", artist.Name)
        end
    },
    {
        Name = "Viral Moment",
        Trigger = function(artist) return artist.Talent > 80 and math.random() < 0.05 end,
        Action = function(artist)
            PlayerDataManager.UpdateStat("Followers", math.random(500, 2000))
            return string.format("%s went viral on TikTok! You're gaining massive traction.", artist.Name)
        end
    },
    {
        Name = "Studio Drama",
        Trigger = function(artist) return artist.Ego > 80 and math.random() < 0.1 end,
        Action = function(artist)
            PlayerDataManager.UpdateStat("Stress", 20)
            return string.format("%s is causing a scene in the studio. Your stress level is rising.", artist.Name)
        end
    },
    {
        Name = "Artist Burnout",
        Trigger = function(artist) return artist.Loyalty < 30 and math.random() < 0.05 end,
        Action = function(artist)
            artist.Talent = math.max(0, artist.Talent - 10)
            return string.format("%s is feeling burned out. Their productivity and talent are taking a hit.", artist.Name)
        end
    },
    {
        Name = "Mainstream Push",
        Trigger = function(artist) return artist.Popularity > 70 and math.random() < 0.05 end,
        Action = function(artist)
            PlayerDataManager.UpdateStat("Money", 500)
            return string.format("%s secured a brand deal! You got a cut of the profit.", artist.Name)
        end
    }
}

function ArtistEvents.Tick()
    local state = PlayerDataManager.GetState()
    local artists = state.Artists
    
    if #artists == 0 then return nil end
    
    local artist = artists[math.random(#artists)]
    for _, event in pairs(EVENTS) do
        if event.Trigger(artist) then
            local desc = event.Action(artist)
            return {
                Title = event.Name,
                Description = desc,
                Outcome = event.Name,
                ResultType = "Neutral",
                Stats = {} -- Can be populated if needed
            }
        end
    end
    
    return nil
end

return ArtistEvents
