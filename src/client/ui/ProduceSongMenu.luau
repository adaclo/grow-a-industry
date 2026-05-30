local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameSystem")
local SongSystem = require(SharedModules:WaitForChild("SongSystem"))
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local SliderUI = require(script.Parent:WaitForChild("SliderUI"))

local ProduceSongMenu = {}
ProduceSongMenu.__index = ProduceSongMenu

local COLORS = {
    BACKGROUND = Color3.fromHex("#0A0A0A"),
    PANEL = Color3.fromHex("#121212"),
    ACCENT = Color3.fromHex("#8A2BE2"),
    ACCENT_NEON = Color3.fromHex("#BF40BF"),
    TEXT_PRIMARY = Color3.fromHex("#FFFFFF"),
    TEXT_SECONDARY = Color3.fromHex("#B3B3B3"),
    MONEY = Color3.fromHex("#4BB543"),
    STRESS = Color3.fromHex("#FF4444")
}

local FONTS = {
    TITLE = Enum.Font.GothamBold,
    SUBTITLE = Enum.Font.GothamMedium,
    BODY = Enum.Font.Gotham,
}

local GENRES = {"Pop", "Trap", "Electronic", "Indie", "Hyperpop", "Rock"}

function ProduceSongMenu.new(parentGui, resultPopup)
    local self = setmetatable({}, ProduceSongMenu)
    self.ResultPopup = resultPopup
    
    self.CurrentSliders = {
        Commercial = 0.5,
        Budget = 0.1,
        Promotion = 0.1,
        Originality = 0.5
    }
    self.SelectedGenre = "Pop"

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "ProduceSongFrame"
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
    title.Text = "🎵 PRODUCE SONG"
    title.Font = FONTS.TITLE
    title.TextSize = 24
    title.TextColor3 = COLORS.TEXT_PRIMARY
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.BackgroundTransparency = 1
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Text = "Shape your sound. Plan your release."
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
    content.Size = UDim2.new(1, -40, 1, -120)
    content.Position = UDim2.new(0, 20, 0, 90)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame

    -- Left Column: Sliders
    local leftCol = Instance.new("ScrollingFrame")
    leftCol.Size = UDim2.new(0.55, 0, 1, 0)
    leftCol.BackgroundTransparency = 1
    leftCol.BorderSizePixel = 0
    leftCol.ScrollBarThickness = 4
    leftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
    leftCol.CanvasSize = UDim2.new(0, 0, 0, 0)
    leftCol.ScrollingDirection = Enum.ScrollingDirection.Y
    leftCol.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    leftCol.Parent = content
    
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 12)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = leftCol

    local function createSectionHeader(num, titleStr, subtitleStr, order)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 40)
        frame.BackgroundTransparency = 1
        frame.LayoutOrder = order
        frame.Parent = leftCol

        local circle = Instance.new("Frame")
        circle.Size = UDim2.new(0, 24, 0, 24)
        circle.Position = UDim2.new(0, 0, 0, 0)
        circle.BackgroundColor3 = COLORS.ACCENT
        circle.Parent = frame
        Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

        local numLabel = Instance.new("TextLabel")
        numLabel.Text = num
        numLabel.Font = FONTS.TITLE
        numLabel.TextSize = 14
        numLabel.TextColor3 = COLORS.TEXT_PRIMARY
        numLabel.Size = UDim2.new(1, 0, 1, 0)
        numLabel.BackgroundTransparency = 1
        numLabel.Parent = circle

        local tLabel = Instance.new("TextLabel")
        tLabel.Text = titleStr
        tLabel.Font = FONTS.TITLE
        tLabel.TextSize = 14
        tLabel.TextColor3 = COLORS.TEXT_PRIMARY
        tLabel.Size = UDim2.new(1, -34, 0, 16)
        tLabel.Position = UDim2.new(0, 34, 0, 0)
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.BackgroundTransparency = 1
        tLabel.Parent = frame

        local sLabel = Instance.new("TextLabel")
        sLabel.Text = subtitleStr
        sLabel.Font = FONTS.BODY
        sLabel.TextSize = 11
        sLabel.TextColor3 = COLORS.TEXT_SECONDARY
        sLabel.Size = UDim2.new(1, -34, 0, 14)
        sLabel.Position = UDim2.new(0, 34, 0, 16)
        sLabel.TextXAlignment = Enum.TextXAlignment.Left
        sLabel.BackgroundTransparency = 1
        sLabel.Parent = frame
    end

    createSectionHeader("1", "SONG DIRECTION", "Choose the vibe of your track", 1)

    local function setupSlider(title, key, order)
        local slider = SliderUI.new(leftCol, title, self.CurrentSliders[key])
        slider.Instance.LayoutOrder = order
        slider.OnChanged = function(val)
            self.CurrentSliders[key] = val
            self:UpdateEstimates()
        end
        return slider
    end

    setupSlider("Commercial vs Experimental", "Commercial", 2)
    setupSlider("Creative Originality", "Originality", 3)

    local spacer1 = Instance.new("Frame")
    spacer1.Size = UDim2.new(1, 0, 0, 5)
    spacer1.BackgroundTransparency = 1
    spacer1.LayoutOrder = 4
    spacer1.Parent = leftCol

    createSectionHeader("2", "GENRE", "Pick the main genre of your track", 5)

    local genreContainer = Instance.new("Frame")
    genreContainer.Size = UDim2.new(1, 0, 0, 70)
    genreContainer.BackgroundTransparency = 1
    genreContainer.LayoutOrder = 6
    genreContainer.Parent = leftCol

    local gList = Instance.new("UIGridLayout")
    gList.CellSize = UDim2.new(0.31, 0, 0, 30)
    gList.CellPadding = UDim2.new(0, 8, 0, 8)
    gList.SortOrder = Enum.SortOrder.LayoutOrder
    gList.Parent = genreContainer

    local genreOrder = 1
    for _, genre in pairs(GENRES) do
        local gBtn = Instance.new("TextButton")
        gBtn.Text = genre
        gBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        gBtn.TextColor3 = COLORS.TEXT_SECONDARY
        gBtn.Font = FONTS.BODY
        gBtn.TextSize = 11
        gBtn.LayoutOrder = genreOrder
        gBtn.Parent = genreContainer
        Instance.new("UICorner").Parent = gBtn
        genreOrder = genreOrder + 1
        
        local gStroke = Instance.new("UIStroke")
        gStroke.Thickness = 1
        gStroke.Color = COLORS.ACCENT
        gStroke.Transparency = 1
        gStroke.Parent = gBtn

        gBtn.MouseButton1Click:Connect(function()
            self.SelectedGenre = genre
            for _, child in pairs(genreContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                    child.UIStroke.Transparency = 1
                end
            end
            gBtn.BackgroundColor3 = COLORS.ACCENT
            gStroke.Transparency = 0
            self:UpdateEstimates()
        end)
        
        if genre == "Pop" then
            gBtn.BackgroundColor3 = COLORS.ACCENT
            gStroke.Transparency = 0
        end
    end

    local spacer2 = Instance.new("Frame")
    spacer2.Size = UDim2.new(1, 0, 0, 5)
    spacer2.BackgroundTransparency = 1
    spacer2.LayoutOrder = 7
    spacer2.Parent = leftCol

    createSectionHeader("3", "EXTRAS (OPTIONAL)", "Tune your promotion and budget", 8)
    
    setupSlider("Marketing Promotion", "Promotion", 9)
    setupSlider("Production Budget", "Budget", 10)

    local tipBox = Instance.new("Frame")
    tipBox.Size = UDim2.new(1, 0, 0, 30)
    tipBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tipBox.LayoutOrder = 11
    tipBox.Parent = leftCol
    Instance.new("UICorner", tipBox).CornerRadius = UDim.new(0, 8)

    local tipLabel = Instance.new("TextLabel")
    tipLabel.Text = "💡 TIP: Higher originality can bring loyal fans but increases risk."
    tipLabel.Font = FONTS.BODY
    tipLabel.TextSize = 11
    tipLabel.TextColor3 = COLORS.TEXT_SECONDARY
    tipLabel.Size = UDim2.new(1, -20, 1, 0)
    tipLabel.Position = UDim2.new(0, 10, 0, 0)
    tipLabel.TextXAlignment = Enum.TextXAlignment.Left
    tipLabel.BackgroundTransparency = 1
    tipLabel.Parent = tipBox

    -- Right Column: Estimates & Stats
    local rightCol = Instance.new("Frame")
    rightCol.Size = UDim2.new(0.4, 0, 1, 0)
    rightCol.Position = UDim2.new(0.6, 0, 0, 0)
    rightCol.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    rightCol.Parent = content
    
    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 15)
    rCorner.Parent = rightCol

    local rPadding = Instance.new("UIPadding")
    rPadding.PaddingTop = UDim.new(0, 20)
    rPadding.PaddingBottom = UDim.new(0, 20)
    rPadding.PaddingLeft = UDim.new(0, 20)
    rPadding.PaddingRight = UDim.new(0, 20)
    rPadding.Parent = rightCol

    local rList = Instance.new("UIListLayout")
    rList.Padding = UDim.new(0, 5)
    rList.SortOrder = Enum.SortOrder.LayoutOrder
    rList.Parent = rightCol

    local estTitle = Instance.new("TextLabel")
    estTitle.Text = "📊 RELEASE ESTIMATE"
    estTitle.Font = FONTS.SUBTITLE
    estTitle.TextSize = 16
    estTitle.TextColor3 = COLORS.TEXT_PRIMARY
    estTitle.Size = UDim2.new(1, 0, 0, 20)
    estTitle.TextXAlignment = Enum.TextXAlignment.Center
    estTitle.BackgroundTransparency = 1
    estTitle.LayoutOrder = 1
    estTitle.Parent = rightCol

    local estSubtitle = Instance.new("TextLabel")
    estSubtitle.Text = "Preview the expected outcome"
    estSubtitle.Font = FONTS.BODY
    estSubtitle.TextSize = 11
    estSubtitle.TextColor3 = COLORS.TEXT_SECONDARY
    estSubtitle.Size = UDim2.new(1, 0, 0, 15)
    estSubtitle.TextXAlignment = Enum.TextXAlignment.Center
    estSubtitle.BackgroundTransparency = 1
    estSubtitle.LayoutOrder = 2
    estSubtitle.Parent = rightCol

    local estSpacer = Instance.new("Frame")
    estSpacer.Size = UDim2.new(1, 0, 0, 15)
    estSpacer.BackgroundTransparency = 1
    estSpacer.LayoutOrder = 3
    estSpacer.Parent = rightCol

    self.EstimateLabels = {}
    local function createEst(name, color, order)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 35)
        frame.BackgroundTransparency = 1
        frame.LayoutOrder = order
        frame.Parent = rightCol
        
        local n = Instance.new("TextLabel")
        n.Text = name
        n.Font = FONTS.BODY
        n.TextSize = 14
        n.TextColor3 = COLORS.TEXT_SECONDARY
        n.Size = UDim2.new(0.5, 0, 1, 0)
        n.TextXAlignment = Enum.TextXAlignment.Left
        n.BackgroundTransparency = 1
        n.Parent = frame
        
        local v = Instance.new("TextLabel")
        v.Text = "..."
        v.Font = FONTS.TITLE
        v.TextSize = 18
        v.TextColor3 = color or COLORS.TEXT_PRIMARY
        v.Size = UDim2.new(0.5, 0, 1, 0)
        v.Position = UDim2.new(0.5, 0, 0, 0)
        v.TextXAlignment = Enum.TextXAlignment.Right
        v.BackgroundTransparency = 1
        v.Parent = frame
        
        self.EstimateLabels[name] = v
    end

    createEst("💰 Total Cost", COLORS.MONEY, 4)
    createEst("💖 Stress Impact", COLORS.STRESS, 5)
    createEst("⚠️ Market Risk", Color3.new(1, 0.6, 0), 6)
    createEst("⭐ Hit Potential", Color3.new(0.4, 0.8, 1), 7)

    -- Release Button (Spaced at the bottom)
    local btnSpacer = Instance.new("Frame")
    btnSpacer.Size = UDim2.new(1, 0, 0, 20)
    btnSpacer.BackgroundTransparency = 1
    btnSpacer.LayoutOrder = 8
    btnSpacer.Parent = rightCol

    local releaseBtn = Instance.new("TextButton")
    releaseBtn.Name = "ReleaseButton"
    releaseBtn.Size = UDim2.new(1, 0, 0, 55)
    releaseBtn.Position = UDim2.new(0, 0, 0.8, 0)
    releaseBtn.BackgroundColor3 = COLORS.ACCENT
    releaseBtn.Font = FONTS.TITLE
    releaseBtn.TextSize = 22
    releaseBtn.TextColor3 = COLORS.TEXT_PRIMARY
    releaseBtn.Text = "🎵 RELEASE TRACK"
    releaseBtn.AutoButtonColor = false
    releaseBtn.LayoutOrder = 9
    releaseBtn.Parent = rightCol

    local warningLabel = Instance.new("TextLabel")
    warningLabel.Text = "🛡️ You can't undo this action"
    warningLabel.Font = FONTS.BODY
    warningLabel.TextSize = 10
    warningLabel.TextColor3 = COLORS.TEXT_SECONDARY
    warningLabel.Size = UDim2.new(1, 0, 0, 20)
    warningLabel.TextXAlignment = Enum.TextXAlignment.Center
    warningLabel.BackgroundTransparency = 1
    warningLabel.LayoutOrder = 10
    warningLabel.Parent = rightCol

    Instance.new("UICorner").CornerRadius = UDim.new(0, 12)
    Instance.new("UICorner").Parent = releaseBtn
    
    releaseBtn.MouseButton1Click:Connect(function()
        local result = SongSystem.ReleaseSong(self.CurrentSliders, self.SelectedGenre)
        if result and result.Success then
            -- Note: We DON'T close the menu anymore as per request
            self.ResultPopup:Show(result)
            self:UpdateEstimates()
            if self.OnActionTriggered then self.OnActionTriggered() end
        else
            -- Feedback for error
            TweenService:Create(releaseBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.STRESS}):Play()
            task.delay(0.2, function()
                TweenService:Create(releaseBtn, TweenInfo.new(0.3), {BackgroundColor3 = COLORS.ACCENT}):Play()
            end)
        end
    end)

    self:UpdateEstimates()

    return self
end

function ProduceSongMenu:UpdateEstimates()
    local est = SongSystem.CalculateEstimate(self.CurrentSliders)
    self.EstimateLabels["💰 Total Cost"].Text = "$" .. math.floor(est.Cost)
    self.EstimateLabels["💖 Stress Impact"].Text = "+" .. math.floor(est.Stress)
    
    local riskText = "Low"
    if est.Risk > 60 then riskText = "Extreme"
    elseif est.Risk > 40 then riskText = "High"
    elseif est.Risk > 20 then riskText = "Medium" end
    self.EstimateLabels["⚠️ Market Risk"].Text = riskText
    
    local potText = "Standard"
    if est.RewardPotential > 80 then potText = "Massive"
    elseif est.RewardPotential > 50 then potText = "High"
    elseif est.RewardPotential > 25 then potText = "Promising" end
    self.EstimateLabels["⭐ Hit Potential"].Text = potText
end

function ProduceSongMenu:Toggle(isVisible)
    if isVisible then
        self:UpdateEstimates()
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

return ProduceSongMenu
