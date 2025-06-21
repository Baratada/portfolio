local DungeonGenerator = {}
 
-- Type definitions for code clarity
type WeightedChoice = { template: Model, weight: number }
type ConnectorData = { Offset: Vector3, Facing: Vector3 }
type ConnectorEntry = { room: Model, conn: BasePart, gx: number, gz: number }
type TryPlaceEntry = { room: Model, conn: BasePart, attempts: number? }
type OpenConnector = { room: Model, conn: BasePart, attempts: number? }
type DungeonContext = {
    Model: Model, -- Container for all dungeon rooms
    Theme: string, -- Visual theme for rooms
    MaxRooms: number, -- Maximum rooms to generate
    StartPos: CFrame, -- Starting position for root room
    PlacedRooms: { Model }, -- List of successfully placed rooms
    Occupied: { [Vector3]: boolean }, -- Grid tracking occupied space
    ShopRoom: Model?, -- Reference to shop room template
    ShopPlaced: boolean, -- Flag if shop has been placed
    ExitPlaced: boolean, -- Flag if Exit teleporter has been placed
    OpenConnectors: { OpenConnector },  -- Available connectors for expansion
}
 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RS_Generation = ReplicatedStorage:WaitForChild("RoomGeneration")
local RS_Rooms = RS_Generation:WaitForChild("Rooms")
 
-- Configuration constants
local GRID_SIZE: number = 48 -- Configurable grid size (studs), basically the dungeon is generated using grids, meaning its generated in 2D space then later converted to 3D space via worldPos
local GRID_RESOLUTION: number = 2 -- Subdivisions per grid cell AKA. how many sub-grids per full grid (higher = finer collision detection allowing for more radical room shapes and sizes)
local SUBCELL_INSET: number = 0.05 -- Fraction (0–0.5) to inset from room bounds when sampling sub‑cells. This is used to relax 2D grid collision checks, so rooms can spawn more leniently
 
local Dungeon = {}
Dungeon.__index = Dungeon
 
-- Snap to sub-grid coordinates, takes vector3 coordinates and turns them into grid coords which are basically vector2
function Dungeon:gridCoords(x: number, z: number): (number, number)
    local subSize = GRID_SIZE / GRID_RESOLUTION
    return math.floor(x / subSize + 0.5), math.floor(z / subSize + 0.5)
end
 
-- Get world position from sub-grid coordinates, opposite of gridCoords, takes grid coords and turns them into vector3 for placing new rooms
function Dungeon:worldPos(gx: number, gz: number, y: number): Vector3
    local subSize = GRID_SIZE / GRID_RESOLUTION
    return Vector3.new(gx * subSize, y, gz * subSize)
end
 
--[[
Weighted random selection, takes the weight of all rooms then pulls a random number from 0 to the total weight, then returns the room with the weight that is greater than the random number.
Otherwise, subtract the current weight from r and continue to the next choice, this gives rooms with higher weights a higher chance to be chosen, while still allowing lower-weight (rarer) rooms to appear.
]]
function Dungeon:weightedRandom(choices: { WeightedChoice }): Model?
    -- Calculate total weight of all choices
    local totalW: number = 0
    for _, w in ipairs(choices) do
        totalW += w.weight  -- Sum all weights in the choices table
    end
 
    -- Early exit if no valid choices (prevents division by zero)
    if totalW <= 0 then
        return nil
    end
 
    -- Generate random number in range [0, totalW)
    local r: number = math.random() * totalW
 
    -- Find which choice corresponds to the random number
    for _, w in ipairs(choices) do
        r -= w.weight  -- Subtract current weight from random value
 
        -- When r becomes <= 0, we've found our selection
        if r <= 0 then
            return w.template
        end
    end
 
    -- Fallback return (should only happen with floating-point precision edge cases lol)
    return nil
end
 
