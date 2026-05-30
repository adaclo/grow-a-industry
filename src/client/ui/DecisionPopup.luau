local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local DecisionPopup = {}
DecisionPopup.__index = DecisionPopup

local COLORS = {
    BACKGROUND = Color3.fromHex("#0F0F0F"),
    ACCENT = Color3.fromHex("#8A2BE2"),
    TEXT = Color3.fromHex("#FFFFFF"),
    SUBTEXT = Color3.fromHex("#B3B3B3"),
    POSITIVE = Color3.fromHex("#4BB543"),
    NEGATIVE = Color3.fromHex("#FF4444"),
    RISK = Color3.fromHex("#FFA500")
}

function DecisionPopup.new(parentGui)
    local self = setmetatable({}, DecisionPopup)
    
    -- Overlay Backdrop (Should block clicks)
    local overlay = Instance.new("TextButton")
    overlay.Name = "DecisionOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 5000
    overlay.Visible = false
    overlay.Text = ""
    overlay.AutoButtonColor = false
    overlay.Parent = parentGui
    self.Overlay = overlay

    -- Main Container
    local container = Instance.new("Frame")
    container.Name = "DecisionBox"
    container.Size = UDim2.new(0, 420, 0, 320)
    container.Position = UDim2.new(0.5, -210, 0.5, -160)
    container.BackgroundColor3 = COLORS.BACKGROUND
    container.BorderSizePixel = 0
    container.ZIndex = 5001
    container.Parent = overlay
    self.Container = container

    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 15)
    local stroke = Instance.new("UIStroke", container)
    stroke.Thickness = 3
    stroke.Color = COLORS.ACCENT
    self.Stroke = stroke

    -- Header
    local title = Instance.new("TextLabel")
    title.Text = "URGENT EVENT"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = COLORS.TEXT
    title.Size = UDim2.new(1, 0, 0, 60)
    title.BackgroundTransparency = 1
    title.ZIndex = 5002
    title.Parent = container
    self.Title = title

    -- Description
    local desc = Instance.new("TextLabel")
    desc.Text = "Something important is happening that requires your immediate decision."
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 14
    desc.TextColor3 = COLORS.SUBTEXT
    desc.Size = UDim2.new(1, -60, 0, 80)
    desc.Position = UDim2.new(0, 30, 0, 60)
    desc.TextWrapped = true
    desc.BackgroundTransparency = 1
    desc.ZIndex = 5002
    desc.Parent = container
    self.Desc = desc

    -- Options Container
    local optionsList = Instance.new("Frame")
    optionsList.Name = "Options"
    optionsList.Size = UDim2.new(1, -60, 0, 140)
    optionsList.Position = UDim2.new(0, 30, 1, -150)
    optionsList.BackgroundTransparency = 1
    optionsList.ZIndex = 5002
    optionsList.Parent = container
    self.OptionsList = optionsList

    local layout = Instance.new("UIListLayout", optionsList)
    layout.Padding = UDim.new(0, 12)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center

    return self
end

