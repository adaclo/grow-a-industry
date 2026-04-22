local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameSystem")
local ArtistSystem = require(SharedModules:WaitForChild("ArtistSystem"))
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local ArtistsMenu = {}
ArtistsMenu.__index = ArtistsMenu

local COLORS = {
    BACKGROUND = Color3.fromHex("#0A0A0A"),
    PANEL = Color3.fromHex("#121212"),
    ACCENT = Color3.fromHex("#8A2BE2"),
    ACCENT_NEON = Color3.fromHex("#BF40BF"),
    TEXT_PRIMARY = Color3.fromHex("#FFFFFF"),
    TEXT_SECONDARY = Color3.fromHex("#B3B3B3"),
    POSITIVE = Color3.fromHex("#4BB543"),
    NEGATIVE = Color3.fromHex("#FF4444"),
    GOLD = Color3.fromHex("#FFD700"),
    PINK = Color3.fromHex("#FF69B4"),
    UNDERGROUND = Color3.fromHex("#6A0DAD"),
    MAINSTREAM = Color3.fromHex("#FFA500"),
    COOLDOWN = Color3.fromHex("#444444"),
    LOCKED = Color3.fromHex("#222222")
}

local FONTS = {
    TITLE = Enum.Font.GothamBold,
    SUBTITLE = Enum.Font.GothamMedium,
    BODY = Enum.Font.Gotham,
}

