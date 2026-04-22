local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local PlaceholderMenu = {}
PlaceholderMenu.__index = PlaceholderMenu

local COLORS = {
    BACKGROUND = Color3.fromHex("#0A0A0A"),
    PANEL = Color3.fromHex("#121212"),
    ACCENT = Color3.fromHex("#8A2BE2"),
    TEXT_PRIMARY = Color3.fromHex("#FFFFFF"),
    TEXT_SECONDARY = Color3.fromHex("#B3B3B3"),
}

function PlaceholderMenu.new(parentGui, titleText, bodyText)
    local self = setmetatable({}, PlaceholderMenu)

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = titleText .. "Frame"
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
    title.Text = titleText:upper()
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.TextColor3 = COLORS.TEXT_PRIMARY
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Parent = header

    local backBtn = Instance.new("TextButton")
    backBtn.Name = "BackButton"
    backBtn.Text = "< BACK"
    backBtn.Font = Enum.Font.GothamMedium
    backBtn.TextSize = 14
    backBtn.TextColor3 = COLORS.ACCENT
    backBtn.Size = UDim2.new(0, 80, 0, 30)
    backBtn.Position = UDim2.new(0, 20, 0, 25)
    backBtn.BackgroundTransparency = 1
    backBtn.Parent = header
    self.BackButton = backBtn

    -- Content
    local content = Instance.new("TextLabel")
    content.Text = bodyText .. "\n\n(System is currently being developed)"
    content.Font = Enum.Font.Gotham
    content.TextSize = 16
    content.TextColor3 = COLORS.TEXT_SECONDARY
    content.Size = UDim2.new(0.8, 0, 0.4, 0)
    content.Position = UDim2.new(0.1, 0, 0.3, 0)
    content.BackgroundTransparency = 1
    content.TextWrapped = true
    content.Parent = mainFrame

    return self
end

function PlaceholderMenu:Toggle(isVisible)
    if isVisible then
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

return PlaceholderMenu
