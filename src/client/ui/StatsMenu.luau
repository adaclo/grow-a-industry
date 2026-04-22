local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameSystem")
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local StatsMenu = {}
StatsMenu.__index = StatsMenu

local COLORS = {
    BACKGROUND = Color3.fromHex("#0A0A0A"),
    PANEL = Color3.fromHex("#121212"),
    ACCENT = Color3.fromHex("#8A2BE2"),
    TEXT_PRIMARY = Color3.fromHex("#FFFFFF"),
    TEXT_SECONDARY = Color3.fromHex("#B3B3B3"),
}

local FONTS = {
    TITLE = Enum.Font.GothamBold,
    STAT_NAME = Enum.Font.GothamMedium,
    STAT_VALUE = Enum.Font.GothamBold,
}

function StatsMenu.new(parentGui)
    local self = setmetatable({}, StatsMenu)

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "StatsFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = COLORS.PANEL
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = parentGui
    self.MainFrame = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = mainFrame

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundTransparency = 1
    header.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Text = "CAREER STATS"
    title.Font = FONTS.TITLE
    title.TextSize = 24
    title.TextColor3 = COLORS.TEXT_PRIMARY
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Parent = header

    local backBtn = Instance.new("TextButton")
    backBtn.Name = "BackButton"
    backBtn.Text = "< BACK"
    backBtn.Font = Enum.Font.GothamMedium
    backBtn.TextSize = 14
    backBtn.TextColor3 = COLORS.ACCENT
    backBtn.Size = UDim2.new(0, 80, 0, 30)
    backBtn.Position = UDim2.new(0, 20, 0, 25)
    backBtn.BackgroundTransparency = 1
    backBtn.Parent = header
    self.BackButton = backBtn

    -- Stats Container
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -60, 1, -120)
    container.Position = UDim2.new(0, 30, 0, 100)
    container.BackgroundTransparency = 1
    container.Parent = mainFrame
    self.Container = container

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = container

    self.StatEntries = {}
    self:CreateStatEntry("Money", "$")
    self:CreateStatEntry("Fame", "")
    self:CreateStatEntry("Followers", "")
    self:CreateStatEntry("Reputation", "%")
    self:CreateStatEntry("Stress", "%")

    -- Listen for updates
    PlayerDataManager.StateChanged:Connect(function()
        if self.MainFrame.Visible then
            self:Refresh()
        end
    end)

    return self
end

function StatsMenu:CreateStatEntry(statName, suffix)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = Color3.fromHex("#1A1A1A")
    frame.BorderSizePixel = 0
    frame.Parent = self.Container
    
    Instance.new("UICorner").Parent = frame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Text = statName:upper()
    nameLabel.Font = FONTS.STAT_NAME
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = COLORS.TEXT_SECONDARY
    nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
    nameLabel.Position = UDim2.new(0.05, 0, 0, 0)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.BackgroundTransparency = 1
    nameLabel.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Text = suffix or ""
    valueLabel.Font = FONTS.STAT_VALUE
    valueLabel.TextSize = 18
    valueLabel.TextColor3 = COLORS.TEXT_PRIMARY
    valueLabel.Size = UDim2.new(0.4, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.55, 0, 0, 0)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.BackgroundTransparency = 1
    valueLabel.Parent = frame
    
    self.StatEntries[statName] = {Label = valueLabel, Suffix = suffix}
end

function StatsMenu:Refresh()
    for statName, data in pairs(self.StatEntries) do
        local val = PlayerDataManager.GetStat(statName)
        if data.Suffix == "$" then
            data.Label.Text = "$" .. string.format("%.0f", val)
        else
            data.Label.Text = string.format("%.0f", val) .. (data.Suffix or "")
        end
    end
end

function StatsMenu:Toggle(isVisible)
    if isVisible then
        self:Refresh()
        self.MainFrame.Visible = true
        self.MainFrame.Position = UDim2.new(1, 0, 0, 0)
        TweenService:Create(self.MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
    else
        local t = TweenService:Create(self.MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 0, 0, 0)
        })
        t:Play()
        t.Completed:Connect(function()
            self.MainFrame.Visible = false
        end)
    end
end

return StatsMenu
