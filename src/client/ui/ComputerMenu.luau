local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameSystem")
local PlayerDataManager = require(SharedModules:WaitForChild("PlayerDataManager"))

local ProduceSongMenu = require(script.Parent:WaitForChild("ProduceSongMenu"))
local ResultPopup = require(script.Parent:WaitForChild("ResultPopup"))
local StatsMenu = require(script.Parent:WaitForChild("StatsMenu"))
local SocialMediaMenu = require(script.Parent:WaitForChild("SocialMediaMenu"))
local ArtistsMenu = require(script.Parent:WaitForChild("ArtistsMenu"))
local PlaceholderMenu = require(script.Parent:WaitForChild("PlaceholderMenu"))
local DecisionPopup = require(script.Parent:WaitForChild("DecisionPopup"))
local EventSystem = require(SharedModules:WaitForChild("EventSystem"))
local StyleSystem = require(SharedModules:WaitForChild("StyleSystem"))

local ComputerMenu = {}
ComputerMenu.__index = ComputerMenu

local COLORS = {
    BACKGROUND = Color3.fromHex("#0A0A0A"),
    PANEL = Color3.fromHex("#121212"),
    ACCENT = Color3.fromHex("#8A2BE2"),
    ACCENT_NEON = Color3.fromHex("#BF40BF"),
    TEXT_PRIMARY = Color3.fromHex("#FFFFFF"),
    TEXT_SECONDARY = Color3.fromHex("#B3B3B3"),
    LOCKED = Color3.fromHex("#333333")
}

local FONTS = {
    TITLE = Enum.Font.GothamBold,
    BUTTON = Enum.Font.GothamBold,
    BODY = Enum.Font.Gotham
}

function ComputerMenu.new(upgradeMenuInstance)
    local self = setmetatable({}, ComputerMenu)
    self.UpgradeMenu = upgradeMenuInstance
    self.OnClose = nil

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ComputerMenuGui"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = screenGui

    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 700, 0, 500)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = COLORS.PANEL
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    self.MainFrame = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = COLORS.ACCENT
    stroke.Transparency = 0.5
    stroke.Parent = mainFrame

    -- Inner Container (for transitions between main and submenus)
    local innerContainer = Instance.new("Frame")
    innerContainer.Name = "InnerContainer"
    innerContainer.Size = UDim2.new(1, 0, 1, 0)
    innerContainer.BackgroundTransparency = 1
    innerContainer.Parent = mainFrame
    self.InnerContainer = innerContainer

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundTransparency = 1
    header.Parent = innerContainer

    local title = Instance.new("TextLabel")
    title.Text = "STUDIO COMPUTER"
    title.Font = FONTS.TITLE
    title.TextSize = 28
    title.TextColor3 = COLORS.TEXT_PRIMARY
    title.Size = UDim2.new(0.6, 0, 1, 0)
    title.Position = UDim2.new(0.05, 0, 0, 0)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.Parent = header

    -- Result Popup Instance
    self.ResultPopup = ResultPopup.new(screenGui)
    self.DecisionPopup = DecisionPopup.new(screenGui)

    -- Submenus
    self.ProduceSongMenu = ProduceSongMenu.new(mainFrame, self.ResultPopup)
    self.StatsMenu = StatsMenu.new(mainFrame)
    self.SocialMediaMenu = SocialMediaMenu.new(mainFrame, self.ResultPopup)
    self.ArtistsMenu = ArtistsMenu.new(mainFrame, self.ResultPopup)
    self.ContractsMenu = PlaceholderMenu.new(mainFrame, "Contracts", "Review and sign deals with major labels, distributors, and sponsors.")

    -- Connect Events
    self.ProduceSongMenu.OnActionTriggered = function() self:CheckForRandomEvent() end
    self.SocialMediaMenu.OnActionTriggered = function() self:CheckForRandomEvent() end
    self.ArtistsMenu.OnActionTriggered = function() self:CheckForRandomEvent() end

    -- Grid Layout for Buttons
    local grid = Instance.new("Frame")
    grid.Name = "ButtonGrid"
    grid.Size = UDim2.new(1, -60, 1, -120)
    grid.Position = UDim2.new(0, 30, 0, 100)
    grid.BackgroundTransparency = 1
    grid.Parent = innerContainer

    local uigrid = Instance.new("UIGridLayout")
    uigrid.CellSize = UDim2.new(0.31, 0, 0, 140)
    uigrid.CellPadding = UDim2.new(0.035, 0, 0.05, 0)
    uigrid.Parent = grid

    -- Buttons
    self:CreateButton(grid, "Produce Song", "Drop a new track and gain followers.", true, function()
        self:OpenSubmenu("ProduceSong")
    end)
    self:CreateButton(grid, "Social Media", "Interact with fans and posts.", true, function()
        self:OpenSubmenu("SocialMedia")
    end)
    self:CreateButton(grid, "Artists", "Manage your roster and signings.", true, function()
        self:OpenSubmenu("Artists")
    end)
    self:CreateButton(grid, "Contracts", "Review label and brand offers.", true, function()
        self:OpenSubmenu("Contracts")
    end)
    self:CreateButton(grid, "Upgrade Studio", "Improve your gear and software.", true, function()
        self:Close()
        if self.UpgradeMenu then
            self.UpgradeMenu:Toggle(true)
        end
    end)
    self:CreateButton(grid, "View Stats", "Check your career progress.", true, function()
        self:OpenSubmenu("Stats")
    end)
    self:CreateButton(grid, "Admin Debug", "Trigger events and disable cooldowns (DEV).", true, function()
        self:TriggerDebugEvent()
    end)
    self:CreateButton(grid, "Close", "Exit the computer simulation.", true, function()
        self:Close()
    end)

    -- Connections
    self.ProduceSongMenu.BackButton.MouseButton1Click:Connect(function()
        self:TranslateInner(true)
        self.ProduceSongMenu:Toggle(false)
    end)

    self.StatsMenu.BackButton.MouseButton1Click:Connect(function()
        self:TranslateInner(true)
        self.StatsMenu:Toggle(false)
    end)

    self.SocialMediaMenu.BackButton.MouseButton1Click:Connect(function()
        self:TranslateInner(true)
        self.SocialMediaMenu:Toggle(false)
    end)

    self.ArtistsMenu.BackButton.MouseButton1Click:Connect(function()
        self:TranslateInner(true)
        self.ArtistsMenu:Toggle(false)
    end)

    self.ContractsMenu.BackButton.MouseButton1Click:Connect(function()
        self:TranslateInner(true)
        self.ContractsMenu:Toggle(false)
    end)


    return self
