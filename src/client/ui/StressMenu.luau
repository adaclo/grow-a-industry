local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameSystem")
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))
local ArtistSystem = require(SharedModules:WaitForChild("ArtistSystem"))

local StressMenu = {}
StressMenu.__index = StressMenu

local COLORS = {
    BACKGROUND = Color3.fromHex("#0A0A0A"),
    PANEL = Color3.fromHex("#121212"),
    ACCENT = Color3.fromHex("#8A2BE2"),
    ACCENT_NEON = Color3.fromHex("#BF40BF"),
    TEXT_PRIMARY = Color3.fromHex("#FFFFFF"),
    TEXT_SECONDARY = Color3.fromHex("#B3B3B3"),
    POSITIVE = Color3.fromHex("#4BB543"),
    WARNING = Color3.fromHex("#FFA500"),
    DANGER = Color3.fromHex("#FF4444"),
    RELAXED = Color3.fromHex("#4BB543"),
    FOCUSED = Color3.fromHex("#4A9DFF"),
    STRESSED = Color3.fromHex("#FFA500"),
    BURNOUT = Color3.fromHex("#FF4444"),
}

local FONTS = {
    TITLE = Enum.Font.GothamBold,
    SUBTITLE = Enum.Font.GothamMedium,
    BODY = Enum.Font.Gotham,
}

local STRESS_TIERS = {
    {Max = 30, Name = "Relaxed", Color = COLORS.RELAXED, Emoji = "😌"},
    {Max = 60, Name = "Focused", Color = COLORS.FOCUSED, Emoji = "🎯"},
    {Max = 80, Name = "Stressed", Color = COLORS.STRESSED, Emoji = "😰"},
    {Max = 100, Name = "Burnout Risk", Color = COLORS.BURNOUT, Emoji = "🔥"},
}

local function getStressTier(stress)
    for _, tier in ipairs(STRESS_TIERS) do
        if stress <= tier.Max then return tier end
    end
    return STRESS_TIERS[4]
end

