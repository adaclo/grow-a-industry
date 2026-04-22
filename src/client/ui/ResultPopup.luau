local TweenService = game:GetService("TweenService")

local ResultPopup = {}
ResultPopup.__index = ResultPopup

local COLORS = {
    BACKGROUND = Color3.fromHex("#121212"),
    ACCENT = Color3.fromHex("#8A2BE2"),
    TEXT = Color3.fromHex("#FFFFFF"),
    SUBTEXT = Color3.fromHex("#B3B3B3"),
    POSITIVE = Color3.fromHex("#4BB543"),
    NEGATIVE = Color3.fromHex("#FF4444"),
    NEUTRAL = Color3.fromHex("#808080")
}

function ResultPopup.new(parentGui)
    local self = setmetatable({}, ResultPopup)
    
    -- Overlay Backdrop
    local overlay = Instance.new("Frame")
    overlay.Name = "PopupOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 1000
    overlay.Visible = false
    overlay.Parent = parentGui
    self.Overlay = overlay

    -- Main Container
    local container = Instance.new("Frame")
    container.Name = "ResultPopup"
    container.Size = UDim2.new(0, 320, 0, 200)
    container.Position = UDim2.new(0.5, -160, 0.5, -100)
    container.BackgroundColor3 = COLORS.BACKGROUND
    container.BorderSizePixel = 0
    container.ZIndex = 1001
    container.Parent = overlay
    self.Container = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = COLORS.ACCENT
    stroke.Parent = container
    self.Stroke = stroke

    -- Close Button (X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "✕"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.TextColor3 = COLORS.TEXT
    closeBtn.TextSize = 16
    closeBtn.ZIndex = 1005
    closeBtn.Parent = container
    closeBtn.MouseButton1Click:Connect(function() self:Hide() end)

    -- Content
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "ACTION RESULT"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = COLORS.TEXT
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 15)
    title.BackgroundTransparency = 1
    title.ZIndex = 1002
    title.Parent = container
    self.Title = title

    local desc = Instance.new("TextLabel")
    desc.Name = "Description"
    desc.Text = "Something happened in your industry."
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 13
    desc.TextColor3 = COLORS.SUBTEXT
    desc.Size = UDim2.new(1, -40, 0, 80)
    desc.Position = UDim2.new(0, 20, 0, 55)
    desc.TextWrapped = true
    desc.BackgroundTransparency = 1
    desc.ZIndex = 1002
    desc.Parent = container
    self.Desc = desc

    local btn = Instance.new("TextButton")
    btn.Name = "ContinueBtn"
    btn.Text = "CONTINUE"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = COLORS.TEXT
    btn.BackgroundColor3 = COLORS.ACCENT
    btn.Size = UDim2.new(0.8, 0, 0, 40)
    btn.Position = UDim2.new(0.1, 0, 1, -55)
    btn.ZIndex = 1002
    btn.Parent = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function() self:Hide() end)

    return self
end

function ResultPopup:Show(data)
    self.Title.Text = (data.Title or "RESULT"):upper()
    self.Desc.Text = data.Description or ""
    
    local typeColor = COLORS.NEUTRAL
    if data.ResultType == "Positive" then typeColor = COLORS.POSITIVE
    elseif data.ResultType == "Negative" then typeColor = COLORS.NEGATIVE end
    
    self.Stroke.Color = typeColor
    self.Title.TextColor3 = typeColor
    
    self.Overlay.Visible = true
    self.Overlay.BackgroundTransparency = 1
    self.Container.Size = UDim2.new(0, 0, 0, 0)
    self.Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    TweenService:Create(self.Overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()
    TweenService:Create(self.Container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 320, 0, 200),
        Position = UDim2.new(0.5, -160, 0.5, -100)
    }):Play()
end

function ResultPopup:Hide()
    TweenService:Create(self.Overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    local t = TweenService:Create(self.Container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    t:Play()
    t.Completed:Connect(function()
        self.Overlay.Visible = false
    end)
end

return ResultPopup
