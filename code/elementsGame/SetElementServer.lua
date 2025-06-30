--!strict
local Players            = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local elementSettings = require(ReplicatedStorage.Modules.ElementSettings) :: { [string]: any }
local cycleRem        = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CycleElement") :: RemoteEvent

local elements = {}
for name,_ in pairs(elementSettings) do
	table.insert(elements, name)
end
table.sort(elements)

local lastCycle : { [Player]: number } = {}

cycleRem.OnServerEvent:Connect(function(player: Player, index: number)
	-- Check if cycling is on cooldown
	if lastCycle[player] and tick() - lastCycle[player] < 0.25 then return end
	
	lastCycle[player] = tick()
	
	-- find their character and Configuration folder

	local char : Model? = player.Character
	if not char then return end

	local cfg : Folder? = char:FindFirstChild("Configuration") :: Folder
	if not cfg then return end

	-- ensure CurrentElement exists
	local curVal : StringValue? = cfg:FindFirstChild("CurrentElement") :: StringValue
	if not curVal then return end

	curVal.Value = elements[index]
end)
