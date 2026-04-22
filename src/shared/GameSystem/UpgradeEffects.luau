local UpgradeEffects = {}

-- Defines the exact stat bonuses (Secondary and Hidden) provided by each level of equipment.
UpgradeEffects.Effects = {
    Computer = {
        [1] = { ProductionQuality = 10, HitChance = 0.05, TechnicalFailureChance = 0.20 },
        [2] = { ProductionQuality = 25, HitChance = 0.12, TechnicalFailureChance = 0.10 },
        [3] = { ProductionQuality = 50, HitChance = 0.25, TechnicalFailureChance = 0.02 }
    },
    Microphone = {
        [1] = { RecordingQuality = 10, FameGain = 1.0, BadReviewChance = 0.15 },
        [2] = { RecordingQuality = 30, FameGain = 1.5, BadReviewChance = 0.05 },
        [3] = { RecordingQuality = 60, FameGain = 2.5, BadReviewChance = 0.01 }
    },
    Speakers = {
        [1] = { MixQuality = 10, HitChance = 0.02, TechnicalFailureChance = 0.10 },
        [2] = { MixQuality = 25, HitChance = 0.08, TechnicalFailureChance = 0.05 },
        [3] = { MixQuality = 50, HitChance = 0.15, TechnicalFailureChance = 0.01 }
    },
    DecoUpgrades = {
        [1] = { StudioPrestige = 5, ArtistAttraction = 0.05, StressReduction = 1, FollowerGain = 1.1 },
        [2] = { StudioPrestige = 20, ArtistAttraction = 0.15, StressReduction = 3, FollowerGain = 1.3 },
        [3] = { StudioPrestige = 50, ArtistAttraction = 0.30, StressReduction = 8, FollowerGain = 1.6 }
    }
}

return UpgradeEffects
