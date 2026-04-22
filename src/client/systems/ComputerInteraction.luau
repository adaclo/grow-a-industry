local Workspace = game:GetService("Workspace")

local ComputerInteraction = {}
ComputerInteraction.__index = ComputerInteraction

function ComputerInteraction.new(computerMenuInstance)
    local self = setmetatable({}, ComputerInteraction)
    self.ComputerMenu = computerMenuInstance
    self.isMenuOpen = false

    -- Find Interaction Part and Prompt
    local studio = Workspace:WaitForChild("Studio")
    local upgrades = studio:WaitForChild("ComputerUpgrades")
    local interactionPart = upgrades:WaitForChild("InteractionPart")
    local prompt = interactionPart:WaitForChild("ProximityPrompt")

    -- Configure Prompt
    prompt.ActionText = "Use Computer"
    prompt.ObjectText = "Studio PC"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 8

    -- Trigger Logic
    prompt.Triggered:Connect(function()
        if self.isMenuOpen then return end
        
        self.isMenuOpen = true
        prompt.Enabled = false -- Temporarily disable prompt while menu is open

        self.ComputerMenu:Open(function()
            -- Callback when menu is closed
            self.isMenuOpen = false
            prompt.Enabled = true
        end)
    end)

    return self
end

return ComputerInteraction
