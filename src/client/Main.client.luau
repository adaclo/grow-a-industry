local MainMenu = require(script.Parent:WaitForChild("ui"):WaitForChild("MainMenu"))
local UpgradeMenu = require(script.Parent:WaitForChild("ui"):WaitForChild("UpgradeMenu"))
local UpgradeVisibility = require(script.Parent:WaitForChild("UpgradeVisibility"))
local ComputerMenu = require(script.Parent:WaitForChild("ui"):WaitForChild("ComputerMenu"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameSystem")
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))
local EventManager = require(SharedModules:WaitForChild("EventManager"))
local ComputerInteraction = require(script.Parent:WaitForChild("systems"):WaitForChild("ComputerInteraction"))

-- Start the Main Menu
local menu = MainMenu.new()
print("Main Menu initialized!")

-- Initialize Upgrade Menu (Hidden by default)
local upgrades = UpgradeMenu.new()

-- Initialize Computer Menu and its Interaction System
local computer = ComputerMenu.new(upgrades)
local computerInteract = ComputerInteraction.new(computer)

-- Separate ScreenGui for Test Buttons (so they are always visible)
local testGui = Instance.new("ScreenGui")
testGui.Name = "TestButtonsGui"
testGui.DisplayOrder = 999 -- Ensure it's above everything
testGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- Temporary Test Button for Upgrade Menu
local testBtn = Instance.new("TextButton")
testBtn.Name = "TestUpgradeButton"
testBtn.Text = "OPEN UPGRADES (TEST)"
testBtn.Size = UDim2.new(0, 180, 0, 40)
testBtn.Position = UDim2.new(0, 20, 1, -60)
testBtn.BackgroundColor3 = Color3.fromHex("#8A2BE2")
testBtn.TextColor3 = Color3.new(1, 1, 1)
testBtn.Font = Enum.Font.GothamBold
testBtn.TextSize = 14
testBtn.Parent = testGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = testBtn

testBtn.MouseButton1Click:Connect(function()
    upgrades:Toggle(not upgrades.Gui.Enabled)
end)

-- Temporary Test Button for Money
local moneyBtn = Instance.new("TextButton")
moneyBtn.Name = "TestMoneyButton"
moneyBtn.Text = "GIVE $10K (TEST)"
moneyBtn.Size = UDim2.new(0, 150, 0, 40)
moneyBtn.Position = UDim2.new(0, 210, 1, -60)
moneyBtn.BackgroundColor3 = Color3.fromHex("#4BB543")
moneyBtn.TextColor3 = Color3.new(1, 1, 1)
moneyBtn.Font = Enum.Font.GothamBold
moneyBtn.TextSize = 14
moneyBtn.Parent = testGui

local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0, 8)
moneyCorner.Parent = moneyBtn

moneyBtn.MouseButton1Click:Connect(function()
    PlayerDataManager.UpdateStat("Money", 10000)
    print("[Admin] Gave $10,000 via Test Button")
end)

-- Temporary Test Button for Events
local eventBtn = Instance.new("TextButton")
eventBtn.Name = "TestEventButton"
eventBtn.Text = "TRIGGER EVENT"
eventBtn.Size = UDim2.new(0, 150, 0, 40)
eventBtn.Position = UDim2.new(0, 380, 1, -60)
eventBtn.BackgroundColor3 = Color3.fromHex("#FFA500")
eventBtn.TextColor3 = Color3.new(1, 1, 1)
eventBtn.Font = Enum.Font.GothamBold
eventBtn.TextSize = 14
eventBtn.Parent = testGui

local eventCorner = Instance.new("UICorner")
eventCorner.CornerRadius = UDim.new(0, 8)
eventCorner.Parent = eventBtn

eventBtn.MouseButton1Click:Connect(function()
    local result = EventManager.TriggerRandomEvent()
    if result.Type == "Positive" then
        print(string.format("[Event] %s (%s) - Earned: $%d | Fame: +%d | Followers: +%d", 
            result.Name, result.Tier, result.Amount, result.Fame, result.Followers))
    else
        warn(string.format("[Event] %s - LOST: $%d", result.Name, math.abs(result.Amount)))
    end
end)



-- Set initial visibility state
local initialState = PlayerDataManager.GetState()
UpgradeVisibility.updateComputerUpgrade(initialState.Levels.Computer)
UpgradeVisibility.updateMicUpgrade(initialState.Levels.Microphone)
UpgradeVisibility.updateSpeakerUpgrade(initialState.Levels.Speakers)
UpgradeVisibility.updateDecoUpgrade(initialState.Levels.DecoUpgrades)
UpgradeVisibility.updateMoneyVisibility(initialState.Stats.Money)


