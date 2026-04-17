--[[
    "Grow A Industry" - Upgrade Menu
    A modern, visually polished menu for studio equipment upgrades.
    Includes persistent state simulation and dynamic UI refreshing.
]]

local TweenService = Game:GetService("TweenService")
local Players = Game:GetService("Players")
local UpgradeVisibility = require(script.Parent.Parent:WaitForChild("UpgradeVisibility"))

local UpgradeMenu = {}
UpgradeMenu.__index = UpgradeMenu

-- Constants (Shared Aesthetic)
local COLORS = {
    BACKGROUND = Color3.fromHex("#0A0A0A"),
    PANEL = Color3.fromHex("#121212"),
    ROW = Color3.fromHex("#1A1A1A"),
    ACCENT = Color3.fromHex("#8A2BE2"),
    ACCENT_NEON = Color3.fromHex("#BF40BF"),
    TEXT_PRIMARY = Color3.fromHex("#FFFFFF"),
    TEXT_SECONDARY = Color3.fromHex("#B3B3B3"),
    MONEY = Color3.fromHex("#4BB543"),
    DISABLED = Color3.fromHex("#333333")
}

local FONTS = {
    TITLE = Enum.Font.GothamBold,
    SUBTITLE = Enum.Font.GothamMedium,
    BUTTON = Enum.Font.GothamBold,
    BODY = Enum.Font.Gotham
}

-- Upgrade Data Simulation
local UPGRADES_DATA = {
    {
        Id = "Computer",
        Description = "Improve your processing power and software speed.",
        Levels = {
            {Name = "Old Laptop", Price = 0},
            {Name = "Gaming PC", Price = 500},
            {Name = "Professional Studio Setup", Price = 2500}
        }
    },
    {
        Id = "Microphone",
        Description = "Capture crystal clear vocals and instruments.",
        Levels = {
            {Name = "Cheap Microphone", Price = 0},
            {Name = "Mid-range Studio Mic", Price = 800},
            {Name = "Professional Recording Microphone", Price = 4000}
        }
    },
    {
        Id = "Speakers",
        Description = "Hear every detail in your mix with precision monitor speakers.",
        Levels = {
            {Name = "Basic Speakers", Price = 0},
            {Name = "Studio Monitors", Price = 600},
            {Name = "Premium Audio System", Price = 3500}
        }
    },
    {
        Id = "DecoUpgrades",
        Description = "Personalize your studio with various decorations.",
        Levels = {
            {Name = "Posters", Price = 0},
            {Name = "Monsters", Price = 500},
            {Name = "Doritos", Price = 1500}
        }
    }
}

-- Mock State (Normally would come from a Server DataStore)
local PlayerData = {
    Money = 30000,
    Levels = {
        Computer = 1,
        Microphone = 1,
        Speakers = 1,
        DecoUpgrades = 1
    }
}
UpgradeMenu.PlayerData = PlayerData

-- Utility: Create a Tween
local function createTween(instance, info, propertyTable)
    local tween = TweenService:Create(instance, info, propertyTable)
    tween:Play()
    return tween
end

function UpgradeMenu.new()
    local self = setmetatable({}, UpgradeMenu)

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UpgradeMenuGui"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = screenGui

    -- Main Container
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 500)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = COLORS.PANEL
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = COLORS.ACCENT
    stroke.Transparency = 0.5
    stroke.Parent = mainFrame

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundTransparency = 1
    header.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Text = "STUDIO UPGRADES"
    title.Font = FONTS.TITLE
    title.TextSize = 28
    title.TextColor3 = COLORS.TEXT_PRIMARY
    title.Size = UDim2.new(0.6, 0, 1, 0)
    title.Position = UDim2.new(0.05, 0, 0, 0)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.Parent = header

    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Name = "MoneyLabel"
    moneyLabel.Text = "$" .. PlayerData.Money
    moneyLabel.Font = FONTS.SUBTITLE
    moneyLabel.TextSize = 22
    moneyLabel.TextColor3 = COLORS.MONEY
    moneyLabel.Size = UDim2.new(0.3, 0, 1, 0)
    moneyLabel.Position = UDim2.new(0.65, 0, 0, 0)
    moneyLabel.TextXAlignment = Enum.TextXAlignment.Right
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Parent = header
    self.MoneyLabel = moneyLabel

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Text = "×"
    closeBtn.TextSize = 40
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.TextColor3 = COLORS.TEXT_SECONDARY
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -50, 0, 20)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Parent = header

    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle(false)
    end)

    -- Scrolling List
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "UpgradeList"
    scrollFrame.Size = UDim2.new(1, -40, 1, -110)
    scrollFrame.Position = UDim2.new(0, 20, 0, 90)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = COLORS.ACCENT
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto-size
    scrollFrame.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = scrollFrame

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
    end)

    self.ScrollFrame = scrollFrame
    self:Refresh()

    return self
