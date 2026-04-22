local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameSystem")
local SocialMediaSystem = require(SharedModules:WaitForChild("SocialMediaSystem"))
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local SocialMediaMenu = {}
SocialMediaMenu.__index = SocialMediaMenu

local COLORS = {
    BACKGROUND = Color3.fromHex("#0A0A0A"),
    PANEL = Color3.fromHex("#121212"),
    ACCENT = Color3.fromHex("#8A2BE2"),
    ACCENT_NEON = Color3.fromHex("#BF40BF"),
    TEXT_PRIMARY = Color3.fromHex("#FFFFFF"),
    TEXT_SECONDARY = Color3.fromHex("#B3B3B3"),
    COOLDOWN = Color3.fromHex("#333333"),
    POSITIVE = Color3.fromHex("#4BB543"),
    NEGATIVE = Color3.fromHex("#FF4444")
}

local FONTS = {
    TITLE = Enum.Font.GothamBold,
    SUBTITLE = Enum.Font.GothamMedium,
    BODY = Enum.Font.Gotham,
}

local OPTIONS = {
    {Id = "YouTube", Name = "Upload Beat to YouTube", Desc = "Gain followers and monetization."},
    {Id = "TikTok", Name = "Upload TikTok Producing", Desc = "High viral potential process videos."},
    {Id = "BTS", Name = "Behind The Scenes", Desc = "Increase loyal fans and reputation."},
    {Id = "Leak", Name = "Leak Snippet", Desc = "Build hype for your next release."},
    {Id = "Twitter", Name = "Twitter Beef", Desc = "High risk, high reward drama."},
    {Id = "Promotion", Name = "Buy Promotion", Desc = "Spend money for mainstream growth."},
    {Id = "RespondHate", Name = "Respond to Hate", Desc = "Manage your image and reduce hate."}
}

function SocialMediaMenu.new(parentGui, resultPopup)
    local self = setmetatable({}, SocialMediaMenu)
    self.ResultPopup = resultPopup
    self.Buttons = {}

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "SocialMediaFrame"
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
    title.Text = "SOCIAL MEDIA"
    title.Font = FONTS.TITLE
    title.TextSize = 24
    title.TextColor3 = COLORS.TEXT_PRIMARY
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Parent = header

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

    -- Scrolling Content
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, -40, 1, -100)
    scrollingFrame.Position = UDim2.new(0, 20, 0, 80)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.ScrollBarThickness = 2
    scrollingFrame.ScrollBarImageColor3 = COLORS.ACCENT
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto-scales
    scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollingFrame.Parent = mainFrame

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 10)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.Parent = scrollingFrame

    for _, opt in pairs(OPTIONS) do
        self:CreateOptionButton(scrollingFrame, opt)
    end

    -- Update loop for cooldowns
    task.spawn(function()
        while true do
            if mainFrame.Visible then
                self:UpdateCooldowns()
            end
            task.wait(1)
        end
    end)

    return self
end

function SocialMediaMenu:CreateOptionButton(parent, opt)
    local btnFrame = Instance.new("Frame")
    btnFrame.Name = opt.Id .. "Button"
    btnFrame.Size = UDim2.new(0.95, 0, 0, 70)
    btnFrame.BackgroundColor3 = COLORS.BACKGROUND
    btnFrame.BorderSizePixel = 0
    btnFrame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btnFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = COLORS.ACCENT
    stroke.Transparency = 0.8
    stroke.Parent = btnFrame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = btnFrame

    local title = Instance.new("TextLabel")
    title.Text = opt.Name:upper()
    title.Font = FONTS.TITLE
    title.TextSize = 14
    title.TextColor3 = COLORS.TEXT_PRIMARY
    title.Size = UDim2.new(0.7, 0, 0, 25)
    title.Position = UDim2.new(0, 15, 0, 12)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.Parent = btnFrame

    local desc = Instance.new("TextLabel")
    desc.Text = opt.Desc
    desc.Font = FONTS.BODY
    desc.TextSize = 11
    desc.TextColor3 = COLORS.TEXT_SECONDARY
    desc.Size = UDim2.new(0.7, 0, 0, 20)
    desc.Position = UDim2.new(0, 15, 0, 37)
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.BackgroundTransparency = 1
    desc.Parent = btnFrame

    local cooldownLabel = Instance.new("TextLabel")
    cooldownLabel.Name = "CooldownLabel"
    cooldownLabel.Text = ""
    cooldownLabel.Font = FONTS.SUBTITLE
    cooldownLabel.TextSize = 12
    cooldownLabel.TextColor3 = COLORS.ACCENT_NEON
    cooldownLabel.Size = UDim2.new(0.25, 0, 1, 0)
    cooldownLabel.Position = UDim2.new(0.75, -15, 0, 0)
    cooldownLabel.TextXAlignment = Enum.TextXAlignment.Right
    cooldownLabel.BackgroundTransparency = 1
    cooldownLabel.Parent = btnFrame

    self.Buttons[opt.Id] = {
        Frame = btnFrame,
        Button = btn,
        Stroke = stroke,
        CooldownLabel = cooldownLabel
    }

    btn.MouseEnter:Connect(function()
        if SocialMediaSystem.GetCooldown(opt.Id) <= 0 then
            TweenService:Create(btnFrame, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromHex("#1A1A1A")}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = COLORS.ACCENT_NEON, Transparency = 0}):Play()
        end
    end)

    btn.MouseLeave:Connect(function()
        if SocialMediaSystem.GetCooldown(opt.Id) <= 0 then
            TweenService:Create(btnFrame, TweenInfo.new(0.3), {BackgroundColor3 = COLORS.BACKGROUND}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = COLORS.ACCENT, Transparency = 0.8}):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        local result = SocialMediaSystem.PerformAction(opt.Id)
        if result.Success then
            self.ResultPopup:Show(result)
            self:UpdateCooldowns()
            if self.OnActionTriggered then self.OnActionTriggered() end
        else
            -- Feedback for error/cooldown
            print("Action failed: ", result.Error)
        end
    end)
end

function SocialMediaMenu:UpdateCooldowns()
    for id, data in pairs(self.Buttons) do
        local remaining = SocialMediaSystem.GetCooldown(id)
        if remaining > 0 then
            data.CooldownLabel.Text = string.format("%ds", math.ceil(remaining))
            data.Frame.BackgroundColor3 = COLORS.COOLDOWN
            data.Stroke.Transparency = 1
            data.Button.AutoButtonColor = false
        else
            data.CooldownLabel.Text = "READY"
            data.CooldownLabel.TextColor3 = COLORS.POSITIVE
            data.Frame.BackgroundColor3 = COLORS.BACKGROUND
            data.Stroke.Transparency = 0.8
            data.Button.AutoButtonColor = true
        end
    end
end

function SocialMediaMenu:Toggle(isVisible)
    if isVisible then
        self:UpdateCooldowns()
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

return SocialMediaMenu
