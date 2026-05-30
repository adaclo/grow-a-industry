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
    NEUTRAL = Color3.fromHex("#808080"),
    PANEL = Color3.fromHex("#1A1A1A")
}

function ResultPopup.new(parentGui)
    local self = setmetatable({}, ResultPopup)
    
    local overlay = Instance.new("Frame")
    overlay.Name = "PopupOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 1000
    overlay.Active = true
    overlay.Visible = false
    overlay.Parent = parentGui
    self.Overlay = overlay

    local container = Instance.new("Frame")
    container.Name = "ResultPopup"
    container.Size = UDim2.new(0, 360, 0, 450)
    container.Position = UDim2.new(0.5, -180, 0.5, -225)
    container.BackgroundColor3 = COLORS.BACKGROUND
    container.BorderSizePixel = 0
    container.ZIndex = 1001
    container.Active = true
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

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "ACTION RESULT"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = COLORS.TEXT
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.ZIndex = 1002
    title.Parent = container
    self.Title = title

    local desc = Instance.new("TextLabel")
    desc.Name = "Description"
    desc.Text = "Flavor text goes here."
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 14
    desc.TextColor3 = COLORS.SUBTEXT
    desc.Size = UDim2.new(1, -40, 0, 40)
    desc.Position = UDim2.new(0, 20, 0, 50)
    desc.TextWrapped = true
    desc.BackgroundTransparency = 1
    desc.ZIndex = 1002
    desc.Parent = container
    self.Desc = desc

    -- Scrollable content for dynamic lists
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "ContentScroll"
    scroll.Size = UDim2.new(1, -20, 1, -160)
    scroll.Position = UDim2.new(0, 10, 0, 95)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ZIndex = 1002
    scroll.Parent = container
    self.Scroll = scroll

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scroll
    self.ListLayout = listLayout

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

-- Helper to determine color based on key and value
local function getColorForStat(key, value)
    if value == 0 then return COLORS.NEUTRAL end
    
    -- Special rules
    if key == "Stress" then
        return value > 0 and COLORS.NEGATIVE or COLORS.POSITIVE
    elseif key == "Haters" then
        return value > 0 and COLORS.NEGATIVE or COLORS.POSITIVE
    end
    
    -- Default rules
    return value > 0 and COLORS.POSITIVE or COLORS.NEGATIVE
end

local function formatKeyName(key)
    if key == "UndergroundAudience" then return "🎧 Underground Audience" end
    if key == "MainstreamAudience" then return "📻 Mainstream Audience" end
    if key == "CasualListeners" then return "🎧 Casual Listeners" end
    if key == "LoyalFans" then return "🤝 Loyal Fans" end
    if key == "Money" then return "💰 Money" end
    if key == "Fame" then return "⭐ Fame" end
    if key == "Followers" then return "👥 Followers" end
    if key == "Reputation" then return "🎭 Reputation" end
    if key == "Stress" then return "⚠️ Stress" end
    if key == "Hype" then return "🔥 Hype" end
    if key == "Haters" then return "😡 Haters" end
    return key
end

local function formatValue(key, value)
    local roundedValue = math.floor(value + 0.5)
    local sign = roundedValue >= 0 and "+" or ""
    if key == "Money" then
        return sign .. "$" .. tostring(math.abs(roundedValue))
    end
    return sign .. tostring(roundedValue)
end

function ResultPopup:CreateRow(parent, labelText, valueText, valueColor, layoutOrder)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 30)
    row.BackgroundTransparency = 1
    row.LayoutOrder = layoutOrder
    row.ZIndex = 1003
    row.Parent = parent
    
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Text = labelText
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.TextColor3 = COLORS.SUBTEXT
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    lbl.ZIndex = 1003
    lbl.Parent = row

    local val = Instance.new("TextLabel")
    val.Text = valueText
    val.Font = Enum.Font.GothamBold
    val.TextSize = 14
    val.TextColor3 = valueColor
    val.Size = UDim2.new(0.4, -10, 1, 0)
    val.Position = UDim2.new(0.6, 0, 0, 0)
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.BackgroundTransparency = 1
    val.ZIndex = 1003
    val.Parent = row
end

function ResultPopup:CreateSectionHeader(parent, text, layoutOrder)
    local lbl = Instance.new("TextLabel")
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = COLORS.TEXT
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    lbl.LayoutOrder = layoutOrder
    lbl.ZIndex = 1003
    lbl.Parent = parent
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -10, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -2)
    line.BackgroundColor3 = COLORS.SUBTEXT
    line.BackgroundTransparency = 0.5
    line.BorderSizePixel = 0
    line.ZIndex = 1003
    line.Parent = lbl
