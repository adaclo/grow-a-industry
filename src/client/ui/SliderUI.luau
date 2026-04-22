local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local SliderUI = {}
SliderUI.__index = SliderUI

function SliderUI.new(parent, title, initialValue)
    local self = setmetatable({}, SliderUI)
    
    self.Value = initialValue or 0.5
    self.OnChanged = nil -- Callback
    
    -- Main Container
    local container = Instance.new("Frame")
    container.Name = title .. "Slider"
    container.Size = UDim2.new(1, 0, 0, 40)
    container.BackgroundTransparency = 1
    container.Parent = parent
    self.Instance = container

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title:upper()
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 12
    titleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    titleLabel.Size = UDim2.new(1, 0, 0, 12)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = container

    -- Track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, 0, 0, 3)
    track.Position = UDim2.new(0, 0, 0, 25)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    track.BorderSizePixel = 0
    track.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = track

    -- Fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(self.Value, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromHex("#8A2BE2")
    fill.BorderSizePixel = 0
    fill.Parent = track
    self.Fill = fill

    Instance.new("UICorner").Parent = fill

    -- Knob
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(self.Value, 0, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Parent = track
    self.Knob = knob

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    local knobStroke = Instance.new("UIStroke")
    knobStroke.Thickness = 2
    knobStroke.Color = Color3.fromHex("#8A2BE2")
    knobStroke.Parent = knob

    -- Drag Logic
    local dragging = false

    local function updateValue(input)
        local relativeX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        self.Value = relativeX
        
        -- Smooth visual update
        TweenService:Create(knob, TweenInfo.new(0.1), {Position = UDim2.new(relativeX, 0, 0.5, 0)}):Play()
        TweenService:Create(fill, TweenInfo.new(0.1), {Size = UDim2.new(relativeX, 0, 1, 0)}):Play()
        
        if self.OnChanged then
            self.OnChanged(relativeX)
        end
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateValue(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input)
        end
    end)

    return self
end

function SliderUI:SetValue(val)
    self.Value = math.clamp(val, 0, 1)
    self.Knob.Position = UDim2.new(self.Value, 0, 0.5, 0)
    self.Fill.Size = UDim2.new(self.Value, 0, 1, 0)
end

return SliderUI