-- Analyzes a room template to get connector positions and orientations
function Dungeon:getConnectorInfo(template: Model): { ConnectorData }
    -- I use probes (temporary clones of the room template) to checkl the connector positions and orientations relative to the room's center without affecting the original template or the dungeon.
    local probe = template:Clone()
    probe.Parent = workspace
    probe:PivotTo(CFrame.new(0, 0, 0))
 
    local connectorData: { ConnectorData } = {}
    for _, c in ipairs(probe:GetDescendants()) do
        if c.Name == "Connector" and c:IsA("BasePart") then
            -- Calculate position relative to room center
            local localOffset = probe:GetPivot():PointToObjectSpace(c.Position)
            -- Calculate world-space facing direction
            local localFacing = (probe:GetPivot():ToWorldSpace(c.CFrame)).LookVector
            table.insert(connectorData, { Offset = localOffset, Facing = localFacing })
        end
    end
 
    probe:Destroy()
    return connectorData
end
 
-- Checks if a room placement would overlap existing rooms
function Dungeon:collectSubgridCells(cframe: CFrame, size: Vector3): { string }?
    local subSize = GRID_SIZE / GRID_RESOLUTION
    local half = size / 2
    local inset = subSize * SUBCELL_INSET
    local cells: { string } = {}
 
    -- Scan through all subcells the room would occupy
    for dx = -half.X + inset, half.X - inset - 1e-3, subSize do
        for dz = -half.Z + inset, half.Z - inset - 1e-3, subSize do
            -- Calculate world position of subcell center
            local wp: Vector3 = cframe.Position
                + cframe:VectorToWorldSpace(Vector3.new(dx + subSize / 2, 0, dz + subSize / 2))
            local gx, gz = self:gridCoords(wp.X, wp.Z)
            local key = ("%d,%d"):format(gx, gz)
 
            -- Return nil if any cell is already occupied
            if self.Context.Occupied[key] then
                return nil
            end
            table.insert(cells, key)
        end
    end
 
    return cells
end
 
-- Marks grid cells as occupied after successful room placement
function Dungeon:markSubgridCells(cells: { string })
    for _, key in ipairs(cells) do
        self.Context.Occupied[key] = true
    end
end
 
