--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Modules.Fusion)
local UserInputService = game:GetService("UserInputService")

local player : Player? = Players.LocalPlayer
if not player then return end

local Value = Fusion.Value
local Computed = Fusion.Computed
local New = Fusion.New
local Children = Fusion.Children

local cycleRem = ReplicatedStorage.Remotes:WaitForChild("CycleElement") :: RemoteEvent
local cooldownUpdateEvent = ReplicatedStorage.Remotes:WaitForChild("CooldownUpdate") :: RemoteEvent

local elementSettings = require(ReplicatedStorage.Modules.ElementSettings) :: { [string]: any }

local lastCycle

-- Get sorted keys
local elements = {}
for key in pairs(elementSettings) do
	table.insert(elements, key)
end
table.sort(elements)

local startElement = "Poison"
local clientIndex

for i, name in ipairs(elements) do
	if name == startElement then
		clientIndex = i
		break
	end
end

-- Create a scope for state management
local scope = Fusion:scoped()

local currentIndex = scope:Value(clientIndex)

local currentElement = scope:Computed(function(use)
	return elements[use(currentIndex)]
end)

-- Local cooldown store
local cooldownStore: { [string]: number } = {}

-- Reactive value to force UI updates
local cooldownTrigger = scope:Value(tick())

-- Update cooldowns from server
cooldownUpdateEvent.OnClientEvent:Connect(function(elementName: string)
	local duration = elementSettings[elementName].Cooldown
	cooldownStore[elementName] = tick() + duration
end)

-- Per-frame update to tick cooldownTrigger (forces Computed reevaluation)
game:GetService("RunService").RenderStepped:Connect(function()
	cooldownTrigger:set(tick()) -- I'm new to fusion so I'm not usre if there's a better way for this.
end)

local currentCooldown = scope:Computed(function(use)
	use(cooldownTrigger) -- track time changes
	local elementName = use(currentElement)
	local expiration = cooldownStore[elementName]

	if not expiration then return "Ready" end

	local remaining = expiration - tick()
	return remaining > 0 and string.format("%.1f s", remaining) or "Ready"
end)


local currentColor = scope:Computed(function(use)
	local settings = elementSettings[use(currentElement)]
	return settings and settings.Color or Color3.fromRGB(255,255,255)
end)

local tweenColor = scope:Spring(currentColor, 30, 3)

local function cycle(step: number)
	clientIndex += step

	if clientIndex < 1 then
		clientIndex = #elements
	elseif clientIndex > #elements then
		clientIndex = 1
	end

	currentIndex:set(clientIndex)
	cycleRem:FireServer(clientIndex)
end

local gui = scope:New "ScreenGui"{
	Name = "ElementCycler",
	ResetOnSpawn = false,
	Parent = player:WaitForChild("PlayerGui"),

	[Children] = {
		scope:New "Frame"{
			Name = "Container",
			Position = UDim2.fromScale(0.025, 0.8),
			Size = UDim2.fromScale(.2, .15),
			BackgroundColor3 = Color3.fromRGB(36, 36, 36),

			[Children] = {
				scope:New "TextLabel"{
					Name = "ElementName",
					Font = Enum.Font.SourceSansBold,
					Text = currentElement,
					Size = UDim2.fromScale(1,.8),
					Position = UDim2.fromScale(0,0),
					TextScaled = true,
					BackgroundTransparency = 1,
					TextColor3 = scope:Computed(function(use)
						return use(tweenColor)
					end)
				},
				scope:New "TextLabel"{
					Name = "ElementCooldown",
					Font = Enum.Font.SourceSansBold,
					Text = currentCooldown,
					Size = UDim2.fromScale(1,.4),
					Position = UDim2.fromScale(0,.6),
					TextScaled = true,
					BackgroundTransparency = 1,
					TextColor3 = scope:Computed(function(use)
						return use(tweenColor)
					end)
				},
				scope:New "UICorner"{
					Name = "UICorner",
					CornerRadius = UDim.new(0, 8)
				}
			}
		}
	}
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if lastCycle and tick() - lastCycle < 0.25 then return end

	lastCycle = tick()

	if input.KeyCode == Enum.KeyCode.Q then
		cycle(-1)
	elseif input.KeyCode == Enum.KeyCode.E then
		cycle(1)
	end
end)