function ArtistsMenu.new(parentGui, resultPopup)
    local self = setmetatable({}, ArtistsMenu)
    self.ResultPopup = resultPopup
    self.IsProcessing = false
    self.ActiveTimers = {}
    self.DiscoveryButtons = {}
    self.ManageButtons = {}
    self.CurrentlyManaging = nil
    
    -- 1. MAIN FRAME
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "ArtistsMainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundColor3 = COLORS.PANEL
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.ZIndex = 100
    
    if not parentGui then
        local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
        local sg = pg:FindFirstChildWhichIsA("ScreenGui") or Instance.new("ScreenGui", pg)
        parentGui = sg
    end
    mainFrame.Parent = parentGui
    self.MainFrame = mainFrame
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 20)

    -- Static Back Button
    local mainBack = Instance.new("TextButton")
    mainBack.Name = "MainBackButton"
    mainBack.Text = "< BACK"
    mainBack.Font = FONTS.SUBTITLE
    mainBack.TextSize = 12
    mainBack.TextColor3 = COLORS.ACCENT_NEON
    mainBack.Size = UDim2.new(0, 80, 0, 30)
    mainBack.Position = UDim2.new(0, 20, 0, 15)
    mainBack.BackgroundTransparency = 1
    mainBack.ZIndex = 110
    mainBack.Parent = mainFrame
    self.BackButton = mainBack
    mainBack.MouseButton1Click:Connect(function() self:Toggle(false) end)

    -- 2. MANDATORY CONTENT SCROLL
    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Name = "ContentScroll"
    contentScroll.Size = UDim2.new(1, -40, 1, -100)
    contentScroll.Position = UDim2.new(0, 20, 0, 70)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 4
    contentScroll.ScrollBarImageColor3 = COLORS.ACCENT
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScroll.ZIndex = 101
    contentScroll.Parent = mainFrame
    self.ContentScroll = contentScroll

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentScroll

    -- A. Header Section
    local header = Instance.new("Frame")
    header.Name = "HeaderSection"
    header.Size = UDim2.new(1, 0, 0, 70)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 1
    header.ZIndex = 105
    header.Parent = contentScroll
    
    local titleL = Instance.new("TextLabel")
    titleL.Text = "ARTISTS"
    titleL.Font = FONTS.TITLE
    titleL.TextSize = 22
    titleL.TextColor3 = COLORS.TEXT_PRIMARY
    titleL.Size = UDim2.new(1, 0, 0, 40)
    titleL.Position = UDim2.new(0, 0, 0, 10)
    titleL.BackgroundTransparency = 1
    titleL.ZIndex = 106
    titleL.Parent = header
    
    self.StudioInfo = Instance.new("TextLabel")
    self.StudioInfo.Text = "STUDIO LVL 1 • SLOTS: 1/1"
    self.StudioInfo.Font = FONTS.SUBTITLE
    self.StudioInfo.TextSize = 12
    self.StudioInfo.TextColor3 = COLORS.GOLD
    self.StudioInfo.Size = UDim2.new(1, 0, 0, 20)
    self.StudioInfo.Position = UDim2.new(0, 0, 0, 45)
    self.StudioInfo.BackgroundTransparency = 1
    self.StudioInfo.ZIndex = 106
    self.StudioInfo.Parent = header

    -- B. ActionsRow Section
    local actionsRow = Instance.new("Frame")
    actionsRow.Name = "ActionsRow"
    actionsRow.Size = UDim2.new(1, 0, 0, 70)
    actionsRow.BackgroundTransparency = 1
    actionsRow.LayoutOrder = 2
    actionsRow.ZIndex = 105
    actionsRow.Parent = contentScroll
    
    local actionGrid = Instance.new("UIGridLayout")
    actionGrid.CellSize = UDim2.new(0.48, 0, 0, 32)
    actionGrid.CellPadding = UDim2.new(0.04, 0, 0, 6)
    actionGrid.Parent = actionsRow

    local discoveryActions = {
        {Id = "DMFamous", Name = "DM FAMOUS", Icon = "📱"},
        {Id = "DuoNew", Name = "DUO NEW", Icon = "🎤"},
        {Id = "SignUnderground", Name = "UNDERGROUND", Icon = "📻"},
        {Id = "SignMainstream", Name = "MAINSTREAM", Icon = "📈"}
    }
    for _, act in pairs(discoveryActions) do
        self:CreateDiscoveryButton(actionsRow, act)
    end

    -- 3. MANAGE ARTIST DETAIL VIEW
    self.DetailView = Instance.new("Frame")
    self.DetailView.Name = "ManageArtistView"
    self.DetailView.Size = UDim2.new(1, 0, 1, 0)
    self.DetailView.BackgroundColor3 = COLORS.PANEL
    self.DetailView.ZIndex = 200
    self.DetailView.Visible = false
    self.DetailView.Parent = mainFrame
    Instance.new("UICorner", self.DetailView).CornerRadius = UDim.new(0, 20)

    -- Detail Content Scroll
    local dc = Instance.new("ScrollingFrame")
    dc.Name = "ManageContentScroll"
    dc.Size = UDim2.new(1, -40, 1, -60)
    dc.Position = UDim2.new(0, 20, 0, 40)
    dc.BackgroundTransparency = 1
    dc.BorderSizePixel = 0
    dc.ScrollBarThickness = 2
    dc.CanvasSize = UDim2.new(0, 0, 0, 0)
    dc.AutomaticCanvasSize = Enum.AutomaticSize.Y
    dc.ZIndex = 201
    dc.Parent = self.DetailView
    self.ManageContentScroll = dc

    local dcLayout = Instance.new("UIListLayout")
    dcLayout.Padding = UDim.new(0, 15)
    dcLayout.SortOrder = Enum.SortOrder.LayoutOrder
    dcLayout.Parent = dc

    -- Detail Back Button
    local db = Instance.new("TextButton")
    db.Name = "DetailBackButton"
    db.Text = "< BACK"
    db.Font = FONTS.SUBTITLE
    db.TextSize = 10
    db.TextColor3 = COLORS.ACCENT_NEON
    db.Size = UDim2.new(0, 50, 0, 20)
    db.Position = UDim2.new(0, 20, 0, 10)
    db.BackgroundTransparency = 1
    db.ZIndex = 210
    db.Parent = self.DetailView
    db.MouseButton1Click:Connect(function() 
        self.DetailView.Visible = false 
        self.CurrentlyManaging = nil
    end)

    self:UpdateRoster()
    
    PlayerDataManager.StateChanged:Connect(function(key)
        if key == "Artists" then self:UpdateRoster()
        elseif key == "StudioLevel" then self:UpdateInfo() end
    end)

    -- Core Update Loop
    RunService.Heartbeat:Connect(function()
        self:UpdateCooldownUI()
    end)

    return self
end

