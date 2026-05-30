local Players = game:GetService("Players")
local SharedModules = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameSystem")
local EventBus = require(SharedModules:WaitForChild("Architecture"):WaitForChild("EventBus"))
local DecisionPopup = require(script.Parent:WaitForChild("DecisionPopup"))

local NotificationQueue = {}
NotificationQueue.__index = NotificationQueue

function NotificationQueue.new(_parentGui)
    local self = setmetatable({}, NotificationQueue)

    -- Persistent ScreenGui (survives MainMenu destruction)
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "NotificationQueueGui"
    notifGui.DisplayOrder = 950
    notifGui.ResetOnSpawn = false
    notifGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = notifGui

    self.Popup = DecisionPopup.new(notifGui)
    self.Queue = {}
    self.IsShowing = false

    -- Container for the little badges
    local badgeContainer = Instance.new("Frame")
    badgeContainer.Name = "NotificationBadgeContainer"
    badgeContainer.Size = UDim2.new(0, 250, 0, 300)
    badgeContainer.Position = UDim2.new(1, -270, 0, 80)
    badgeContainer.BackgroundTransparency = 1
    badgeContainer.Parent = notifGui
    self.BadgeContainer = badgeContainer

    local layout = Instance.new("UIListLayout", badgeContainer)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.VerticalAlignment = Enum.VerticalAlignment.Top

    EventBus.Subscribe("REACTIVE_EVENT_TRIGGERED", function(payload)
        self:AddEventToQueue(payload.EventData)
    end)

    EventBus.Subscribe("READABILITY_NOTIFICATION", function(payload)
        self:ShowReadabilityBadge(payload.Text, payload.Type)
    end)
 
    return self
end

function NotificationQueue:ShowReadabilityBadge(text, typeStr)
    local btn = Instance.new("TextLabel")
    btn.Text = " " .. text
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.TextWrapped = true
    btn.TextXAlignment = Enum.TextXAlignment.Left
    
    if typeStr == "Negative" then
        btn.BackgroundColor3 = Color3.fromHex("#FF4444")
    elseif typeStr == "Positive" then
        btn.BackgroundColor3 = Color3.fromHex("#4BB543")
    elseif typeStr == "NARRATIVE" then
        btn.BackgroundColor3 = Color3.fromHex("#00BFFF") -- Deep Sky Blue for narrative
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
    else
        btn.BackgroundColor3 = Color3.fromHex("#8A2BE2") -- Accent
    end
    
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.Parent = self.BadgeContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    -- Auto-dismiss logic (narrative stays longer)
    local displayTime = typeStr == "NARRATIVE" and 8 or 4
    
    task.delay(displayTime, function()
        if btn and btn.Parent then
            local ts = game:GetService("TweenService")
            local t = ts:Create(btn, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1})
            t:Play()
            t.Completed:Connect(function() btn:Destroy() end)
        end
    end)
end
 
function NotificationQueue:AddEventToQueue(eventData)
    if not eventData then return end
    print("[NotificationQueue] Event added to queue:", eventData.Id)
 
    local btn = Instance.new("TextButton")
    btn.Text = "🔔 " .. (eventData.Title or "NEW EVENT")
    btn.Size = UDim2.new(1, 0, 0, 45)
    
    if eventData.Consequences and eventData.Consequences.Type == "Negative" then
        btn.BackgroundColor3 = Color3.fromHex("#FF4444")
    else
        btn.BackgroundColor3 = Color3.fromHex("#FFA500")
    end
    
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = self.BadgeContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
 
    btn.MouseButton1Click:Connect(function()
        btn:Destroy()
        self:ShowEvent(eventData)
    end)
end
 
function NotificationQueue:ShowEvent(eventData)
    if self.IsShowing then return end
    self.IsShowing = true
    
    -- Normalize: NarrativeChainSystem puts Options inside Consequences
    if not eventData.Options and eventData.Consequences and eventData.Consequences.Options then
        eventData.Options = eventData.Consequences.Options
    end
    
    if not eventData.Options or #eventData.Options == 0 then
        print("[NotificationQueue] WARNING: Event has no Options, cannot show popup:", eventData.Id)
        self.IsShowing = false
        return
    end
    
    self.Popup:Show(eventData, function(choicePayload)
        self.IsShowing = false
        if choicePayload then
            print("[NotificationQueue] Choice resolved. Emitting REACTIVE_EVENT_CHOICE_RESOLVED with payload.")
            EventBus.Emit("REACTIVE_EVENT_CHOICE_RESOLVED", choicePayload)
            EventBus.Emit("SHOW_RESULT_POPUP", choicePayload)
        end
    end)
end
 
return NotificationQueue
