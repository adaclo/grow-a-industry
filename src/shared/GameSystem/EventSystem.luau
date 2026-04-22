local EventSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = script.Parent
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

-- Database of modular events
local EVENTS = {
    -- 1. NEGATIVE EVENTS
    {
        Id = "ConcertScam",
        Title = "CONCERT SCAM",
        Description = "A shady promoter vanished with your deposit for the upcoming tour!",
        Type = "Negative",
        Weight = 10,
        Options = {
            {
                Text = "Accept Loss",
                Effect = function()
                    PlayerDataManager.UpdateStat("Money", -500)
                    PlayerDataManager.UpdateStat("Stress", 5)
                    return "You lost $500, but kept your cool."
                end
            },
            {
                Text = "Blame Artist",
                Effect = function(artistId)
                    if artistId then
                        PlayerDataManager.UpdateArtist(artistId, {Loyalty = -10})
                        PlayerDataManager.UpdateStat("Stress", 10)
                        return "The artist is furious that you blamed them. Loyalty decreased."
                    end
                    return "No artist to blame! You just got stressed."
                end
            }
        }
    },
    {
        Id = "CopyrightStrike",
        Title = "COPYRIGHT STRIKE",
        Description = "A major label claimed your last release. It's taking down views!",
        Type = "Negative",
        Weight = 15,
        Options = {
            {
                Text = "Fight It",
                Effect = function()
                    local win = math.random() < 0.3
                    if win then
                        PlayerDataManager.UpdateStat("Reputation", 10)
                        return "You won the appeal! Your reputation grew."
                    else
                        PlayerDataManager.UpdateStat("Money", -200)
                        PlayerDataManager.UpdateStat("Reputation", -5)
                        return "You lost the legal battle and $200."
                    end
                end
            },
            {
                Text = "Remove Song",
                Effect = function()
                    PlayerDataManager.UpdateStat("Followers", -100)
                    return "Fans are disappointed the song is gone."
                end
            }
        }
    },

    -- 2. POSITIVE EVENTS
    {
        Id = "ViralMoment",
        Title = "VIRAL MOMENT",
        Description = "A snippet of your session was used in a mega-viral trend!",
        Type = "Positive",
        Weight = 5,
        Options = {
            {
                Text = "Ride the Wave",
                Effect = function()
                    PlayerDataManager.UpdateStat("Followers", 1000)
                    PlayerDataManager.UpdateStat("Fame", 50)
                    PlayerDataManager.UpdateStat("Hype", 20)
                    return "Massive growth! You're everywhere."
                end
            },
            {
                Text = "Drop Single Now",
                Effect = function()
                    PlayerDataManager.UpdateStat("Money", 1000)
                    PlayerDataManager.UpdateStat("Fame", 20)
                    return "Quick cash! You made $1000 from the hype."
                end
            }
        }
    },

    -- 3. NEUTRAL / RISK
    {
        Id = "TwitterBeef",
        Title = "TWITTER BEEF",
        Description = "A rival producer is sub-tweeting you. Everyone is watching.",
        Type = "Risk",
        Weight = 20,
        Options = {
            {
                Text = "Ignite Beef",
                Effect = function()
                    PlayerDataManager.UpdateStat("Hype", 30)
                    PlayerDataManager.UpdateStat("Reputation", -10)
                    return "High hype, but the industry thinks you're messy."
                end
            },
            {
                Text = "Stay Classy",
                Effect = function()
                    PlayerDataManager.UpdateStat("Reputation", 15)
                    PlayerDataManager.UpdateStat("Hype", -5)
                    return "You earned respect for staying out of it."
                end
            }
        }
    }
}

-- ARTIST REQUESTS (Sign/Job)
local REQUESTS = {
    Sign = {
        Id = "SignRequest",
        Title = "NEW TALENT",
        Description = "A rising artist wants to join your roster.",
        Options = {
            {
                Text = "Sign Them",
                Effect = function(artistData)
                    local state = PlayerDataManager.GetState()
                    if #state.Artists < state.StudioLevel then
                        PlayerDataManager.AddArtist(artistData)
                        return artistData.Name .. " has joined the studio!"
                    else
                        return "No slots available! Missed opportunity."
                    end
                end
            },
            {
                Text = "Decline",
                Effect = function() return "You passed on the artist." end
            }
        }
    }
}

function EventSystem.GetRandomEvent()
    local totalWeight = 0
    for _, e in pairs(EVENTS) do totalWeight += e.Weight end
    
    local rand = math.random(totalWeight)
    local current = 0
    for _, e in pairs(EVENTS) do
        current += e.Weight
        if rand <= current then return e end
    end
    return EVENTS[1]
end

function EventSystem.GetRequest(type)
    return REQUESTS[type]
end

function EventSystem.TriggerEvent(eventId, artistId)
    local event = nil
    for _, e in pairs(EVENTS) do if e.Id == eventId then event = e break end end
    if not event then return nil end
    
    -- In a real scenario, this would be called from the server and communicated to client
    return event
end

return EventSystem