function ArtistsMenu:UpdateInfo()
    if not self.StudioInfo then return end
    local state = PlayerDataManager.GetState()
    local level = state.StudioLevel or 1
    local artists = state.Artists or {}
    self.StudioInfo.Text = string.format("STUDIO LVL %d • SLOTS: %d/%d", level, #artists, level)
end

function ArtistsMenu:CreateDiscoveryButton(parent, act)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = COLORS.BACKGROUND
    btn.Text = ""
    btn.ZIndex = 110
    btn.Parent = parent
    Instance.new("UICorner", btn)
    local label = Instance.new("TextLabel")
    label.Text = act.Icon .. " " .. act.Name
    label.Font = FONTS.SUBTITLE
    label.TextSize = 10
    label.TextColor3 = COLORS.TEXT_PRIMARY
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.ZIndex = 111
    label.Parent = btn
    self.DiscoveryButtons[act.Id] = {Button = btn, Label = label, Action = act}
    btn.MouseButton1Click:Connect(function()
        local state, reason = ArtistSystem.GetActionState(act.Id)
        if state == "LOCKED" or state == "FULL" or state == "COOLDOWN" then return end
        if self.IsProcessing then return end
        self.IsProcessing = true
        local success, result = pcall(function() return ArtistSystem.PerformAction(act.Id) end)
        if success and result and result.Success then 
            self.ResultPopup:Show(result) 
            if self.OnActionTriggered then self.OnActionTriggered() end
        end
        task.wait(1)
        self.IsProcessing = false
    end)
end

function ArtistsMenu:UpdateCooldownUI()
    -- Update Discovery Buttons
    for id, data in pairs(self.DiscoveryButtons) do
        local state, reason = ArtistSystem.GetActionState(id)
        if state == "READY" then
            data.Button.BackgroundColor3 = COLORS.BACKGROUND
            data.Label.TextColor3 = COLORS.TEXT_PRIMARY
        elseif state == "LOCKED" or state == "FULL" then
            data.Button.BackgroundColor3 = COLORS.LOCKED
            data.Label.TextColor3 = COLORS.NEGATIVE
        elseif state == "COOLDOWN" then
            data.Button.BackgroundColor3 = COLORS.COOLDOWN
            data.Label.TextColor3 = COLORS.GOLD
        end
    end

    -- Update Manage Buttons
    if self.CurrentlyManaging and self.DetailView.Visible then
        for id, data in pairs(self.ManageButtons) do
            local state, reason = ArtistSystem.GetActionState(id, self.CurrentlyManaging.Id)
            
            if state == "READY" then
                if data.Label.Text ~= "READY" then
                    data.Label.Text = "READY"
                    data.Label.TextColor3 = COLORS.POSITIVE
                    data.Label.TextSize = 9
                    data.Button.BackgroundColor3 = COLORS.BACKGROUND
                    if data.Stroke then data.Stroke.Transparency = 0 end
                end
            elseif state == "PENDING" or state == "COOLDOWN" then
                data.Label.Text = "⏳ " .. (reason or "...")
                data.Label.TextColor3 = COLORS.GOLD
                data.Label.TextSize = 8
                data.Button.BackgroundColor3 = COLORS.COOLDOWN
                if data.Stroke then data.Stroke.Transparency = 0.8 end
            elseif state == "LOCKED" then
                data.Label.Text = "LOCKED"
                data.Label.TextColor3 = COLORS.NEGATIVE
                data.Button.BackgroundColor3 = COLORS.LOCKED
                if data.Stroke then data.Stroke.Transparency = 1 end
            end
        end
    end

    -- Update Roster Statuses
    for _, timer in pairs(self.ActiveTimers) do
        local state, reason = ArtistSystem.GetActionState(timer.ActionId, timer.ArtistId)
        if state == "READY" then
            timer.Label.Text = "READY"
            timer.Label.TextColor3 = COLORS.POSITIVE
        elseif state == "PENDING" or state == "COOLDOWN" then
            timer.Label.Text = "⏳ " .. (reason or "...")
            timer.Label.TextColor3 = COLORS.GOLD
        else
            timer.Label.Text = "BUSY"
            timer.Label.TextColor3 = COLORS.GOLD
        end
    end
end

function ArtistsMenu:UpdateRoster()
    if not self.ContentScroll then return end
    for _, child in pairs(self.ContentScroll:GetChildren()) do
        if child.Name == "ArtistCard" or child.Name == "EmptyLabel" then child:Destroy() end
    end
    self.ActiveTimers = {}
    local artists = PlayerDataManager.GetState().Artists or {}
    self:UpdateInfo()
    if #artists == 0 then
        local empty = Instance.new("TextLabel")
        empty.Name = "EmptyLabel"
        empty.Text = "NO ARTISTS SIGNED"
        empty.Font = FONTS.BODY
        empty.TextSize = 14
        empty.TextColor3 = COLORS.TEXT_SECONDARY
        empty.Size = UDim2.new(1, -10, 0, 100)
        empty.BackgroundTransparency = 1
        empty.LayoutOrder = 10 
        empty.ZIndex = 105
        empty.Parent = self.ContentScroll
    else
        for i, artist in ipairs(artists) do
            local card = self:CreateArtistCard(artist, i + 10)
            card.Parent = self.ContentScroll
        end
    end
end

function ArtistsMenu:CreateArtistCard(artist, index)
    local entry = Instance.new("Frame")
    entry.Name = "ArtistCard"
    entry.Size = UDim2.new(1, -10, 0, 100)
    entry.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    entry.LayoutOrder = index
    entry.ZIndex = 105
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 12)
    local name = Instance.new("TextLabel")
    name.Text = artist.Name:upper()
    name.Font = FONTS.TITLE
    name.TextSize = 15
    name.TextColor3 = COLORS.TEXT_PRIMARY
    name.Size = UDim2.new(0.6, 0, 0, 30)
    name.Position = UDim2.new(0, 15, 0, 10)
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.BackgroundTransparency = 1
    name.ZIndex = 106
    name.Parent = entry
    local status = Instance.new("TextLabel")
    status.Text = "READY"
    status.Font = FONTS.BODY
    status.TextSize = 8
    status.TextColor3 = COLORS.POSITIVE
    status.Size = UDim2.new(0.6, 0, 0, 20)
    status.Position = UDim2.new(0, 15, 0, 35)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.BackgroundTransparency = 1
    status.ZIndex = 106
    status.Parent = entry
    table.insert(self.ActiveTimers, {Label = status, ArtistId = artist.Id, ActionId = "Status"})
    local manageBtn = Instance.new("TextButton")
    manageBtn.Text = "MANAGE"
    manageBtn.Font = FONTS.SUBTITLE
    manageBtn.TextSize = 10
    manageBtn.TextColor3 = COLORS.TEXT_PRIMARY
    manageBtn.BackgroundColor3 = COLORS.ACCENT
    manageBtn.Size = UDim2.new(0, 85, 0, 30)
    manageBtn.Position = UDim2.new(1, -100, 0.5, -15)
    manageBtn.ZIndex = 107
    manageBtn.Parent = entry
    Instance.new("UICorner", manageBtn)
    manageBtn.MouseButton1Click:Connect(function()
        if self.IsProcessing then return end
        self:OpenArtistDetail(artist)
    end)
    return entry