function StressMenu.new(parentGui, resultPopup)
    local self = setmetatable({}, StressMenu)
    self.ResultPopup = resultPopup
    self.ActionCards = {}

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "StressMenuFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = COLORS.PANEL
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = parentGui
    self.MainFrame = mainFrame
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 20)

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundTransparency = 1
    header.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Text = "🧠 STRESS MANAGEMENT"
    title.Font = FONTS.TITLE
    title.TextSize = 24
    title.TextColor3 = COLORS.TEXT_PRIMARY
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.BackgroundTransparency = 1
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Text = "Take care of yourself to stay productive."
    subtitle.Font = FONTS.BODY
    subtitle.TextSize = 14
    subtitle.TextColor3 = COLORS.TEXT_SECONDARY
    subtitle.Size = UDim2.new(1, 0, 0, 20)
    subtitle.Position = UDim2.new(0, 0, 0, 45)
    subtitle.TextXAlignment = Enum.TextXAlignment.Center
    subtitle.BackgroundTransparency = 1
    subtitle.Parent = header

    local backBtn = Instance.new("TextButton")
    backBtn.Name = "BackButton"
    backBtn.Text = "< BACK"
    backBtn.Font = FONTS.SUBTITLE
    backBtn.TextSize = 14
    backBtn.TextColor3 = COLORS.ACCENT_NEON
    backBtn.Size = UDim2.new(0, 80, 0, 30)
    backBtn.Position = UDim2.new(0, 20, 0, 25)
    backBtn.BackgroundTransparency = 1
    backBtn.Parent = header
    self.BackButton = backBtn

    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -40, 1, -100)
    content.Position = UDim2.new(0, 20, 0, 90)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame

    -- Stress Meter (top)
    local meterFrame = Instance.new("Frame")
    meterFrame.Size = UDim2.new(1, 0, 0, 80)
    meterFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    meterFrame.Parent = content
    Instance.new("UICorner", meterFrame).CornerRadius = UDim.new(0, 12)

    local meterPadding = Instance.new("UIPadding")
    meterPadding.PaddingLeft = UDim.new(0, 20)
    meterPadding.PaddingRight = UDim.new(0, 20)
    meterPadding.Parent = meterFrame

    local stressTitle = Instance.new("TextLabel")
    stressTitle.Text = "Current Stress Level"
    stressTitle.Font = FONTS.SUBTITLE
    stressTitle.TextSize = 14
    stressTitle.TextColor3 = COLORS.TEXT_SECONDARY
    stressTitle.Size = UDim2.new(0.5, 0, 0, 20)
    stressTitle.Position = UDim2.new(0, 0, 0, 10)
    stressTitle.TextXAlignment = Enum.TextXAlignment.Left
    stressTitle.BackgroundTransparency = 1
    stressTitle.Parent = meterFrame

    local stressValueLabel = Instance.new("TextLabel")
    stressValueLabel.Name = "StressValue"
    stressValueLabel.Text = "10 / 100"
    stressValueLabel.Font = FONTS.TITLE
    stressValueLabel.TextSize = 18
    stressValueLabel.TextColor3 = COLORS.RELAXED
    stressValueLabel.Size = UDim2.new(0.5, 0, 0, 20)
    stressValueLabel.Position = UDim2.new(0.5, 0, 0, 10)
    stressValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    stressValueLabel.BackgroundTransparency = 1
    stressValueLabel.Parent = meterFrame
    self.StressValueLabel = stressValueLabel

    local tierLabel = Instance.new("TextLabel")
    tierLabel.Name = "TierLabel"
    tierLabel.Text = "😌 Relaxed"
    tierLabel.Font = FONTS.SUBTITLE
    tierLabel.TextSize = 14
    tierLabel.TextColor3 = COLORS.RELAXED
    tierLabel.Size = UDim2.new(1, 0, 0, 20)
    tierLabel.Position = UDim2.new(0, 0, 0, 30)
    tierLabel.TextXAlignment = Enum.TextXAlignment.Left
    tierLabel.BackgroundTransparency = 1
    tierLabel.Parent = meterFrame
    self.TierLabel = tierLabel

    -- Stress bar
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, 0, 0, 8)
    barBg.Position = UDim2.new(0, 0, 0, 58)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    barBg.Parent = meterFrame
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.Size = UDim2.new(0.1, 0, 1, 0)
    barFill.BackgroundColor3 = COLORS.RELAXED
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
    self.BarFill = barFill

    -- Action Cards
    local cardsFrame = Instance.new("Frame")
    cardsFrame.Size = UDim2.new(1, 0, 1, -100)
    cardsFrame.Position = UDim2.new(0, 0, 0, 95)
    cardsFrame.BackgroundTransparency = 1
    cardsFrame.Parent = content

    local cardList = Instance.new("UIListLayout")
    cardList.Padding = UDim.new(0, 12)
    cardList.SortOrder = Enum.SortOrder.LayoutOrder
    cardList.Parent = cardsFrame

    self:CreateActionCard(cardsFrame, {
        LayoutOrder = 1,
        ActionId = "StudioRest",
        Title = "😴 Rest",
        Desc = "Take a short break. Free but gentle.",
        Cost = "Free",
        StressReduction = "-15 Stress",
        Cooldown = "1 min cooldown",
        Color = COLORS.POSITIVE,
    })

    self:CreateActionCard(cardsFrame, {
        LayoutOrder = 2,
        ActionId = "StudioVacation",
        Title = "✈️ Vacation",
        Desc = "Escape the grind and come back fresh.",
        Cost = "$500",
        StressReduction = "-40 Stress",
        Cooldown = "5 min cooldown",
        Color = COLORS.WARNING,
    })

    self:CreateActionCard(cardsFrame, {
        LayoutOrder = 3,
        ActionId = "StudioBreak",
        Title = "🏖️ Take a Break",
        Desc = "Step away completely. Maximum recovery.",
        Cost = "Free",
        StressReduction = "-60 Stress",
        Cooldown = "10 min cooldown",
        Color = COLORS.DANGER,
    })
    
    RunService.Heartbeat:Connect(function()
        if not self.MainFrame.Visible then return end
        if not self.ActionCards then return end
        
        for _, card in ipairs(self.ActionCards) do
            local state, reason = ArtistSystem.GetActionState(card.ActionId)
            if state == "COOLDOWN" then
                card.StatusLabel.Text = reason
                card.StatusLabel.TextColor3 = COLORS.WARNING
                card.Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            elseif state == "LOCKED" then
                card.StatusLabel.Text = reason
                card.StatusLabel.TextColor3 = COLORS.DANGER
                card.Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            else
                card.StatusLabel.Text = card.ConfigCooldown
                card.StatusLabel.TextColor3 = COLORS.TEXT_SECONDARY
                card.Button.BackgroundColor3 = card.Color
            end
        end
    end)

    return self
end