end

function ResultPopup:CreateSpecialEvent(parent, text, layoutOrder)
    local lbl = Instance.new("TextLabel")
    lbl.Text = "• " .. text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextColor3 = COLORS.ACCENT
    lbl.Size = UDim2.new(1, -10, 0, 25)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    lbl.LayoutOrder = layoutOrder
    lbl.ZIndex = 1003
    lbl.Parent = parent
end

function ResultPopup:Show(data)
    print("[ResultPopup] Payload received")
    print("[ResultPopup] Title:", data.Title)
    print("[ResultPopup] StatChanges:", data.StatChanges and "YES" or "NIL")
    print("[ResultPopup] CommunityChanges:", data.CommunityChanges and "YES" or "NIL")
    print("[ResultPopup] SpecialEvents:", data.SpecialEvents and ("YES (" .. #data.SpecialEvents .. ")") or "NIL")

    self.Title.Text = (data.Title or "RESULT"):upper()
    self.Desc.Text = data.Description or ""
    
    local typeColor = COLORS.NEUTRAL
    if data.ResultType == "Positive" then typeColor = COLORS.POSITIVE
    elseif data.ResultType == "Negative" then typeColor = COLORS.NEGATIVE end
    
    self.Stroke.Color = typeColor
    self.Title.TextColor3 = typeColor

    -- Clear scroll content
    for _, child in pairs(self.Scroll:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end

    local order = 0
    local statRowCount = 0
    local communityRowCount = 0
    local specialRowCount = 0

    local numElements = 0
    local sumHeights = 0

    if data.StatChanges then
        local count = 0
        for k, v in pairs(data.StatChanges) do count = count + 1 end
        if count > 0 then
            order = order + 1
            numElements = numElements + 1
            sumHeights = sumHeights + 20
            self:CreateSectionHeader(self.Scroll, "STATS CHANGED", order)
            for k, v in pairs(data.StatChanges) do
                order = order + 1
                statRowCount = statRowCount + 1
                numElements = numElements + 1
                sumHeights = sumHeights + 30
                self:CreateRow(self.Scroll, formatKeyName(k), formatValue(k, v), getColorForStat(k, v), order)
            end
        end
    end

    if data.CommunityChanges then
        local count = 0
        for k, v in pairs(data.CommunityChanges) do count = count + 1 end
        if count > 0 then
            order = order + 1
            numElements = numElements + 1
            sumHeights = sumHeights + 20
            self:CreateSectionHeader(self.Scroll, "AUDIENCE CHANGED", order)
            for k, v in pairs(data.CommunityChanges) do
                order = order + 1
                communityRowCount = communityRowCount + 1
                numElements = numElements + 1
                sumHeights = sumHeights + 30
                self:CreateRow(self.Scroll, formatKeyName(k), formatValue(k, v), getColorForStat(k, v), order)
            end
        end
    end

    if data.SpecialEvents and #data.SpecialEvents > 0 then
        order = order + 1
        numElements = numElements + 1
        sumHeights = sumHeights + 20
        self:CreateSectionHeader(self.Scroll, "CONSEQUENCES", order)
        for _, evt in ipairs(data.SpecialEvents) do
            order = order + 1
            specialRowCount = specialRowCount + 1
            numElements = numElements + 1
            sumHeights = sumHeights + 25
            self:CreateSpecialEvent(self.Scroll, evt, order)
        end
    end

    print(string.format("[ResultPopup] Stat rows created: %d", statRowCount))
    print(string.format("[ResultPopup] Community rows created: %d", communityRowCount))
    print(string.format("[ResultPopup] Special rows created: %d", specialRowCount))

    local contentHeight = sumHeights + math.max(0, (numElements - 1) * 10)
    local targetHeight = 160 -- Base size for Title, Desc, and Button
    if contentHeight > 0 then
        targetHeight = math.clamp(160 + contentHeight + 20, 160, 450)
    end
    local targetY = -(targetHeight / 2)

    -- Update scroll canvas size
    self.Scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 20)
    
    if self.LayoutConnection then self.LayoutConnection:Disconnect() end
    self.LayoutConnection = self.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.Scroll.CanvasSize = UDim2.new(0, 0, 0, self.ListLayout.AbsoluteContentSize.Y + 20)
    end)
    
    self.Overlay.Visible = true
    self.Overlay.BackgroundTransparency = 1
    self.Container.Size = UDim2.new(0, 0, 0, 0)
    self.Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    TweenService:Create(self.Overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()
    TweenService:Create(self.Container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 360, 0, targetHeight),
        Position = UDim2.new(0.5, -180, 0.5, targetY)
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