-- Places the starting room and initializes grid occupancy
function Dungeon:placeStartRoom(): Model
    local startPrefab = RS_Rooms:FindFirstChild("StartRoom") :: Model
    assert(startPrefab, "Missing StartRoom prefab")
 
    local startRoom = startPrefab:Clone()
    startRoom:PivotTo(self.Context.StartPos)
    startRoom.Parent = self.Context.Model
 
    -- Mark all occupied grid cells
    local cframe, size = startRoom:GetBoundingBox()
    local halfSize = size / 2
    local subSize = GRID_SIZE / GRID_RESOLUTION
    local inset = subSize * SUBCELL_INSET
 
    --[[
    Iterate through X-axis grid positions covering the room's width
    Start from left edge (-halfSize.X) plus inset buffer
    End at right edge (halfSize.X) minus inset and small epsilon (1e-3) to prevent floating point errors
    Step by subcell size (subSize) to check each grid position]]
    for dx = -halfSize.X + inset, halfSize.X - inset - 1e-3, subSize do
        -- Iterate through Z-axis grid positions covering the room's depth
        -- Same logic as X-axis but for forward/backward direction
        for dz = -halfSize.Z + inset, halfSize.Z - inset - 1e-3, subSize do
 
            --[[ Calculate world position of current grid cell center:
            1. Start from room's center position (cframe.Position)
            2. Add offset in room's local X direction (dx + subSize/2 to get cell center)
            3. Add offset in room's local Z direction (dz + subSize/2)
            4. Transform local offset to world space using room's orientation]]
            local worldPoint = cframe.Position
                + cframe:VectorToWorldSpace(Vector3.new(
                    dx + subSize / 2,  -- Center of current X cell segment
                    0,                 -- Ignore Y-axis cause I'm transforming into 2D, which has no Y-axis
                    dz + subSize / 2    -- Center of current Z cell segment
                    ))
 
            -- Convert world coordinates to integer grid coordinates
            local gx, gz = self:gridCoords(worldPoint.X, worldPoint.Z)
 
            -- Mark this grid cell as occupied using "x,z" string format as key
            self.Context.Occupied[("%d,%d"):format(gx, gz)] = true
        end
    end
 
    return startRoom
end
 
-- Creates weighted room list based on current dungeon state
function Dungeon:buildWeightedList(entryRoomName: string): ({ WeightedChoice }, boolean)
    local weightedList: { WeightedChoice } = {}
    local shopPlaced = self.Context.ShopPlaced
    local placedCount = #self.Context.PlacedRooms
    local maxRooms = self.Context.MaxRooms
 
    -- Get theme-specific rooms
    local themeFolder = RS_Rooms:FindFirstChild(self.Context.Theme) or RS_Rooms:FindFirstChild("Hokma") :: Folder
 
    -- Special handling for abnormality hub rooms, overrides all room options to be abnormality rooms, which is a special type of room that should always be connected to "abnormality hubs"
    if entryRoomName == "AbnormalityHub" then
        local abnormalityFolder = themeFolder:FindFirstChild("Abnormality")
        for _, prefab in ipairs(abnormalityFolder:GetChildren()) do
            if prefab:IsA("Model") then
                table.insert(weightedList, { template = prefab, weight = 1 })
            end
        end
    else
        -- Possible choices for the weight-based picker
        local tiers = {
            { folderName = "Common", weight = 45 },
            { folderName = "Uncommon", weight = 25 },
            { folderName = "Rare", weight = 18 },
            { folderName = "Unique", weight = 3 },
            { folderName = "Abnormality", weight = 1 },
        }
 
        for _, tierInfo in ipairs(tiers) do
            local folderInst = themeFolder:FindFirstChild(tierInfo.folderName)
            if folderInst then
                for _, prefab in ipairs(folderInst:GetChildren()) do
                    if prefab:IsA("Model") then
                        table.insert(weightedList, { template = prefab, weight = tierInfo.weight })
                    end
                end
            end
        end
    end
 
    -- Shop placement logic (only if not already placed, basically how this works is the shop has a 5% chance of spawning as the first room other than the root room, with each new placement the shop room placement increases in probability
    if not shopPlaced and self.Context.ShopRoom then
        local shopProg = math.clamp(placedCount / maxRooms, 0, 1)
        local shopChance = 0.05 + shopProg * 0.95
        if math.random() <= shopChance then
            weightedList = {}
            table.insert(weightedList, { template = self.Context.ShopRoom, weight = 1 })
            shopPlaced = true
        end
    end
 
    return weightedList, shopPlaced
end
 
-- Attempts to place a new room at a connector location
function Dungeon:tryPlace(entry: TryPlaceEntry): (boolean, boolean, boolean)
    entry.attempts = (entry.attempts or 0) + 1
 
    -- Skip if connector already used
    if entry.conn:GetAttribute("Connected") then
        return false, self.Context.ShopPlaced, self.Context.ExitPlaced
    end
 
    -- Get valid room options
    local weightedList, newShopPlaced = self:buildWeightedList(entry.room.Name)
    local pick = self:weightedRandom(weightedList)
    if not pick then
        return false, newShopPlaced, self.Context.ExitPlaced
    end
 
    -- Get connector data and prepare rotations
    local connectorData = self:getConnectorInfo(pick)
    local rotations = {0, 90, 180, 270}
    self:shuffle(rotations)  -- Randomize rotation order
 
    local placed = false
    local finalCFrame: CFrame?
    local subCells: {string}?
 
    -- Try all rotation angles
    for _, deg in ipairs(rotations) do
        local rotCF = CFrame.Angles(0, math.rad(deg), 0)
 
        -- Try all connectors in the room template
        for _, cd in ipairs(connectorData) do
            -- Calculate world-space facing direction
            local wf = rotCF:VectorToWorldSpace(cd.Facing)
 
            -- Only consider connectors facing opposite direction
            if wf:Dot(-entry.conn.CFrame.LookVector) < 0.99 then
                continue
            end
 
            -- Calculate placement position
            local rotatedOffset = rotCF:VectorToWorldSpace(cd.Offset)
            local originPos = entry.conn.Position - rotatedOffset
            local targetCFrame = CFrame.new(originPos) * rotCF
 
            -- Check for collisions
            local bboxCF, bboxSize = pick:GetBoundingBox()
            local relativeCF = pick:GetPivot():ToObjectSpace(bboxCF)
            local cells = self:collectSubgridCells(targetCFrame * relativeCF, bboxSize)
 
            if cells then
                -- Valid placement found
                finalCFrame = targetCFrame
                subCells = cells
                placed = true
                break
            end
        end
        if placed then break end
    end
 
    -- Retry if placement failed (up to 5 attempts)
    if not placed then
        if entry.attempts < 5 then
            return self:tryPlace(entry)
        end
        return false, newShopPlaced, self.Context.ExitPlaced
    end
 
    -- Place the room
    local newRoom = pick:Clone()
    newRoom:PivotTo(finalCFrame :: CFrame)
    newRoom.Parent = self.Context.Model
    self:markSubgridCells(subCells :: {string})
    entry.conn:SetAttribute("Connected", true)
 
    -- Connect to nearest matching connector
    local closestConn: BasePart?
    local minDist = math.huge
    local parentPos = entry.conn.Position
 
    for _, conn in ipairs(newRoom:GetDescendants()) do
        if conn:IsA("BasePart") and conn.Name == "Connector" then
            local dist = (conn.Position - parentPos).Magnitude
            if dist < minDist then
                minDist = dist
                closestConn = conn
            end
        end
    end
 
    -- Mark as connected if close enough
    if closestConn and minDist < (GRID_SIZE / GRID_RESOLUTION) * 0.5 then
        closestConn:SetAttribute("Connected", true)
    end
 
    -- Update room tracking
    table.insert(self.Context.PlacedRooms, newRoom)
 
    -- Exit teleporter placement logic
    if not self.Context.ExitPlaced and #self.Context.PlacedRooms >= math.floor(self.Context.MaxRooms * 0.5) then
        local progress = math.clamp((#self.Context.PlacedRooms - self.Context.MaxRooms * 0.5) / (self.Context.MaxRooms * 0.5), 0, 1)
 
        if math.random() < progress then
            local candidates = {}
            for _, conn in ipairs(newRoom:GetDescendants()) do
                if conn:IsA("BasePart") and conn.Name == "Connector" and not conn:GetAttribute("Connected") then
                    table.insert(candidates, conn)
                end
            end
 
            if #candidates > 0 then
                local chosen = candidates[math.random(#candidates)]
                chosen:SetAttribute("Exit", true)
                chosen:SetAttribute("Connected", true)
                self.Context.ExitPlaced = true
            end
        end
    end
 
    -- Update status flags
    self.Context.ShopPlaced = newShopPlaced
    return true, newShopPlaced, self.Context.ExitPlaced
end
 
-- Collect all connectors in all rooms, take their Vector3 and convert it to my grid's Vector2 style.
function Dungeon:gatherOpenConnectors()
    self.Context.OpenConnectors = {}  -- Reset open connectors list
 
    -- Iterate through all placed rooms
    for _, room in ipairs(self.Context.PlacedRooms) do
        -- Iterate through all descendants in the room
        for _, descendant in ipairs(room:GetDescendants()) do
            
            if not (descendant:IsA("BasePart") and descendant.Name == "Connector" and not descendant:GetAttribute("Connected")) then continue end -- Skip the following: non-basepart objects, objects not named "Connector" and finally already connected connectors
 
            -- Calculate grid coordinates for this connector
            local gx, gz = self:gridCoords(descendant.Position.X, descendant.Position.Z)
 
            -- Add valid open connector to list
            table.insert(self.Context.OpenConnectors, {
                room = room,
                conn = descendant,
                gx = gx,
                gz = gz
            })
        end
    end
end
 
-- Updates visual appearance and functionality of all connectors
function Dungeon:updateConnectorVisuals()
    local themeFolder = RS_Rooms:FindFirstChild(self.Context.Theme) or RS_Rooms:FindFirstChild("Hokma")
 
    for _, room in ipairs(self.Context.Model:GetChildren()) do
        if not room:IsA("Model") then continue end
 
        for _, conn in ipairs(room:GetDescendants()) do
            if not (conn:IsA("BasePart") and conn.Name == "Connector") then continue end
 
            -- Add a prompt to the connector that contains the attribute Exit so the player can teleport out of the dungeon
            if conn:GetAttribute("Exit") then
                conn.Transparency = 0
                conn.CanCollide = false
                conn.Material = Enum.Material.Neon
                conn.Color = Color3.fromRGB(255, 0, 0)
                conn.Name = "Exit"
                room.Name = "ExitRoom"
 
                -- Create teleportation prompt
                local prompt = Instance.new("ProximityPrompt")
                prompt.ActionText = "Leave Dungeon"
                prompt.ObjectText = "Exit Gate"
                prompt.RequiresLineOfSight = false
                prompt.MaxActivationDistance = 10
                prompt.Parent = conn
 
                prompt.Triggered:Connect(function(player)
                    local char = player.Character
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    hrp.CFrame = CFrame.new(500,25,500)
                end)
                continue
            end
 
            -- Handle normal connectors
            local isConnected = conn:GetAttribute("Connected")
            local isExit = conn:GetAttribute("Exit")
 
            -- Unreachable connector AKA. connector that leads to the outside world or to a room that isn't accessible from that direction.
            if not isConnected then
                conn.Transparency = 0
                conn.CanCollide = true
                conn.Color = Color3.fromRGB(128, 128, 128)
                continue
            end
            
            if isExit then continue end
            -- Invisible passage for connected connectors
            conn.Transparency = 1
            conn.CanCollide = false
        end
    end
end
 
-- Randomizes array order using Fisher-Yates algorithm
function Dungeon:shuffle(t: { any })
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end
 
-- Main dungeon generation entry point
function DungeonGenerator.GenerateDungeon(theme: string, maxRooms: number?, startPos: CFrame?): DungeonContext
    -- Validate input parameters
    assert(type(theme) == "string" and theme ~= "", "Theme must be non-empty string")
    if maxRooms then assert(maxRooms > 0, "maxRooms must be positive") end
    if startPos then assert(typeof(startPos) == "CFrame", "startPos must be CFrame") end
 
    -- Initialize dungeon state
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
        ExitPlaced = false,
        OpenConnectors = {},
    }
    self.Context.Model.Name = "Dungeon"
    self.Context.Model.Parent = workspace
 
    -- Load theme-specific assets
    local themeFolder = RS_Rooms:FindFirstChild(theme)
    if themeFolder then
        self.Context.ShopRoom = themeFolder:FindFirstChild("ShopRoom") or nil
    end
 
    -- Place starting room
    local startRoom = self:placeStartRoom()
    table.insert(self.Context.PlacedRooms, startRoom)
 
    -- Initialize open connectors
    for _, c in ipairs(startRoom:GetDescendants()) do
        if c:IsA("BasePart") and c.Name == "Connector" then
            table.insert(self.Context.OpenConnectors, { room = startRoom, conn = c })
        end
    end
 
    -- Main generation loop
    while #self.Context.PlacedRooms < self.Context.MaxRooms and #self.Context.OpenConnectors > 0 do
        self:shuffle(self.Context.OpenConnectors)
        local entry = table.remove(self.Context.OpenConnectors, math.random(#self.Context.OpenConnectors))
 
        -- Skip already connected connectors
        if entry.conn:GetAttribute("Connected") then
            continue
        end
 
        -- Attempt room placement
        local success, newShopPlaced, newExitPlaced = self:tryPlace(entry)
        self.Context.ShopPlaced = newShopPlaced
        self.Context.ExitPlaced = newExitPlaced
 
        if success then
            -- Add new room's connectors to open list
            local newRoom = self.Context.PlacedRooms[#self.Context.PlacedRooms]
            for _, c in ipairs(newRoom:GetDescendants()) do
                if c:IsA("BasePart") and c.Name == "Connector" and not c:GetAttribute("Connected") then
                    table.insert(self.Context.OpenConnectors, { room = newRoom, conn = c })
                end
            end
        elseif entry.attempts < 10 then
            -- Retry placement later
            entry.attempts = (entry.attempts or 0) + 1
            table.insert(self.Context.OpenConnectors, entry)
        end
    end
 
    -- Cleanup helper parts
    for _, inst in ipairs(self.Context.Model:GetDescendants()) do
        if inst.Name:lower():find("node") or inst.Name == "PrimaryPart" then
            inst.Transparency = 1
            inst.CanCollide = false
        end
    end
 
    -- Finalize connector visuals
    self:updateConnectorVisuals()
 
    return self.Context
end
 
return DungeonGenerator
 
-- HOW TO CALL: DungeonGenerator.GenerateDungeon("Hokma", 50, CFrame.new(0,13.5,0)) Generate the dungeon with theme "Hokma", 50 max rooms, and starting position at 0, 13.5, 0
 
-- Thanks for reading!