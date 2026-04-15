local MainMenu = require(script.Parent:WaitForChild("ui"):WaitForChild("MainMenu"))
local UpgradeMenu = require(script.Parent:WaitForChild("ui"):WaitForChild("UpgradeMenu"))

-- Start the Main Menu
local menu = MainMenu.new()
print("Main Menu initialized!")

-- Initialize Upgrade Menu (Hidden by default)
local upgrades = UpgradeMenu.new()

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
