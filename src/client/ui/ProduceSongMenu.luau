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
    title.Text = "MUSIC PRODUCTION STUDIO"
    title.Font = FONTS.TITLE
    title.TextSize = 18
    title.TextColor3 = COLORS.TEXT_PRIMARY
    title.Size = UDim2.new(0.5, 0, 1, 0)
    title.Position = UDim2.new(0.25, 0, 0, 0)
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

    local identityLabel = Instance.new("TextLabel")
    identityLabel.Name = "IdentityLabel"
    identityLabel.Text = "Current Identity: " .. SongSystem.GetArtistIdentity()
    identityLabel.Font = FONTS.BODY
    identityLabel.TextSize = 10
    identityLabel.TextColor3 = COLORS.ACCENT
    identityLabel.Size = UDim2.new(0.35, 0, 0, 30)
    identityLabel.Position = UDim2.new(1, -10, 0, 25)
    identityLabel.AnchorPoint = Vector2.new(1, 0)
    identityLabel.TextXAlignment = Enum.TextXAlignment.Right
    identityLabel.BackgroundTransparency = 1
    identityLabel.Parent = header
    self.IdentityLabel = identityLabel

    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -40, 1, -120)
    content.Position = UDim2.new(0, 20, 0, 90)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame

    -- Left Column: Sliders
    local leftCol = Instance.new("Frame")
    leftCol.Size = UDim2.new(0.55, 0, 1, 0)
    leftCol.BackgroundTransparency = 1
    leftCol.Parent = content
    
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 12)
    list.Parent = leftCol

    local function setupSlider(title, key)
        local slider = SliderUI.new(leftCol, title, self.CurrentSliders[key])
        slider.OnChanged = function(val)
            self.CurrentSliders[key] = val
            self:UpdateEstimates()
        end
        return slider
    end

    setupSlider("Commercial vs Experimental", "Commercial")
    setupSlider("Production Budget", "Budget")
    setupSlider("Marketing Promotion", "Promotion")
    setupSlider("Creative Originality", "Originality")

    -- Genre Selection (Simple Horizontal List)
    local genreLabel = Instance.new("TextLabel")
    genreLabel.Text = "GENRE SELECTION"
    genreLabel.Font = FONTS.SUBTITLE
    genreLabel.TextSize = 12
    genreLabel.TextColor3 = COLORS.TEXT_SECONDARY
    genreLabel.Size = UDim2.new(1, 0, 0, 20)
    genreLabel.TextXAlignment = Enum.TextXAlignment.Left
    genreLabel.BackgroundTransparency = 1
    genreLabel.Parent = leftCol

    local genreContainer = Instance.new("Frame")
    genreContainer.Size = UDim2.new(1, 0, 0, 40)
    genreContainer.BackgroundTransparency = 1
    genreContainer.Parent = leftCol

    local gList = Instance.new("UIListLayout")
    gList.FillDirection = Enum.FillDirection.Horizontal
    gList.Padding = UDim.new(0, 5)
    gList.Parent = genreContainer

    for _, genre in pairs(GENRES) do
        local gBtn = Instance.new("TextButton")
        gBtn.Text = genre
        gBtn.Size = UDim2.new(0, 60, 1, 0)
        gBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        gBtn.TextColor3 = COLORS.TEXT_SECONDARY
        gBtn.Font = FONTS.BODY
        gBtn.TextSize = 11
        gBtn.Parent = genreContainer
        Instance.new("UICorner").Parent = gBtn
        
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
    rList.Parent = rightCol

    local estTitle = Instance.new("TextLabel")
    estTitle.Text = "RELEASE ESTIMATES"
    estTitle.Font = FONTS.SUBTITLE
    estTitle.TextSize = 13
    estTitle.TextColor3 = COLORS.TEXT_PRIMARY
    estTitle.Size = UDim2.new(1, 0, 0, 25)
    estTitle.BackgroundTransparency = 1
    estTitle.Parent = rightCol

    self.EstimateLabels = {}
    local function createEst(name, color)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 28)
        frame.BackgroundTransparency = 1
        frame.Parent = rightCol
        
        local n = Instance.new("TextLabel")
        n.Text = name
        n.Font = FONTS.BODY
        n.TextSize = 12
        n.TextColor3 = COLORS.TEXT_SECONDARY
        n.Size = UDim2.new(0.5, 0, 1, 0)
        n.TextXAlignment = Enum.TextXAlignment.Left
        n.BackgroundTransparency = 1
        n.Parent = frame
        
        local v = Instance.new("TextLabel")
        v.Text = "..."
        v.Font = FONTS.TITLE
        v.TextSize = 14
        v.TextColor3 = color or COLORS.TEXT_PRIMARY
        v.Size = UDim2.new(0.5, 0, 1, 0)
        v.Position = UDim2.new(0.5, 0, 0, 0)
        v.TextXAlignment = Enum.TextXAlignment.Right
        v.BackgroundTransparency = 1
        v.Parent = frame
        
        self.EstimateLabels[name] = v
    end

    createEst("Total Cost", COLORS.MONEY)
    createEst("Stress Impact", COLORS.STRESS)
    createEst("Market Risk", Color3.new(1, 0.6, 0))
    createEst("Potential", Color3.new(0.4, 0.8, 1))

    -- Release Button (Spaced at the bottom)
    local btnSpacer = Instance.new("Frame")
    btnSpacer.Size = UDim2.new(1, 0, 0, 10)
    btnSpacer.BackgroundTransparency = 1
    btnSpacer.Parent = rightCol

    -- Release Button
    local releaseBtn = Instance.new("TextButton")
    releaseBtn.Name = "ReleaseButton"
    releaseBtn.Size = UDim2.new(1, 0, 0, 50)
    releaseBtn.Position = UDim2.new(0, 0, 0.8, 0)
    releaseBtn.BackgroundColor3 = COLORS.ACCENT
    releaseBtn.Font = FONTS.TITLE
    releaseBtn.TextSize = 20
    releaseBtn.TextColor3 = COLORS.TEXT_PRIMARY
    releaseBtn.Text = "RELEASE TRACK"
    releaseBtn.AutoButtonColor = false
    releaseBtn.Parent = rightCol

    Instance.new("UICorner").Parent = releaseBtn
    
    releaseBtn.MouseButton1Click:Connect(function()
        local result = SongSystem.ReleaseSong(self.CurrentSliders, self.SelectedGenre)
        if result and result.Success then
            -- Note: We DON'T close the menu anymore as per request
            self.ResultPopup:Show(result)
            self:UpdateEstimates()
            self.IdentityLabel.Text = "Current Identity: " .. SongSystem.GetArtistIdentity()
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
    self.EstimateLabels["Total Cost"].Text = "$" .. math.floor(est.Cost)
    self.EstimateLabels["Stress Impact"].Text = "+" .. math.floor(est.Stress)
    
    local riskText = "Low"
    if est.Risk > 60 then riskText = "Extreme"
    elseif est.Risk > 40 then riskText = "High"
    elseif est.Risk > 20 then riskText = "Medium" end
    self.EstimateLabels["Market Risk"].Text = riskText
    
    local potText = "Standard"
    if est.RewardPotential > 80 then potText = "Massive"
    elseif est.RewardPotential > 50 then potText = "High"
    elseif est.RewardPotential > 25 then potText = "Promising" end
    self.EstimateLabels["Potential"].Text = potText
end

function ProduceSongMenu:Toggle(isVisible)
    if isVisible then
        self.IdentityLabel.Text = "Current Identity: " .. SongSystem.GetArtistIdentity()
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
