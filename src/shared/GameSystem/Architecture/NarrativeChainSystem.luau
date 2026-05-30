-- NarrativeChainSystem.luau
-- Manages multi-stage narrative arcs that escalate over time.

local SharedModules     = script.Parent.Parent
local EventBus          = require(script.Parent:WaitForChild("EventBus"))
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local NarrativeChainSystem = {}

local CHAINS = {
    IgnoredArtist = {
        Id = "IgnoredArtist",
        MaxStages = 5,
        CheckTrigger = function(state)
            local ArtistSystem = require(SharedModules:WaitForChild("ArtistSystem"))
            for _, artist in pairs(state.Artists) do
                local resentment = artist.Resentment or 0
                local trust = artist.Trust or 50
                local stress = artist.Stress or 0
                local isCloutChaser = ArtistSystem.HasTrait(artist, "CloutChaser")
                
                -- Check for high resentment, low trust, and high stress (or needy trait)
                if resentment > 60 and trust < 40 and (stress > 60 or isCloutChaser) then
                    return true, { artistId = artist.Id }
                end
            end
            return false, nil
        end,
        OnAdvance = function(stage, context)
            local state = PlayerDataManager.GetState()
            local artist = nil
            for _, a in pairs(state.Artists) do
                if a.Id == context.artistId then artist = a break end
            end
            if not artist then return "CANCEL" end -- artist was dropped

            if stage == 1 then
                return { Text = string.format("%s is feeling ignored by the label.", artist.Name), Type = "NARRATIVE" }
            elseif stage == 2 then
                return { Text = string.format("%s posted passive-aggressive comments online.", artist.Name), Type = "NARRATIVE" }
            elseif stage == 3 then
                PlayerDataManager.UpdateRosterTension(10)
                return { Text = string.format("Fans are noticing tension between %s and the label.", artist.Name), Type = "NARRATIVE" }
            elseif stage == 4 then
                PlayerDataManager.UpdateArtist(artist.Id, { Loyalty = math.clamp(artist.Loyalty - 10, 0, 100) })
                PlayerDataManager.UpdateRosterTension(15)
                return { Text = string.format("%s's loyalty is dropping. The roster is feeling the heat.", artist.Name), Type = "Negative" }
            elseif stage == 5 then
                return {
                    EventTrigger = {
                        Id = "chain_ignored_artist",
                        Title = "ARTIST REBELLION",
                        Description = string.format("%s has reached their breaking point and is threatening to leave unless things change immediately.", artist.Name),
                        Consequences = {
                            Type = "Negative",
                            Options = {
                                {
                                    Text = "Give Them a Bonus ($2000)",
                                    Effect = function(contextData)
                                        return {
                                            Description = string.format("You paid them off. They are staying, but the resentment remains."),
                                            Payload = {
                                                statChanges = { Money = -2000 },
                                                artistId = contextData.artistId,
                                                artistUpdate = { Trust = 50, Stress = 0 }
                                            }
                                        }
                                    end
                                },
                                {
                                    Text = "Let Them Leave",
                                    Effect = function(contextData)
                                        return {
                                            Description = string.format("They walked out, damaging your reputation slightly."),
                                            Payload = {
                                                statChanges = { Reputation = -10 },
                                                artistId = contextData.artistId,
                                                removeArtist = true
                                            }
                                        }
                                    end
                                }
                            }
                        }
                    }
                }
            end
        end
    },
    InternalBeef = {
        Id = "InternalBeef",
        MaxStages = 5,
        CheckTrigger = function(state)
            if #state.Artists < 2 then return false, nil end
            local tension = state.Stats.RosterTension or 0
            if tension > 60 then
                local ArtistSystem = require(SharedModules:WaitForChild("ArtistSystem"))
                for _, a in pairs(state.Artists) do
                    if ArtistSystem.HasTrait(a, "DramaMagnet") or (a.Ego and a.Ego > 70) then
                        return true, { instigatorId = a.Id }
                    end
                end
            end
            return false, nil
        end,
        OnAdvance = function(stage, context)
            local state = PlayerDataManager.GetState()
            local instigator = nil
            for _, a in pairs(state.Artists) do
                if a.Id == context.instigatorId then instigator = a break end
            end
            if not instigator then return "CANCEL" end

            if stage == 1 then
                return { Text = string.format("Some artists have stopped interacting with %s.", instigator.Name), Type = "NARRATIVE" }
            elseif stage == 2 then
                return { Text = "Studio sessions are becoming noticeably tense.", Type = "NARRATIVE" }
            elseif stage == 3 then
                PlayerDataManager.UpdateRosterTension(10)
                return { Text = "Rumors of internal label beef have hit the blogs.", Type = "NARRATIVE" }
            elseif stage == 4 then
                return { Text = "Fans are picking sides. The tension is palpable.", Type = "Negative" }
            elseif stage == 5 then
                return {
                    EventTrigger = {
                        Id = "chain_internal_beef",
                        Title = "ROSTER WAR",
                        Description = string.format("The internal beef started by %s has escalated into a full public feud.", instigator.Name),
                        Consequences = {
                            Type = "Negative",
                            Options = {
                                {
                                    Text = "Mediate the Dispute",
                                    Effect = function(contextData)
                                        return {
                                            Description = "You spent time cooling everyone down. Tension drops, but hype suffers.",
                                            Payload = {
                                                statChanges = { Hype = -15 },
                                                rosterTensionChange = -30
                                            }
                                        }
                                    end
                                },
                                {
                                    Text = "Exploit the Drama",
                                    Effect = function(contextData)
                                        return {
                                            Description = "You fed the drama to the press. Massive hype, but the roster is furious.",
                                            Payload = {
                                                statChanges = { Hype = 40, Reputation = -10 },
                                                rosterTensionChange = 20
                                            }
                                        }
                                    end
                                }
                            }
                        }
                    }
                }
            end
        end
    }
}

