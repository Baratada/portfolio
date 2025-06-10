--!nonstrict
local DungeonGenerator = {}

type WeightedChoice = { template: Model, weight: number }
type ConnectorData = { Offset: Vector3, Facing: Vector3 }
type ConnectorEntry = { room: Model, conn: BasePart, gx: number, gz: number }
type TryPlaceEntry = { room: Model, conn: BasePart, attempts: number? }
type OpenConnector = { room: Model, conn: BasePart, attempts: number? }
type DungeonContext = {
	Model: Model,
	Theme: string,
	MaxRooms: number,
	StartPos: CFrame,
	PlacedRooms: { Model },
	Occupied: { [Vector3]: boolean },
	ShopRoom: Model?,
	ShopPlaced: boolean,
	BossPlaced: boolean,
	BossRoom: Model?,
	OpenConnectors: { { room: Model, conn: BasePart, attempts: number? } },
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RS_Generation = ReplicatedStorage:WaitForChild("RoomGeneration")
local RS_Rooms = RS_Generation:WaitForChild("Rooms")

local GRID_SIZE: number = 48
local GRID_RESOLUTION: number = 2
local OVERLAP_SCALE: number = 0.9
local SUBCELL_INSET: number = 0.05

-- Definition of Dungeon methods and state
local Dungeon = {}
Dungeon.__index = Dungeon

-- Convert world X,Z to integer subgrid coordinates
function Dungeon:gridCoords(x: number, z: number): (number, number)
	local subSize = GRID_SIZE / GRID_RESOLUTION
	return math.floor(x / subSize + 0.5), math.floor(z / subSize + 0.5)
end

-- Convert subgrid coordinates back to a world Vector3
function Dungeon:worldPos(gx: number, gz: number, y: number): Vector3
	local subSize = GRID_SIZE / GRID_RESOLUTION
	return Vector3.new(gx * subSize, y, gz * subSize)
end

-- Weighted random choice from a list of templates
function Dungeon:weightedRandom(choices: { WeightedChoice }): Model?
	local totalW: number = 0
	for _, w in ipairs(choices) do
		totalW += w.weight
	end

	local r: number = math.random() * totalW
	for _, w in ipairs(choices) do
		r -= w.weight
		if r <= 0 then
			return w.template
		end
	end

	return nil
end

-- Extract connector offsets and facing vectors from a room prefab
function Dungeon:getConnectorInfo(template: Model): { ConnectorData }
	local probe = template:Clone()
	probe.Parent = workspace
	probe:PivotTo(CFrame.new(0, 0, 0))

	local connectorData: { ConnectorData } = {}
	for _, c in ipairs(probe:GetDescendants()) do
		if c.Name == "Connector" and c:IsA("BasePart") then
			local localOffset = probe:GetPivot():PointToObjectSpace(c.Position)
			local localFacing = (probe:GetPivot():ToWorldSpace(c.CFrame)).LookVector
			table.insert(connectorData, { Offset = localOffset, Facing = localFacing })
		end
	end

	probe:Destroy()
	return connectorData
end

-- Collect subgrid cells covered by a bounding box if none are already occupied
function Dungeon:collectSubgridCells(cframe: CFrame, size: Vector3): { string }?
	local subSize = GRID_SIZE / GRID_RESOLUTION
	local half = size / 2
	local inset = subSize * SUBCELL_INSET
	local cells: { string } = {}

	for dx = -half.X + inset, half.X - inset - 1e-3, subSize do
		for dz = -half.Z + inset, half.Z - inset - 1e-3, subSize do
			local wp: Vector3 = cframe.Position
				+ cframe:VectorToWorldSpace(Vector3.new(dx + subSize / 2, 0, dz + subSize / 2))
			local gx, gz = self:gridCoords(wp.X, wp.Z)
			local key = ("%d,%d"):format(gx, gz)

			if self.Context.Occupied[key] then
				return nil
			end
			table.insert(cells, key)
		end
	end

	return cells
end

-- Mark a list of cells as occupied
function Dungeon:markSubgridCells(cells: { string })
	for _, key in ipairs(cells) do
		self.Context.Occupied[key] = true
	end
end

-- Place the StartRoom at StartPos and mark its occupied cells
function Dungeon:placeStartRoom(): Model
	local startPrefab = RS_Rooms:FindFirstChild("StartRoom") :: Model
	assert(startPrefab and startPrefab:IsA("Model"), "Missing StartRoom prefab")

	local startRoom = startPrefab:Clone()
	startRoom:PivotTo(self.Context.StartPos)
	startRoom.Parent = self.Context.Model

	local cframe, size = startRoom:GetBoundingBox()
	local halfSize = size / 2
	local subSize = GRID_SIZE / GRID_RESOLUTION
	local inset = subSize * SUBCELL_INSET

	for dx = -halfSize.X + inset, halfSize.X - inset - 1e-3, subSize do
		for dz = -halfSize.Z + inset, halfSize.Z - inset - 1e-3, subSize do
			local worldPoint = cframe.Position
				+ cframe:VectorToWorldSpace(Vector3.new(dx + subSize / 2, 0, dz + subSize / 2))
			local gx, gz = self:gridCoords(worldPoint.X, worldPoint.Z)
			self.Context.Occupied[("%d,%d"):format(gx, gz)] = true
		end
	end

	return startRoom
end

-- Assemble a weighted list of possible next rooms based on theme and shop state
function Dungeon:buildWeightedList(entryRoomName: string): ({ WeightedChoice }, boolean)
	local weightedList: { WeightedChoice } = {}
	local shopPlaced = self.Context.ShopPlaced
	local placedCount = #self.Context.PlacedRooms
	local maxRooms = self.Context.MaxRooms

	local themeFolderInstance = RS_Rooms:FindFirstChild(self.Context.Theme)
	local themeFolder: Folder = if themeFolderInstance and themeFolderInstance:IsA("Folder")
		then themeFolderInstance
		else RS_Rooms:FindFirstChild("Hokma") :: Folder

	if entryRoomName == "AbnormalityHub" then
		local abnormalityFolder = themeFolder:FindFirstChild("Abnormality")
		assert(abnormalityFolder and abnormalityFolder:IsA("Folder"),
			"Missing Abnormality folder under theme")
		for _, prefab in ipairs(abnormalityFolder:GetChildren()) do
			if prefab:IsA("Model") then
				table.insert(weightedList, { template = prefab, weight = 1 })
			end
		end
	else
		local tiers = {
			{ folderName = "Common", weight = 45 },
			{ folderName = "Uncommon", weight = 25 },
			{ folderName = "Rare", weight = 18 },
			{ folderName = "Unique", weight = 3 },
			{ folderName = "Abnormality", weight = 1 },
		}

		for _, tierInfo in ipairs(tiers) do
			local folderInst = themeFolder:FindFirstChild(tierInfo.folderName)
			if folderInst and folderInst:IsA("Folder") then
				for _, prefab in ipairs(folderInst:GetChildren()) do
					if prefab:IsA("Model") then
						table.insert(weightedList, { template = prefab, weight = tierInfo.weight })
					end
				end
			end
		end
	end

	if not shopPlaced then
		local shopProg = math.clamp(placedCount / maxRooms, 0, 1)
		local shopChance = 0.05 + shopProg * 0.95
		if math.random() <= shopChance and self.Context.ShopRoom then
			weightedList = {}
			table.insert(weightedList, { template = self.Context.ShopRoom, weight = 1 })
			shopPlaced = true
		end
	end

	return weightedList, shopPlaced
end

-- Try placing a new room at a given connector; returns success and updated shop/boss flags
function Dungeon:tryPlace(entry: TryPlaceEntry): (boolean, boolean, boolean)
	entry.attempts = entry.attempts or 0
	local parentConn: BasePart = entry.conn

	if parentConn:GetAttribute("Connected") then
		return false, self.Context.ShopPlaced, self.Context.BossPlaced
	end

	local parentPos = parentConn.Position
	local parentFacing = parentConn.CFrame.LookVector
	parentFacing = Vector3.new(math.round(parentFacing.X), 0, math.round(parentFacing.Z))

	local weightedList, newShopPlaced = self:buildWeightedList(entry.room.Name)
	local pick = self:weightedRandom(weightedList)
	if not (pick and pick:IsA("Model")) then
		return false, newShopPlaced, self.Context.BossPlaced
	end

	local connectorData = self:getConnectorInfo(pick)
	local rotations = { 0, 90, 180, 270 }
	for i = #rotations, 2, -1 do
		local j = math.random(i)
		rotations[i], rotations[j] = rotations[j], rotations[i]
	end

	local placed = false
	local finalCFrame: CFrame?
	local subCells: { string }?

	for _, deg in ipairs(rotations) do
		local rotCF = CFrame.Angles(0, math.rad(deg), 0)
		for _, unknownCD in ipairs(connectorData) do
			local cd = unknownCD :: ConnectorData
			local wf = rotCF:VectorToWorldSpace(cd.Facing)
			if wf:Dot(-parentFacing) < 0.99 then
				continue
			end

			local rotatedOffset = rotCF:VectorToWorldSpace(cd.Offset)
			local originPos = parentPos - rotatedOffset
			local targetCFrame = CFrame.new(originPos) * rotCF

			local bboxCF, bboxSize = pick:GetBoundingBox()
			local relativeCF = pick:GetPivot():ToObjectSpace(bboxCF)
			local cells = self:collectSubgridCells(targetCFrame * relativeCF, bboxSize)
			if not cells then
				continue
			end

			finalCFrame = targetCFrame
			subCells = cells
			placed = true
			break
		end
		if placed then
			break
		end
	end

	if not placed then
		local attempts = entry.attempts or 0
		if attempts < 5 then
			return self:tryPlace({
				room = entry.room,
				conn = entry.conn,
				attempts = attempts + 1,
			})
		else
			return false, newShopPlaced, self.Context.BossPlaced
		end
	end

	local newRoom = pick:Clone()
	newRoom.Parent = self.Context.Model
	newRoom:PivotTo(finalCFrame :: CFrame)

	self:markSubgridCells(subCells :: { string })
	parentConn:SetAttribute("Connected", true)

	local best: BasePart? = nil
	local bestDist = math.huge
	local subSize = GRID_SIZE / GRID_RESOLUTION
	for _, c2 in ipairs(newRoom:GetDescendants()) do
		if c2:IsA("BasePart") and c2.Name == "Connector" then
			local d = (c2.Position - parentPos).Magnitude
			if d < bestDist then
				bestDist = d
				best = c2 :: BasePart
			end
		end
	end
	if best and bestDist < (subSize * 0.5) then
		best:SetAttribute("Connected", true)
		best:SetAttribute("IsEntrance", true)
	end

	table.insert(self.Context.PlacedRooms, newRoom)

	if not self.Context.BossPlaced and #self.Context.PlacedRooms >= math.floor(self.Context.MaxRooms :: number * 0.5) then
		local chance = math.clamp((#self.Context.PlacedRooms - self.Context.MaxRooms * 0.5) / (self.Context.MaxRooms * 0.5), 0, 1)
		if math.random() < chance then
			local candidates: { BasePart } = {}
			for _, c in ipairs(newRoom:GetDescendants()) do
				if c:IsA("BasePart") and c.Name == "Connector" and not c:GetAttribute("Connected") then
					table.insert(candidates, c)
				end
			end
			if #candidates > 0 then
				local chosen = candidates[math.random(1, #candidates)]
				chosen:SetAttribute("BossTeleporter", true)
				self.Context.BossPlaced = true
			end
		end
	end

	self.Context.ShopPlaced = newShopPlaced
	return true, newShopPlaced, self.Context.BossPlaced
end

-- Gather all currently open connectors from placed rooms
function Dungeon:gatherOpenConnectors()
	self.Context.OpenConnectors = {}
	for _, room in ipairs(self.Context.PlacedRooms) do
		for _, c in ipairs(room:GetDescendants()) do
			if c:IsA("BasePart") and c.Name == "Connector" and not c:GetAttribute("Connected") then
				local gx, gz = self:gridCoords(c.Position.X, c.Position.Z)
				table.insert(self.Context.OpenConnectors, { room = room, conn = c, gx = gx, gz = gz })
			end
		end
	end
end

-- Update connector visual appearance based on connectivity and NPC presence
function Dungeon:updateConnectorVisuals()
	local NPCs: { Instance } = {}
	if workspace:FindFirstChild("NPCS") then
		NPCs = workspace.NPCS:GetChildren()
	end

	local themeFolderInstance = RS_Rooms:FindFirstChild(self.Context.Theme)
	local themeFolder: Folder = if themeFolderInstance and themeFolderInstance:IsA("Folder")
		then themeFolderInstance
		else RS_Rooms:FindFirstChild("Hokma") :: Folder

	local bossRoom: Model = themeFolder:FindFirstChild("BossRoom") :: Model

	for _, child in ipairs(self.Context.Model:GetChildren()) do
		if not child:IsA("Model") then
			continue
		end
		local room: Model = child

		local cframe, size = room:GetBoundingBox()
		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = NPCs :: { Instance }
		overlapParams.FilterType = Enum.RaycastFilterType.Include

		local parts: { BasePart } = workspace:GetPartBoundsInBox(cframe, size, overlapParams)
		local seenModels: { [Model]: boolean } = {}
		local hasAlive = false

		for _, part in ipairs(parts) do
			local m: Model? = part:FindFirstAncestorOfClass("Model")
			if m and not seenModels[m] then
				seenModels[m] = true
				local h: Humanoid? = m:FindFirstChildWhichIsA("Humanoid")
				if h and h.Health > 0 then
					hasAlive = true
					break
				end
			end
		end

		for _, c in ipairs(room:GetDescendants()) do
			if not (c:IsA("BasePart") and c.Name == "Connector") then
				continue
			end

			if c:GetAttribute("BossTeleporter") then
				c.Transparency = 0
				c.CanCollide = false
				c.Material = Enum.Material.Neon
				c.Color = Color3.fromRGB(255, 0, 0)
				c.Name = "BossTeleport"
				room.Name = "BossTeleporterRoom"

				local prompt = Instance.new("ProximityPrompt")
				prompt.Parent = c
				prompt.ActionText = "Enter Boss Room"
				prompt.ObjectText = "Boss Gate"
				prompt.RequiresLineOfSight = false
				prompt.MaxActivationDistance = 10

				prompt.Triggered:Connect(function(player: Player)
					local char: Model? = player.Character
					if not (char and char:FindFirstChild("HumanoidRootPart")) then
						return
					end
					local spawn: BasePart = bossRoom and bossRoom:FindFirstChild("BossNode", true) :: BasePart
					local targetCFrame: CFrame = if spawn then spawn.CFrame else (bossRoom and bossRoom:GetPivot()) or CFrame.new()
					local hrp: BasePart = char:FindFirstChild("HumanoidRootPart") :: BasePart
					hrp.CFrame = targetCFrame + Vector3.new(40, 0, 0)
				end)

				continue
			end

			local isConnected: boolean = c:GetAttribute("Connected") or false
			local isEntrance: boolean = c:GetAttribute("IsEntrance") or false

			if not isConnected then
				local nearbyParams = OverlapParams.new()
				nearbyParams.FilterType = Enum.RaycastFilterType.Include
				nearbyParams.FilterDescendantsInstances = { self.Context.Model }

				local searchSize = Vector3.new(2, 2, 2)
				local nearbyParts = workspace:GetPartBoundsInBox(c.CFrame, searchSize, nearbyParams)

				for _, np in ipairs(nearbyParts) do
					if np ~= c and np:IsA("BasePart") and np.Name == "Connector" then
						isConnected = true
						break
					end
				end
			end

			if not isConnected then
				c.Transparency = 0
				c.CanCollide = true
				c.Color = Color3.fromRGB(128, 128, 128)
				continue
			end

			if isEntrance or not hasAlive then
				c.Transparency = 1
				c.CanCollide = false
			else
				c.Transparency = 0.5
				c.Material = Enum.Material.ForceField
				c.Color = Color3.fromRGB(255, 0, 0)
				c.CanCollide = true
			end
		end
	end
end

-- Shuffle utility
function Dungeon:shuffle(t: { any })
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
end

-- Public entry point: create and populate a Dungeon instance
function DungeonGenerator.GenerateDungeon(theme: string, maxRooms: number?, startPos: CFrame?): DungeonContext
	assert(type(theme) == "string" and theme ~= "", ("GenerateDungeon: expected non‐empty string `theme`; got %q"):format(tostring(theme)))
	if maxRooms ~= nil then
		assert(type(maxRooms) == "number" and maxRooms > 0, ("GenerateDungeon: expected `maxRooms` > 0 or nil; got %s"):format(tostring(maxRooms)))
	end
	if startPos ~= nil then
		assert(typeof(startPos) == "CFrame", ("GenerateDungeon: expected `startPos` to be CFrame or nil; got %s"):format(tostring(startPos)))
	end

	maxRooms = maxRooms or 20
	startPos = startPos or CFrame.new(0, 13.5, 0)
	math.randomseed(tick())

	local self = setmetatable({}, Dungeon)
	self.Context = {
		Model = Instance.new("Model"),
		Theme = theme,
		MaxRooms = maxRooms,
		StartPos = startPos,
		PlacedRooms = {},
		Occupied = {},
		ShopRoom = nil,
		ShopPlaced = false,
		BossPlaced = false,
		OpenConnectors = {},
	}

	self.Context.Model.Name = "Dungeon"
	self.Context.Model.Parent = workspace

	local themeFolderInstance = RS_Rooms:FindFirstChild(theme)
	if themeFolderInstance and themeFolderInstance:IsA("Folder") then
		local shop = themeFolderInstance:FindFirstChild("ShopRoom")
		if shop and shop:IsA("Model") then
			self.Context.ShopRoom = shop :: Model
		end
	end

	local startRoom = self:placeStartRoom()
	table.insert(self.Context.PlacedRooms, startRoom)

	for _, c in ipairs(startRoom:GetDescendants()) do
		if c:IsA("BasePart") and c.Name == "Connector" then
			table.insert(self.Context.OpenConnectors, { room = startRoom, conn = c })
		end
	end

	while #self.Context.PlacedRooms < self.Context.MaxRooms and #self.Context.OpenConnectors > 0 do
		self:shuffle(self.Context.OpenConnectors)

		local entry = table.remove(self.Context.OpenConnectors, math.random(#self.Context.OpenConnectors))
		if entry.conn:GetAttribute("Connected") then
			continue
		end

		local success, newShopPlaced, newBossPlaced = self:tryPlace(entry)
		self.Context.ShopPlaced = newShopPlaced
		self.Context.BossPlaced = newBossPlaced

		if success then
			local newRoom = self.Context.PlacedRooms[#self.Context.PlacedRooms]
			for _, c in ipairs(newRoom:GetDescendants()) do
				if c:IsA("BasePart") and c.Name == "Connector" and not c:GetAttribute("Connected") then
					table.insert(self.Context.OpenConnectors, { room = newRoom, conn = c, attempts = 0 })
				end
			end
		else
			entry.attempts = (entry.attempts or 0) + 1
			if entry.attempts < 10 then
				table.insert(self.Context.OpenConnectors, entry)
			else
			end
		end
	end

	for _, inst in ipairs(self.Context.Model:GetDescendants()) do
		if inst.Name:lower():find("node") or inst.Name == "PrimaryPart" then
			inst.Transparency = 1
			inst.CanCollide = false
		end
	end

	self:updateConnectorVisuals()

	if workspace:FindFirstChild("NPCS") then
		for _, npc in ipairs(workspace.NPCS:GetChildren()) do
			local h: Humanoid? = npc:FindFirstChildWhichIsA("Humanoid")
			if h then
				h.Died:Connect(function()
					self:updateConnectorVisuals()
				end)
			end
		end
	end

	return self.Context
end

return DungeonGenerator