end

function UpgradeMenu:CreateRow(upgradeData)
    local currentLevel = PlayerData.Levels[upgradeData.Id]
    local isMax = currentLevel >= #upgradeData.Levels
    local nextLevelData = not isMax and upgradeData.Levels[currentLevel + 1] or nil
    local currentLevelData = upgradeData.Levels[currentLevel]

    local row = Instance.new("Frame")
    row.Name = upgradeData.Id .. "Row"
    row.Size = UDim2.new(1, -10, 0, 100)
    row.BackgroundColor3 = COLORS.ROW
    row.BorderSizePixel = 0
    row.Parent = self.ScrollFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = row

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = COLORS.ACCENT
    stroke.Transparency = 0.8
    stroke.Parent = row

    -- Info Container
    local info = Instance.new("Frame")
    info.Size = UDim2.new(0.65, 0, 1, 0)
    info.Position = UDim2.new(0, 15, 0, 0)
    info.BackgroundTransparency = 1
    info.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Text = upgradeData.Id:upper() .. " - " .. currentLevelData.Name
    nameLabel.Font = FONTS.TITLE
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = COLORS.TEXT_PRIMARY
    nameLabel.Size = UDim2.new(1, 0, 0, 30)
    nameLabel.Position = UDim2.new(0, 0, 0.15, 0)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.BackgroundTransparency = 1
    nameLabel.Parent = info

    local descLabel = Instance.new("TextLabel")
    descLabel.Text = upgradeData.Description
    descLabel.Font = FONTS.BODY
    descLabel.TextSize = 12
    descLabel.TextColor3 = COLORS.TEXT_SECONDARY
    descLabel.Size = UDim2.new(1, 0, 0, 40)
    descLabel.Position = UDim2.new(0, 0, 0.45, 0)
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.BackgroundTransparency = 1
    descLabel.Parent = info

    local levelBadge = Instance.new("TextLabel")
    levelBadge.Text = "LVL " .. currentLevel
    levelBadge.Font = FONTS.SUBTITLE
    levelBadge.TextSize = 10
    levelBadge.TextColor3 = COLORS.ACCENT_NEON
    levelBadge.Size = UDim2.new(0, 50, 0, 20)
    levelBadge.Position = UDim2.new(1, -60, 0.15, 0)
    levelBadge.BackgroundColor3 = COLORS.BACKGROUND
    levelBadge.Parent = info
    
    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(1, 0)
    badgeCorner.Parent = levelBadge

    -- Action Container
    local action = Instance.new("Frame")
    action.Size = UDim2.new(0.3, 0, 1, 0)
    action.Position = UDim2.new(0.68, 0, 0, 0)
    action.BackgroundTransparency = 1
    action.Parent = row

    local buyBtn = Instance.new("TextButton")
    buyBtn.Name = "BuyButton"
    buyBtn.Size = UDim2.new(0.9, 0, 0, 40)
    buyBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
    buyBtn.AnchorPoint = Vector2.new(0, 0.5)
    buyBtn.Font = FONTS.BUTTON
    buyBtn.TextSize = 14
    buyBtn.TextColor3 = COLORS.TEXT_PRIMARY
    buyBtn.AutoButtonColor = false
    buyBtn.BorderSizePixel = 0
    buyBtn.Parent = action

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = buyBtn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Thickness = 2
    btnStroke.Color = COLORS.ACCENT_NEON
    btnStroke.Parent = buyBtn

    if isMax then
        buyBtn.Text = "MAX LEVEL"
        buyBtn.BackgroundColor3 = COLORS.DISABLED
        btnStroke.Color = COLORS.DISABLED
        buyBtn.Active = false
    else
        buyBtn.Text = "UPGRADE\n$" .. nextLevelData.Price
        buyBtn.BackgroundColor3 = COLORS.ACCENT
        
        -- Hover
        buyBtn.MouseEnter:Connect(function()
            createTween(buyBtn, TweenInfo.new(0.3), {BackgroundColor3 = COLORS.ACCENT_NEON})
            createTween(btnStroke, TweenInfo.new(0.3), {Transparency = 0})
        end)
        buyBtn.MouseLeave:Connect(function()
            createTween(buyBtn, TweenInfo.new(0.3), {BackgroundColor3 = COLORS.ACCENT})
            createTween(btnStroke, TweenInfo.new(0.3), {Transparency = 0.5})
        end)

        -- Click
        buyBtn.MouseButton1Click:Connect(function()
            if PlayerData.Money >= nextLevelData.Price then
                PlayerData.Money -= nextLevelData.Price
                PlayerData.Levels[upgradeData.Id] += 1
                
                -- Physical Upgrade: Update the model in Workspace
                if upgradeData.Id == "Computer" then
                    UpgradeVisibility.updateComputerUpgrade(PlayerData.Levels.Computer)
                elseif upgradeData.Id == "Microphone" then
                    UpgradeVisibility.updateMicUpgrade(PlayerData.Levels.Microphone)
                elseif upgradeData.Id == "Speakers" then
                    UpgradeVisibility.updateSpeakerUpgrade(PlayerData.Levels.Speakers)
                elseif upgradeData.Id == "DecoUpgrades" then
                    UpgradeVisibility.updateDecoUpgrade(PlayerData.Levels.DecoUpgrades)
                end
                -- Visual Feedback
                local flash = Instance.new("Frame")
                flash.Size = UDim2.new(1, 0, 1, 0)
                flash.BackgroundColor3 = COLORS.ACCENT_NEON
                flash.BackgroundTransparency = 0.5
                flash.ZIndex = 10
                flash.Parent = row
                Instance.new("UICorner").Parent = flash
                
                createTween(flash, TweenInfo.new(0.5), {BackgroundTransparency = 1})
                task.delay(0.5, function() flash:Destroy() end)
                
                self:Refresh()
            else
                -- Error shake or color flash
                createTween(buyBtn, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {BackgroundColor3 = Color3.new(0.8, 0, 0)})
                task.delay(0.2, function()
                    createTween(buyBtn, TweenInfo.new(0.3), {BackgroundColor3 = COLORS.ACCENT})
                end)
            end
        end)
    end

    return row
end

function UpgradeMenu:Refresh()
    -- Clear current list
    for _, child in pairs(self.ScrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    -- Update Money
    self.MoneyLabel.Text = "$" .. PlayerData.Money
    
    -- Update physical prop visibility (Money Stacks)
    UpgradeVisibility.updateMoneyVisibility(PlayerData.Money)

    -- Rebuild rows
    for _, data in pairs(UPGRADES_DATA) do
        self:CreateRow(data)
    end
end

function UpgradeMenu:Toggle(isVisible)
    self.Gui.Enabled = isVisible
    if isVisible then
        self:Refresh()
        -- Animated fade in/scale
        local mainFrame = self.Gui.MainFrame
        mainFrame.Size = UDim2.new(0, 500, 0, 400)
        mainFrame.GroupTransparency = 1
        createTween(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 600, 0, 500),
            GroupTransparency = 0
        })
    end
end

return UpgradeMenu