function NarrativeChainSystem.Init()
    EventBus.Subscribe("PASSIVE_TICK", function()
        local state = PlayerDataManager.GetState()
        
        -- 1. Check for triggers to start new chains
        for id, chainDef in pairs(CHAINS) do
            if not state.ActiveChains[id] then
                local shouldStart, context = chainDef.CheckTrigger(state)
                if shouldStart then
                    PlayerDataManager.AddNarrativeChain(id, {
                        Stage = 0,
                        Context = context,
                        TicksInStage = 0
                    })
                    print(string.format("[NarrativeChainSystem] Started new chain: %s", id))
                end
            end
        end

        -- 2. Advance active chains
        for id, activeData in pairs(state.ActiveChains) do
            local chainDef = CHAINS[id]
            if chainDef then
                activeData.TicksInStage = (activeData.TicksInStage or 0) + 1
                
                -- Advance stage every X ticks (e.g., 3 passive ticks per stage)
                local TICKS_PER_STAGE = 3
                if activeData.TicksInStage >= TICKS_PER_STAGE then
                    activeData.Stage = activeData.Stage + 1
                    activeData.TicksInStage = 0
                    
                    if activeData.Stage > chainDef.MaxStages then
                        PlayerDataManager.RemoveNarrativeChain(id)
                    else
                        local result = chainDef.OnAdvance(activeData.Stage, activeData.Context)
                        if result == "CANCEL" then
                            PlayerDataManager.RemoveNarrativeChain(id)
                        elseif result and result.EventTrigger then
                            EventBus.Emit("REACTIVE_EVENT_TRIGGERED", {
                                EventData = result.EventTrigger,
                                Context = activeData.Context
                            })
                            PlayerDataManager.RemoveNarrativeChain(id)
                        elseif result and result.Text then
                            EventBus.Emit("READABILITY_NOTIFICATION", result)
                            PlayerDataManager.UpdateNarrativeChain(id, { Stage = activeData.Stage, TicksInStage = 0 })
                        end
                    end
                else
                    PlayerDataManager.UpdateNarrativeChain(id, { TicksInStage = activeData.TicksInStage })
                end
            end
        end
    end)
    
    print("[NarrativeChainSystem] Initialized.")
end

return NarrativeChainSystem