function StressMenu:CreateActionCard(parent, config)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 70)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    card.LayoutOrder = config.LayoutOrder
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = config.Color
    stroke.Transparency = 0.7
    stroke.Parent = card

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = config.Title
    titleLabel.Font = FONTS.TITLE
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = COLORS.TEXT_PRIMARY
    titleLabel.Size = UDim2.new(0.4, 0, 0, 25)
    titleLabel.Position = UDim2.new(0, 15, 0, 10)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = card

    local descLabel = Instance.new("TextLabel")
    descLabel.Text = config.Desc
    descLabel.Font = FONTS.BODY
    descLabel.TextSize = 11
    descLabel.TextColor3 = COLORS.TEXT_SECONDARY
    descLabel.Size = UDim2.new(0.5, 0, 0, 15)
    descLabel.Position = UDim2.new(0, 15, 0, 35)
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.BackgroundTransparency = 1
    descLabel.Parent = card

    local stressLabel = Instance.new("TextLabel")
    stressLabel.Text = config.StressReduction
    stressLabel.Font = FONTS.TITLE
    stressLabel.TextSize = 14
    stressLabel.TextColor3 = config.Color
    stressLabel.Size = UDim2.new(0.15, 0, 0, 20)
    stressLabel.Position = UDim2.new(0.5, 0, 0, 12)
    stressLabel.TextXAlignment = Enum.TextXAlignment.Center
    stressLabel.BackgroundTransparency = 1
    stressLabel.Parent = card

    local costLabel = Instance.new("TextLabel")
    costLabel.Text = config.Cost
    costLabel.Font = FONTS.SUBTITLE
    costLabel.TextSize = 12
    costLabel.TextColor3 = COLORS.TEXT_SECONDARY
    costLabel.Size = UDim2.new(0.15, 0, 0, 15)
    costLabel.Position = UDim2.new(0.5, 0, 0, 35)
    costLabel.TextXAlignment = Enum.TextXAlignment.Center
    costLabel.BackgroundTransparency = 1
    costLabel.Parent = card

    local actionBtn = Instance.new("TextButton")
    actionBtn.Name = config.ActionId
    actionBtn.Text = "USE"
    actionBtn.Font = FONTS.TITLE
    actionBtn.TextSize = 14
    actionBtn.TextColor3 = COLORS.TEXT_PRIMARY
    actionBtn.BackgroundColor3 = config.Color
    actionBtn.Size = UDim2.new(0, 80, 0, 35)
    actionBtn.Position = UDim2.new(1, -95, 0.5, 0)
    actionBtn.AnchorPoint = Vector2.new(0, 0.5)
    actionBtn.AutoButtonColor = false
    actionBtn.Parent = card
    Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 8)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Text = config.Cooldown
    statusLabel.Font = FONTS.BODY
    statusLabel.TextSize = 10
    statusLabel.TextColor3 = COLORS.TEXT_SECONDARY
    statusLabel.Size = UDim2.new(0, 80, 0, 12)
    statusLabel.Position = UDim2.new(1, -95, 1, -15)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.BackgroundTransparency = 1
    statusLabel.Parent = card
    
    table.insert(self.ActionCards, {
        ActionId = config.ActionId,
        Button = actionBtn,
        StatusLabel = statusLabel,
        Color = config.Color,
        ConfigCooldown = config.Cooldown
    })

    actionBtn.MouseButton1Click:Connect(function()
        local currentState, reason = ArtistSystem.GetActionState(config.ActionId)
        if currentState ~= "READY" then return end
        
        local result = ArtistSystem.PerformAction(config.ActionId)
        if result and result.Success then
            self.ResultPopup:Show(result)
            self:UpdateStressMeter()
            if self.OnActionTriggered then self.OnActionTriggered() end
        else
            TweenService:Create(actionBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.DANGER}):Play()
            task.delay(0.3, function()
                TweenService:Create(actionBtn, TweenInfo.new(0.3), {BackgroundColor3 = config.Color}):Play()
            end)
        end
    end)
end

function StressMenu:UpdateStressMeter()
    local stress = PlayerDataManager.GetStat("Stress")
    local tier = getStressTier(stress)
    
    self.StressValueLabel.Text = math.floor(stress) .. " / 100"
    self.StressValueLabel.TextColor3 = tier.Color
    self.TierLabel.Text = tier.Emoji .. " " .. tier.Name
    self.TierLabel.TextColor3 = tier.Color
    
    local pct = math.clamp(stress / 100, 0, 1)
    TweenService:Create(self.BarFill, TweenInfo.new(0.5), {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = tier.Color
    }):Play()
end

function StressMenu:Toggle(isVisible)
    if isVisible then
        self:UpdateStressMeter()
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

return StressMenu
