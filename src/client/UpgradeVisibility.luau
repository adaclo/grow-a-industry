local UpgradeVisibility = {}

--[[
    Grow A Industry - Upgrade Visibility System
    This module manages the visual states of upgrades in the studio.
    It handles parts, decals, textures, and GUIs recursively.
]]

-- Configuration: Reference to the models in the Workspace
local Studio = workspace:WaitForChild("Studio", 10)
if not Studio then
    warn("UpgradeVisibility: CRITICAL - 'Studio' folder not found!")
end

local ComputerUpgrades = Studio and Studio:WaitForChild("ComputerUpgrades", 5)
local MicUpgrades = Studio and Studio:WaitForChild("MicUpgrades", 5)
local SpeakerUpgrades = Studio and Studio:WaitForChild("SpeakerUpgrades", 5)
local DecoUpgrades = Studio and Studio:WaitForChild("DecoUpgrades", 5)
local Props = Studio and Studio:WaitForChild("Props", 5)

-- Hidden Storage: We move models here instead of changing transparency
-- This is much more robust for physics-based models
local HiddenStorage = game:GetService("ReplicatedStorage"):FindFirstChild("HiddenUpgrades")
if not HiddenStorage then
    HiddenStorage = Instance.new("Folder")
    HiddenStorage.Name = "HiddenUpgrades"
    HiddenStorage.Parent = game:GetService("ReplicatedStorage")
end

-- Tables to keep track of models even when they are hidden
local allComputerModels = {}
local allMicModels = {}
local allSpeakerModels = {}
local allDecoModels = {}
local moneyModel = nil -- Reference to Studio/Props/Money

local function anchorModel(model: Instance)
    if not model then return end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.Massless = true
            -- We disable collision to prevent physics 'explosions' if parts overlap
            descendant.CanCollide = false
            -- Ensure any existing physics momentum is cleared
            descendant.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            descendant.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end
end

-- Initial discovery: Move everything to storage and index it
-- We wait a bit for replication since this is a LocalScript
task.wait(1)

if ComputerUpgrades then
    for _, model in ipairs(ComputerUpgrades:GetChildren()) do
        -- CRITICAL: Skip the InteractionPart so the ProximityPrompt stays in the world!
        if model.Name == "InteractionPart" then 
            anchorModel(model) -- Still anchor it so it doesn't fall
            continue 
        end
        
        allComputerModels[model.Name] = model
        anchorModel(model) -- Stop parts from falling
        model.Parent = HiddenStorage
    end
end

if MicUpgrades then
    for _, model in ipairs(MicUpgrades:GetChildren()) do
        allMicModels[model.Name] = model
        anchorModel(model) -- Stop parts from falling
        model.Parent = HiddenStorage
    end
end

if SpeakerUpgrades then
    for _, model in ipairs(SpeakerUpgrades:GetChildren()) do
        allSpeakerModels[model.Name] = model
        anchorModel(model)
        model.Parent = HiddenStorage
    end
end

if DecoUpgrades then
    for _, model in ipairs(DecoUpgrades:GetChildren()) do
        allDecoModels[model.Name] = model
        anchorModel(model)
        model.Parent = HiddenStorage
    end
end

if Props then
    local money = Props:FindFirstChild("Money")
    if money then
        moneyModel = money
        anchorModel(money)
        money.Parent = HiddenStorage
    end
end

--[[
    Function: updateComputerUpgrade
]]
function UpgradeVisibility.updateComputerUpgrade(level: number)
    local targetNameMap = {
        [1] = "Portatil",
        [2] = "PC",
        [3] = "GamingPc"
    }
    local targetName = targetNameMap[level]
    print("DEBUG: Updating Computer ->", targetName or "None")

    for name, model in pairs(allComputerModels) do
        if name == targetName then
            anchorModel(model) -- Defensive: always ensure anchored before showing
            model.Parent = ComputerUpgrades
            print("Successfully displayed model:", name)
        else
            model.Parent = HiddenStorage
        end
    end
end

--[[
    Function: updateMicUpgrade
]]
function UpgradeVisibility.updateMicUpgrade(level: number)
    local targetName = "mic" .. level
    print("DEBUG: Updating Mic ->", targetName)
    
    local found = false
    for name, model in pairs(allMicModels) do
        if name == targetName then
            anchorModel(model) -- Defensive: always ensure anchored before showing
            model.Parent = MicUpgrades
            found = true
        else
            model.Parent = HiddenStorage
        end
    end
    
    if not found then
        warn("UpgradeVisibility: No model found named " .. targetName .. " in storage!")
    end
end

--[[
    Function: updateSpeakerUpgrade
]]
function UpgradeVisibility.updateSpeakerUpgrade(level: number)
    local targetName = "speaker" .. level
    print("DEBUG: Updating Speaker ->", targetName)
    
    local found = false
    for name, model in pairs(allSpeakerModels) do
        if name == targetName then
            anchorModel(model)
            model.Parent = SpeakerUpgrades
            found = true
        else
            model.Parent = HiddenStorage
        end
    end
    
    if not found then
        warn("UpgradeVisibility: No model found named " .. targetName .. " in storage!")
    end
end

--[[
    Function: updateDecoUpgrade
]]
function UpgradeVisibility.updateDecoUpgrade(level: number)
    local levelToName = {
        [1] = "Posters",
        [2] = "Monsters",
        [3] = "Doritos"
    }
    
    print("DEBUG: Updating Deco to Level ->", level)

    for name, model in pairs(allDecoModels) do
        local isVisible = false
        -- Additive logic: show everything up to the current level
        for i = 1, level do
            if name == levelToName[i] then
                isVisible = true
                break
            end
        end

        if isVisible then
            anchorModel(model)
            model.Parent = DecoUpgrades
        else
            model.Parent = HiddenStorage
        end
    end
end

--[[
    Function: updateMoneyVisibility
]]
function UpgradeVisibility.updateMoneyVisibility(amount: number)
    if not moneyModel then return end
    
    local isVisible = amount > 10000
    if isVisible then
        moneyModel.Parent = Props
    else
        moneyModel.Parent = HiddenStorage
    end
end

print("UpgradeVisibility: Module initialized with Safe Storage")
return UpgradeVisibility