end

function ComputerMenu:CreateButton(parent, text, desc, enabled, callback)
    local btnFrame = Instance.new("Frame")
    btnFrame.BackgroundColor3 = enabled and COLORS.BACKGROUND or COLORS.LOCKED
    btnFrame.BorderSizePixel = 0
    btnFrame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btnFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = enabled and COLORS.ACCENT or COLORS.LOCKED
    stroke.Transparency = 0.8
    stroke.Parent = btnFrame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = btnFrame

    local title = Instance.new("TextLabel")
    title.Text = text:upper()
    title.Font = FONTS.BUTTON
    title.TextSize = 14
    title.TextColor3 = enabled and COLORS.TEXT_PRIMARY or COLORS.TEXT_SECONDARY
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0.1, 0)
    title.BackgroundTransparency = 1
    title.Parent = btnFrame

    local descLabel = Instance.new("TextLabel")
    descLabel.Text = desc
    descLabel.Font = FONTS.BODY
    descLabel.TextSize = 11
    descLabel.TextColor3 = COLORS.TEXT_SECONDARY
    descLabel.Size = UDim2.new(0.8, 0, 0, 50)
    descLabel.Position = UDim2.new(0.1, 0, 0.4, 0)
    descLabel.BackgroundTransparency = 1
    descLabel.TextWrapped = true
    descLabel.Parent = btnFrame

    if enabled then
        btn.MouseEnter:Connect(function()
            TweenService:Create(btnFrame, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromHex("#1A1A1A")}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = COLORS.ACCENT_NEON, Transparency = 0}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btnFrame, TweenInfo.new(0.3), {BackgroundColor3 = COLORS.BACKGROUND}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.3), {Color = COLORS.ACCENT, Transparency = 0.8}):Play()
        end)
        btn.MouseButton1Click:Connect(callback)
    end
end

function ComputerMenu:OpenSubmenu(name)
    self:TranslateInner(false)
    if name == "ProduceSong" then
        self.ProduceSongMenu:Toggle(true)
    elseif name == "Stats" then
        self.StatsMenu:Toggle(true)
    elseif name == "SocialMedia" then
        self.SocialMediaMenu:Toggle(true)
    elseif name == "Artists" then
        self.ArtistsMenu:Toggle(true)
    elseif name == "Contracts" then
        self.ContractsMenu:Toggle(true)
    end
end

function ComputerMenu:TranslateInner(toCenter)
    local targetPos = toCenter and UDim2.new(0, 0, 0, 0) or UDim2.new(-1, 0, 0, 0)
    TweenService:Create(self.InnerContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = targetPos
    }):Play()
end

function ComputerMenu:Open(onCloseCallback)
    print("Opening Computer Menu")
    self.OnClose = onCloseCallback
    self.Gui.Enabled = true
    self.InnerContainer.Position = UDim2.new(0, 0, 0, 0)
    
    self.MainFrame.Size = UDim2.new(0, 500, 0, 400)
    self.MainFrame.BackgroundTransparency = 1
    TweenService:Create(self.MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 700, 0, 500),
        BackgroundTransparency = 0
    }):Play()
end

function ComputerMenu:Close()
    local t = TweenService:Create(self.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 500, 0, 400),
        BackgroundTransparency = 1
    })
    t:Play()
    t.Completed:Connect(function()
        self.Gui.Enabled = false
        if self.OnClose then
            self.OnClose()
            self.OnClose = nil
        end
    end)
end

function ComputerMenu:Toggle(isVisible)
    if isVisible then
        self:Open()
    else
        self:Close()
    end
end

function ComputerMenu:CheckForRandomEvent()
    local chance = 0.2 -- 20% chance after action
    if math.random() < chance then
        local event = EventSystem.GetRandomEvent()
        if event then
            self.DecisionPopup:Show(event, function()
                StyleSystem.UpdateStyleFromHistory()
            end)
        end
    end
end

function ComputerMenu:TriggerDebugEvent()
    local event = EventSystem.GetRandomEvent()
    self.DecisionPopup:Show(event, function()
        StyleSystem.UpdateStyleFromHistory()
    end)
end

return ComputerMenu
