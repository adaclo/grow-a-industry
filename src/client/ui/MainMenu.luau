--[[
    "Grow A Industry" - Main Menu
    A premium, modern music industry simulator UI.
    Spotify-inspired aesthetic with dark tones and neon accents.
]]

local TweenService = Game:GetService("TweenService")
local Players = Game:GetService("Players")

local MainMenu = {}
MainMenu.__index = MainMenu

-- Constants
local COLORS = {
    BACKGROUND = Color3.fromHex("#0A0A0A"),
    PANEL = Color3.fromHex("#121212"),
    ACCENT = Color3.fromHex("#8A2BE2"), -- Blue Violet
    ACCENT_NEON = Color3.fromHex("#BF40BF"), -- Neon Purple
    TEXT_PRIMARY = Color3.fromHex("#FFFFFF"),
    TEXT_SECONDARY = Color3.fromHex("#B3B3B3"),
    ERROR = Color3.fromHex("#FF4B4B")
}

local FONTS = {
    TITLE = Enum.Font.GothamBold,
    SUBTITLE = Enum.Font.GothamMedium,
    BUTTON = Enum.Font.GothamMedium,
    FOOTER = Enum.Font.Code
}

-- Utility: Create a Tween
local function createTween(instance, info, propertyTable)
    local tween = TweenService:Create(instance, info, propertyTable)
    tween:Play()
    return tween
end

-- UI Factory: Rounded Button with Hover Effects
function MainMenu:CreateButton(name, text, parent, isPrimary)
    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Text = text:upper()
    button.Font = FONTS.BUTTON
    button.TextSize = 16
    button.TextColor3 = COLORS.TEXT_PRIMARY
    button.BackgroundColor3 = isPrimary and COLORS.ACCENT or COLORS.PANEL
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    button.Size = UDim2.new(0, 240, 0, 50)
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = isPrimary and COLORS.ACCENT_NEON or COLORS.ACCENT
    stroke.Transparency = isPrimary and 0.5 or 0.8
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = button

    -- Hover animations
    button.MouseEnter:Connect(function()
        createTween(button, TweenInfo.new(0.3), {
            BackgroundColor3 = isPrimary and COLORS.ACCENT_NEON or COLORS.ACCENT,
            Size = UDim2.new(0, 250, 0, 55)
        })
        createTween(stroke, TweenInfo.new(0.3), {
            Transparency = 0,
            Thickness = 3
        })
    end)

    button.MouseLeave:Connect(function()
        createTween(button, TweenInfo.new(0.3), {
            BackgroundColor3 = isPrimary and COLORS.ACCENT or COLORS.PANEL,
            Size = UDim2.new(0, 240, 0, 50)
        })
        createTween(stroke, TweenInfo.new(0.3), {
            Transparency = isPrimary and 0.5 or 0.8,
            Thickness = 2
        })
    end)

    return button
end

