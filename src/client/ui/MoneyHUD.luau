local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameSystem")
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local MoneyHUD = {}
MoneyHUD.__index = MoneyHUD

local COLORS = {
	BG = Color3.fromHex("#121212"),
	ACCENT = Color3.fromHex("#8A2BE2"),
	TEXT = Color3.fromHex("#FFFFFF"),
	MONEY = Color3.fromHex("#4BB543"),
	GOLD = Color3.fromHex("#FFD700"),
}

local function formatMoney(amount)
	amount = math.floor(amount + 0.5)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. tostring(amount)
	end
end

function MoneyHUD.new()
	local self = setmetatable({}, MoneyHUD)

	-- ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "MoneyHUD"
	gui.DisplayOrder = 900
	gui.ResetOnSpawn = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	self.Gui = gui

	local container = Instance.new("Frame")
	container.Name = "MoneyContainer"
	container.AnchorPoint = Vector2.new(1, 0)
	container.Size = UDim2.new(0, 180, 0, 56)
	container.Position = UDim2.new(1, -24, 0, 24)
	container.BackgroundTransparency = 1
	container.ZIndex = 900
	container.Parent = gui
	self.Container = container

	-- Dollar icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Text = "💰"
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 22
	icon.Size = UDim2.new(0, 36, 1, 0)
	icon.Position = UDim2.new(0, 4, 0, 0)
	icon.BackgroundTransparency = 1
	icon.ZIndex = 901
	icon.Parent = container

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Thickness = 2
	iconStroke.Color = Color3.new(0, 0, 0)
	iconStroke.Transparency = 0.2
	iconStroke.Parent = icon

	-- Money label
	local label = Instance.new("TextLabel")
	label.Name = "MoneyLabel"
	label.Text = "$0"
	label.Font = Enum.Font.GothamBold
	label.TextSize = 24
	label.TextColor3 = COLORS.MONEY
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.Size = UDim2.new(1, -48, 1, 0)
	label.Position = UDim2.new(0, 36, 0, 0)
	label.BackgroundTransparency = 1
	label.ZIndex = 901
	label.Parent = container
	self.Label = label

	local labelStroke = Instance.new("UIStroke")
	labelStroke.Thickness = 2
	labelStroke.Color = Color3.new(0, 0, 0)
	labelStroke.Transparency = 0.2
	labelStroke.Parent = label

	-- Flash overlay for change animation
	local flash = Instance.new("TextLabel")
	flash.Name = "Flash"
	flash.Text = ""
	flash.Size = UDim2.new(1, -48, 1, 0)
	flash.Position = UDim2.new(0, 36, 0, 0)
	flash.BackgroundTransparency = 1
	flash.TextTransparency = 1
	flash.Font = Enum.Font.GothamBold
	flash.TextSize = 24
	flash.TextColor3 = COLORS.MONEY
	flash.TextXAlignment = Enum.TextXAlignment.Right
	flash.ZIndex = 902
	flash.Parent = container
	self.Flash = flash
	
	local flashStroke = Instance.new("UIStroke")
	flashStroke.Thickness = 2
	flashStroke.Color = Color3.new(1, 1, 1)
	flashStroke.Transparency = 1
	flashStroke.Parent = flash
	self.FlashStroke = flashStroke

	-- Set initial value
	local state = PlayerDataManager.GetState()
	local money = (state.Stats and state.Stats.Money) or 0
	self.Label.Text = formatMoney(money)
	self.LastMoney = money

	-- Listen for changes
	PlayerDataManager.StateChanged:Connect(function(key, value)
		if key == "Money" then
			local newMoney = value
			local delta = newMoney - (self.LastMoney or 0)
			self.LastMoney = newMoney
			self.Label.Text = formatMoney(newMoney)

			-- Flash green for gain, red for loss
			local flashColor = delta >= 0 and COLORS.MONEY or Color3.fromHex("#FF4444")
			self.Flash.TextColor3 = flashColor
			self.Flash.Text = formatMoney(newMoney)
			self.Flash.TextTransparency = 0
			self.FlashStroke.Transparency = 0.5
			TweenService:Create(self.Flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 1
			}):Play()
			TweenService:Create(self.FlashStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1
			}):Play()

			-- Pulse scale
			self.Container.Size = UDim2.new(0, 170, 0, 46)
			TweenService:Create(self.Container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 160, 0, 42)
			}):Play()
		end
	end)

	return self
end

return MoneyHUD