end

function ArtistsMenu:OpenArtistDetail(artist)
    self.CurrentlyManaging = artist
    self.DetailView.Visible = true
    self:RenderManageMenu(artist)
end

function ArtistsMenu:GetArtistStatusText(artist)
    if artist.Stress > 70 then return "Artist is extremely stressed and unstable."
    elseif artist.Stress > 40 then return "Artist is feeling the pressure."
    elseif artist.Ego > 80 then return "Ego is causing friction in the studio."
    elseif artist.Loyalty < 30 then return "Artist doesn't seem to trust your vision."
    elseif artist.Loyalty > 80 and artist.Stress < 20 then return "Artist is motivated and very stable."
    else return "Artist is performing within normal parameters." end
end

function ArtistsMenu:RenderManageMenu(artist)
    local dc = self.ManageContentScroll
    if not dc then return end
    for _, child in pairs(dc:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    self.ManageButtons = {}
    
    -- 1. HEADER
    local header = Instance.new("Frame")
    header.Name = "DetailHeader"
    header.Size = UDim2.new(1, 0, 0, 70)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 1
    header.ZIndex = 205
    header.Parent = dc
    local nameL = Instance.new("TextLabel")
    nameL.Text = artist.Name:upper()
    nameL.Font = FONTS.TITLE
    nameL.TextSize = 22
    nameL.TextColor3 = COLORS.TEXT_PRIMARY
    nameL.Size = UDim2.new(1, 0, 0, 30)
    nameL.BackgroundTransparency = 1
    nameL.ZIndex = 206
    nameL.Parent = header
    local styleL = Instance.new("TextLabel")
    styleL.Text = string.format("%s • %s • %s", artist.Style:upper(), artist.Mood:upper(), "Motivated")
    styleL.Font = FONTS.SUBTITLE
    styleL.TextSize = 10
    styleL.TextColor3 = COLORS.ACCENT_NEON
    styleL.Size = UDim2.new(1, 0, 0, 15)
    styleL.Position = UDim2.new(0, 0, 0, 32)
    styleL.BackgroundTransparency = 1
    styleL.ZIndex = 206
    styleL.Parent = header

    -- 2. STATS PANEL
    local statsPanel = Instance.new("Frame")
    statsPanel.Name = "StatsPanel"
    statsPanel.Size = UDim2.new(1, 0, 0, 130)
    statsPanel.BackgroundTransparency = 1
    statsPanel.LayoutOrder = 2
    statsPanel.ZIndex = 205
    statsPanel.Parent = dc
    local statsList = Instance.new("UIListLayout")
    statsList.Padding = UDim.new(0, 8)
    statsList.Parent = statsPanel
    
    local statsData = {
        {N = "Talent", V = artist.Talent, C = COLORS.POSITIVE},
        {N = "Loyalty", V = artist.Loyalty, C = COLORS.ACCENT_NEON},
        {N = "Ego", V = artist.Ego, C = COLORS.PINK},
        {N = "Stress", V = artist.Stress, C = (artist.Stress > 70 and COLORS.NEGATIVE) or (artist.Stress > 40 and COLORS.GOLD) or COLORS.POSITIVE}
    }
    for _, s in pairs(statsData) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 24)
        row.BackgroundTransparency = 1
        row.ZIndex = 206
        row.Parent = statsPanel
        local l = Instance.new("TextLabel")
        l.Text = s.N:upper()
        l.Font = FONTS.BODY
        l.TextSize = 9
        l.TextColor3 = COLORS.TEXT_SECONDARY
        l.Size = UDim2.new(1, 0, 0, 12)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.BackgroundTransparency = 1
        l.ZIndex = 207
        l.Parent = row
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 0, 5)
        bg.Position = UDim2.new(0, 0, 0, 15)
        bg.BackgroundColor3 = Color3.new(0,0,0)
        bg.ZIndex = 207
        bg.Parent = row
        Instance.new("UICorner", bg)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(math.clamp(s.V/100, 0, 1), 0, 1, 0)
        fill.BackgroundColor3 = s.C
        fill.ZIndex = 208
        fill.Parent = bg
        Instance.new("UICorner", fill)
    end

    -- 3. STATUS INTERPRETATION
    local statusL = Instance.new("TextLabel")
    statusL.Name = "StatusText"
    statusL.Text = self:GetArtistStatusText(artist)
    statusL.Font = FONTS.BODY
    statusL.TextSize = 10
    statusL.TextColor3 = COLORS.TEXT_SECONDARY
    statusL.Size = UDim2.new(1, 0, 0, 25)
    statusL.BackgroundTransparency = 1
    statusL.LayoutOrder = 3
    statusL.ZIndex = 206
    statusL.Parent = dc

    -- 4. ACTION GRID
    local actionContainer = Instance.new("Frame")
    actionContainer.Name = "ActionContainer"
    actionContainer.Size = UDim2.new(1, 0, 0, 160)
    actionContainer.AutomaticSize = Enum.AutomaticSize.Y
    actionContainer.BackgroundTransparency = 1
    actionContainer.LayoutOrder = 4
    actionContainer.ZIndex = 205
    actionContainer.Parent = dc
    local actionGrid = Instance.new("UIGridLayout")
    actionGrid.CellSize = UDim2.new(0.31, 0, 0, 75)
    actionGrid.CellPadding = UDim2.new(0.03, 0, 0, 12)
    actionGrid.Parent = actionContainer

    local mActions = {
        {Id = "TalkToArtist", Name = "TALK", Icon = "💬", Desc = "+Loyal -Stress"},
        {Id = "GiveBonus", Name = "BONUS", Icon = "💰", Desc = "++Loyal +Ego"},
        {Id = "RecordSong", Name = "RECORD", Icon = "🎤", Desc = "+$$ +Fame"},
        {Id = "RestArtist", Name = "REST", Icon = "💤", Desc = "-Stress -Ego"},
        {Id = "DropArtist", Name = "DROP", Icon = "❌", Desc = "BYE"}
    }
    for _, act in pairs(mActions) do
        local btn = Instance.new("Frame")
        btn.BackgroundColor3 = COLORS.BACKGROUND
        btn.ZIndex = 206
        btn.Parent = actionContainer
        Instance.new("UICorner", btn)
        
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 2
        stroke.Color = COLORS.ACCENT_NEON
        stroke.Transparency = 0 -- Initial READY glow
        stroke.Parent = btn

        local nL = Instance.new("TextLabel")
        nL.Text = act.Icon .. " " .. act.Name
        nL.Font = FONTS.SUBTITLE
        nL.TextSize = 10
        nL.TextColor3 = COLORS.TEXT_PRIMARY
        nL.Size = UDim2.new(1, 0, 0, 25)
        nL.BackgroundTransparency = 1
        nL.ZIndex = 207
        nL.Parent = btn
        local dL = Instance.new("TextLabel")
        dL.Text = act.Desc
        dL.Font = FONTS.BODY
        dL.TextSize = 8
        dL.TextColor3 = COLORS.TEXT_SECONDARY
        dL.Size = UDim2.new(1, -10, 0, 20)
        dL.Position = UDim2.new(0, 5, 0, 25)
        dL.BackgroundTransparency = 1
        dL.ZIndex = 207
        dL.Parent = btn
        local sL = Instance.new("TextLabel")
        sL.Text = "READY"
        sL.Font = FONTS.BODY
        sL.TextSize = 9
        sL.TextColor3 = COLORS.POSITIVE
        sL.Size = UDim2.new(1, 0, 0, 20)
        sL.Position = UDim2.new(0, 0, 0, 48)
        sL.BackgroundTransparency = 1
        sL.ZIndex = 207
        sL.Parent = btn
        
        self.ManageButtons[act.Id] = {Button = btn, Label = sL, Stroke = stroke}

        local clickBtn = Instance.new("TextButton")
        clickBtn.Size = UDim2.new(1, 0, 1, 0)
        clickBtn.BackgroundTransparency = 1
        clickBtn.Text = ""
        clickBtn.ZIndex = 208
        clickBtn.Parent = btn
        
        clickBtn.MouseEnter:Connect(function()
            if sL.Text == "READY" then
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30,30,30)}):Play()
            end
        end)
        clickBtn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BACKGROUND}):Play()
        end)

        clickBtn.MouseButton1Click:Connect(function()
            local state, reason = ArtistSystem.GetActionState(act.Id, artist.Id)
            if state ~= "READY" then return end
            if self.IsProcessing then return end
            self.IsProcessing = true
            local success, result = pcall(function() return ArtistSystem.PerformAction(act.Id, artist.Id) end)
            if success and result and result.Success then
                self.ResultPopup:Show(result)
                if act.Id == "DropArtist" then self.DetailView.Visible = false else self:RenderManageMenu(artist) end
                if self.OnActionTriggered then self.OnActionTriggered() end
            end
            task.wait(1)
            self.IsProcessing = false
        end)
    end
end

function ArtistsMenu:Toggle(isVisible)
    if isVisible then
        self:UpdateRoster()
        self.MainFrame.Visible = true
        self.MainFrame.Position = UDim2.new(1, 0, 0, 0)
        TweenService:Create(self.MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
    else
        self.MainFrame.Visible = false
        self.DetailView.Visible = false
        self.CurrentlyManaging = nil
    end
end

return ArtistsMenu