function MainMenu.new()
    local self = setmetatable({}, MainMenu)

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MainMenuGui"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = screenGui

    -- Background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = COLORS.BACKGROUND
    background.BorderSizePixel = 0
    background.Parent = screenGui
    self.Background = background

    -- Decorative: Grid / Studio Vibes
    local decorationContainer = Instance.new("Frame")
    decorationContainer.Name = "Decorations"
    decorationContainer.Size = UDim2.new(1, 0, 1, 0)
    decorationContainer.BackgroundTransparency = 1
    decorationContainer.Parent = background

    -- Simple "Equalizer" Bars (Animated)
    for i = 1, 20 do
        local bar = Instance.new("Frame")
        bar.Name = "EQBar" .. i
        bar.Size = UDim2.new(0, 10, 0, math.random(20, 100))
        bar.Position = UDim2.new(0.05 * i, 0, 0.9, 0)
        bar.AnchorPoint = Vector2.new(0, 1)
        bar.BackgroundColor3 = COLORS.ACCENT
        bar.BackgroundTransparency = 0.7
        bar.BorderSizePixel = 0
        bar.Parent = decorationContainer

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = bar

        -- Infinite animation
        task.spawn(function()
            while screenGui.Parent do
                createTween(bar, TweenInfo.new(math.random(5, 15) / 10), {
                    Size = UDim2.new(0, 10, 0, math.random(30, 150)),
                    BackgroundColor3 = i % 2 == 0 and COLORS.ACCENT_NEON or COLORS.ACCENT
                })
                task.wait(0.5)
            end
        end)
    end

    -- Main Panel
    local mainPanel = Instance.new("Frame")
    mainPanel.Name = "MainPanel"
    mainPanel.Size = UDim2.new(0, 400, 0, 500)
    mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    mainPanel.BackgroundColor3 = COLORS.PANEL
    mainPanel.BackgroundTransparency = 0.1
    mainPanel.BorderSizePixel = 0
    mainPanel.Parent = background

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 20)
    panelCorner.Parent = mainPanel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Thickness = 1
    panelStroke.Color = COLORS.ACCENT
    panelStroke.Transparency = 0.5
    panelStroke.Parent = mainPanel

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "GROW A INDUSTRY"
    title.Font = FONTS.TITLE
    title.TextSize = 42
    title.TextColor3 = COLORS.TEXT_PRIMARY
    title.Size = UDim2.new(1, 0, 0, 80)
    title.LayoutOrder = 1
    title.BackgroundTransparency = 1
    title.Parent = mainPanel

    local titleGlow = Instance.new("UIStroke")
    titleGlow.Thickness = 2
    titleGlow.Color = COLORS.ACCENT_NEON
    titleGlow.Transparency = 0.6
    titleGlow.Parent = title

    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Text = "Build your own music empire"
    subtitle.Font = FONTS.SUBTITLE
    subtitle.TextSize = 18
    subtitle.TextColor3 = COLORS.TEXT_SECONDARY
    subtitle.Size = UDim2.new(1, 0, 0, 30)
    subtitle.LayoutOrder = 2
    subtitle.BackgroundTransparency = 1
    subtitle.Parent = mainPanel

    -- Button Layout
    local buttonList = Instance.new("UIListLayout")
    buttonList.Padding = UDim.new(0, 15)
    buttonList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    buttonList.VerticalAlignment = Enum.VerticalAlignment.Center
    buttonList.Parent = mainPanel

    local buttonSpacer = Instance.new("Frame")
    buttonSpacer.Size = UDim2.new(1, 0, 0, 40)
    buttonSpacer.BackgroundTransparency = 1
    buttonSpacer.LayoutOrder = 3
    buttonSpacer.Parent = mainPanel

    -- Buttons
    local playBtn = self:CreateButton("Play", "Play", mainPanel, true)
    playBtn.LayoutOrder = 4

    local settingsBtn = self:CreateButton("Settings", "Settings", mainPanel, false)
    settingsBtn.LayoutOrder = 5

    -- Credits Panel
    local creditsPanel = Instance.new("Frame")
    creditsPanel.Name = "CreditsPanel"
    creditsPanel.Size = UDim2.new(0, 350, 0, 250)
    creditsPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
    creditsPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    creditsPanel.BackgroundColor3 = COLORS.PANEL
    creditsPanel.BorderSizePixel = 0
    creditsPanel.Visible = false
    creditsPanel.ZIndex = 5
    creditsPanel.Parent = background

    local creditsCorner = Instance.new("UICorner")
    creditsCorner.CornerRadius = UDim.new(0, 15)
    creditsCorner.Parent = creditsPanel

    local creditsContent = Instance.new("TextLabel")
    creditsContent.Size = UDim2.new(1, -40, 1, -40)
    creditsContent.Position = UDim2.new(0, 20, 0, 20)
    creditsContent.BackgroundTransparency = 1
    creditsContent.TextColor3 = COLORS.TEXT_PRIMARY
    creditsContent.Text = "Created by Adrián\n\nInspired by BitLife and music management games\n\nDeveloped with Roblox Studio and Luau"
    creditsContent.Font = Enum.Font.Gotham
    creditsContent.TextSize = 16
    creditsContent.TextWrapped = true
    creditsContent.Parent = creditsPanel

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -10, 0, 10)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.BackgroundColor3 = COLORS.ERROR
    closeBtn.Text = "X"
    closeBtn.TextColor3 = COLORS.TEXT_PRIMARY
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = creditsPanel

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeBtn

    -- Logic: Play Transition
    playBtn.MouseButton1Click:Connect(function()
        local fadeOut = createTween(background, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        
        -- Fade all children
        for _, child in pairs(background:GetDescendants()) do
            if child:IsA("GuiObject") then
                createTween(child, TweenInfo.new(0.8), {Transparency = 1})
            end
        end

        fadeOut.Completed:Connect(function()
            screenGui:Destroy()
            print("Game Started!")
        end)
    end)

    -- Footer
    local footer = Instance.new("TextLabel")
    footer.Name = "Footer"
    footer.Text = "DAW/DAM Project · Roblox Studio"
    footer.Font = FONTS.FOOTER
    footer.TextSize = 12
    footer.TextColor3 = COLORS.TEXT_SECONDARY
    footer.Size = UDim2.new(1, 0, 0, 20)
    footer.Position = UDim2.new(0, 0, 1, -30)
    footer.BackgroundTransparency = 1
    footer.Parent = background

    return self
end

return MainMenu