function DecisionPopup:Show(event, onDecision)
    self.Title.Text = event.Title:upper()
    self.Desc.Text = event.Description
    
    -- Clear old options
    for _, child in pairs(self.OptionsList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    -- Create new options
    for i, opt in ipairs(event.Options) do
        local btn = Instance.new("TextButton")
        btn.Text = opt.Text:upper()
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextColor3 = COLORS.TEXT
        btn.BackgroundColor3 = COLORS.ACCENT
        btn.Size = UDim2.new(1, 0, 0, 40)
        btn.ZIndex = 5005
        btn.Parent = self.OptionsList
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        if opt.Expected and #opt.Expected > 0 then
            -- Expand the button to fit expected text
            btn.Size = UDim2.new(1, 0, 0, 55)
            btn.TextYAlignment = Enum.TextYAlignment.Top
            local pad = Instance.new("UIPadding", btn)
            pad.PaddingTop = UDim.new(0, 8)
            
            local expectedFrame = Instance.new("Frame")
            expectedFrame.Size = UDim2.new(1, 0, 0, 20)
            expectedFrame.Position = UDim2.new(0, 0, 1, -25)
            expectedFrame.BackgroundTransparency = 1
            expectedFrame.Parent = btn
            
            local eList = Instance.new("UIListLayout", expectedFrame)
            eList.FillDirection = Enum.FillDirection.Horizontal
            eList.HorizontalAlignment = Enum.HorizontalAlignment.Center
            eList.Padding = UDim.new(0, 10)
            
            local eLabel = Instance.new("TextLabel")
            eLabel.Text = "Expected: "
            eLabel.Font = Enum.Font.GothamMedium
            eLabel.TextSize = 11
            eLabel.TextColor3 = COLORS.SUBTEXT
            eLabel.Size = UDim2.new(0, 0, 1, 0)
            eLabel.AutomaticSize = Enum.AutomaticSize.X
            eLabel.BackgroundTransparency = 1
            eLabel.Parent = expectedFrame
            
            for _, expText in ipairs(opt.Expected) do
                local t = Instance.new("TextLabel")
                t.Text = expText
                t.Font = Enum.Font.GothamBold
                t.TextSize = 11
                if string.sub(expText, 1, 1) == "+" then
                    t.TextColor3 = COLORS.POSITIVE
                elseif string.sub(expText, 1, 1) == "-" then
                    t.TextColor3 = COLORS.NEGATIVE
                else
                    t.TextColor3 = COLORS.TEXT
                end
                t.Size = UDim2.new(0, 0, 1, 0)
                t.AutomaticSize = Enum.AutomaticSize.X
                t.BackgroundTransparency = 1
                t.Parent = expectedFrame
            end
        end

        btn.MouseButton1Click:Connect(function()
            local effectResult = opt.Effect(event.Context and event.Context.artistId)
            local resultText = ""
            local payload = nil
            
            if type(effectResult) == "table" and effectResult.Title then
                -- This is a standard ResultPayload
                self:Hide()
                if onDecision then onDecision(effectResult) end
            elseif type(effectResult) == "table" then
                -- Legacy fallback
                resultText = effectResult.Description or ""
                payload = effectResult.Payload
                self:ShowResult(resultText, function()
                    if onDecision then
                        onDecision(payload)
                    end
                end)
            else
                -- Legacy fallback
                resultText = effectResult or ""
                self:ShowResult(resultText, function()
                    if onDecision then
                        onDecision(payload)
                    end
                end)
            end
        end)
    end

    self.Overlay.Visible = true
    self.Overlay.BackgroundTransparency = 1
    
    TweenService:Create(self.Overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.7}):Play()
    self.Container.Size = UDim2.new(0, 100, 0, 100)
    self.Container.Position = UDim2.new(0.5, -50, 0.5, -50)
    
    TweenService:Create(self.Container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 420, 0, 320),
        Position = UDim2.new(0.5, -210, 0.5, -160)
    }):Play()
end

function DecisionPopup:ShowResult(resultText, onDecision)
    -- Clear options and show result
    for _, child in pairs(self.OptionsList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    self.Desc.Text = resultText
    
    local okBtn = Instance.new("TextButton")
    okBtn.Text = "CONTINUE"
    okBtn.Font = Enum.Font.GothamBold
    okBtn.TextSize = 14
    okBtn.TextColor3 = COLORS.TEXT
    okBtn.BackgroundColor3 = COLORS.POSITIVE
    okBtn.Size = UDim2.new(0.6, 0, 0, 45)
    okBtn.ZIndex = 5005
    okBtn.Parent = self.OptionsList
    Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0, 8)

    okBtn.MouseButton1Click:Connect(function()
        self:Hide()
        if onDecision then onDecision() end
    end)
end

function DecisionPopup:Hide()
    TweenService:Create(self.Overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    local t = TweenService:Create(self.Container, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    t:Play()
    t.Completed:Connect(function()
        self.Overlay.Visible = false
    end)
end

return DecisionPopup
