--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Hitbox = require(replicatedStorage.Modules:WaitForChild("MuchachoHitbox"))
local Types = require(replicatedStorage.Modules.MuchachoHitbox.Types)

local castRemote = replicatedStorage:WaitForChild("Remotes"):WaitForChild("CastSpellEvent") :: RemoteEvent
local cooldownUpdateEvent = replicatedStorage.Remotes.CooldownUpdate :: RemoteEvent

local GRAVITY = workspace.Gravity

local lastCast : {[Player]: {[string]: number}} = {}
local hitboxes : {[number]: Types.Hitbox} = {}

local elementSettings : { [string]: elementSettings.ElementData } = require(ReplicatedStorage.Modules.ElementSettings) -- An external module script with element settings
local ELEMENTS = {}

local NPCs : {Instance} = workspace.NPCs:GetChildren()

local function getGroundPlacementCFrame(position: Vector3, excludePart: BasePart?)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	local ignoreList : {Instance} = NPCs
	-- Filter out NPCs, players, and the ball itself
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(ignoreList, player.Character)
		end
	end
	if excludePart then
		table.insert(ignoreList, excludePart)
	end
	params.FilterDescendantsInstances = ignoreList

	-- Raycast downward to find ground position
	local groundRayParams = RaycastParams.new()
	groundRayParams.FilterType = Enum.RaycastFilterType.Exclude
	groundRayParams.FilterDescendantsInstances = {}
	groundRayParams.RespectCanCollide = true

	local groundRayOrigin = position + Vector3.new(0, 10, 0)
	local groundRayResult = workspace:Raycast(groundRayOrigin, Vector3.new(0, -100, 0), groundRayParams)

	local groundPosition = position
	local groundNormal = Vector3.new(0, 1, 0)

	if groundRayResult then
		groundPosition = groundRayResult.Position
		groundNormal = groundRayResult.Normal.Unit
	end

	-- Create surface-aligned CFrame
	local rightVector = Vector3.new(1, 0, 0)
	if math.abs(groundNormal:Dot(rightVector) :: number) > 0.99 then
		rightVector = Vector3.new(0, 0, 1)
	end

	local upVector = groundNormal
	local forwardVector = upVector:Cross(rightVector).Unit
	rightVector = forwardVector:Cross(upVector).Unit

	local surfaceCFrame = CFrame.fromMatrix(
		groundPosition + upVector * 0.05,
		rightVector,
		upVector,
		forwardVector
	)
	
	return surfaceCFrame
end


local function rotateToNegative90(cf: CFrame)
	-- Get current rotation angles
	local _, y, _ = cf:ToEulerAnglesXYZ()
	-- Convert to degrees and find nearest -90 degree rotation
	local yDeg = math.deg(y)
	local targetRot = math.floor(yDeg / 90) * 90 - 90
	-- Apply rotation
	return cf * CFrame.Angles(0, 0, math.rad(targetRot - yDeg))
end

local function spawnSound(soundId: string, position: Vector3)
	local soundPart = Instance.new("Part")
	soundPart.Anchored = true
	soundPart.CanCollide = false
	soundPart.CanTouch = false
	soundPart.Transparency = 1
	soundPart.Size = Vector3.new(1, 1, 1)
	soundPart.Position = position
	soundPart.Parent = workspace

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Parent = soundPart
	sound.RollOffMaxDistance = 100

	sound:Play()

	sound.Ended:Connect(function()
		if soundPart and soundPart.Parent then
			soundPart:Destroy()
		end
	end)
end

local function spawnDebrisParts(center: Vector3, radius: number, partCount: number, lifetime: number, baseCFrame: CFrame?)
	spawnSound("rbxassetid://3923230963", center)

	for i = 1, partCount do
		local angle = math.rad((360 / partCount) * i + math.random(-15, 15))
		local distance = math.random(radius * 0.5, radius)
		local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * distance

		local heightOffset = Vector3.new(0, -2 - math.random(), 0)
		local rotatedOffset = baseCFrame and baseCFrame:VectorToWorldSpace(offset) or offset
		local position = center + rotatedOffset + heightOffset

		local part = Instance.new("Part")
		part.Size = Vector3.new(1.5, 2, 1.5)
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Concrete
		part.BrickColor = BrickColor.DarkGray()
		part.Transparency = 0
		part.Parent = workspace

		if baseCFrame then
			part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, 0)
		else
			part.Position = position
			part.Rotation = Vector3.new(math.random(-30, 30), math.random(0, 360), math.random(-30, 30))
		end

		local targetPosition = position + Vector3.new(0, math.random(1, 3), 0)
		local tweenInfo = TweenInfo.new(0.4 + math.random() * 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 1, true)
		local tween = TweenService:Create(part, tweenInfo, { Position = targetPosition })
		tween:Play()

		task.delay(lifetime - 0.5, function()
			local fadeTween = TweenService:Create(part, TweenInfo.new(0.5), { Transparency = 1 })
			fadeTween:Play()
		end)

		Debris:AddItem(part, lifetime)
	end
end

local function fadeEmittersToTransparent(zone: Instance, duration: number)
	local fadeSteps = 10
	local waitTime = duration / fadeSteps

	for _, emitter in ipairs(zone:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			local startSequence = emitter.Transparency
			local newKeypoints = {}

			task.spawn(function()
				for step = 1, fadeSteps do
					local alpha = step / fadeSteps
					newKeypoints = {}

					for _, keypoint in ipairs(startSequence.Keypoints) do
						local fadedValue = keypoint.Value + (1 - keypoint.Value) * alpha
						table.insert(newKeypoints, NumberSequenceKeypoint.new(keypoint.Time, fadedValue, keypoint.Envelope))
					end

					emitter.Transparency = NumberSequence.new(newKeypoints)
					task.wait(waitTime)
				end
			end)
		end
	end
end

local function placeZone(position : Vector3?, cframe : CFrame?, element : string, elementConfig : { [string]: any }, character : Model)
	local zoneTemplate = ReplicatedStorage.Models
		:FindFirstChild(element.."Attack")
		:FindFirstChild(element.."Zone")
	if not zoneTemplate then return end

	local zone : BasePart = zoneTemplate:Clone() :: BasePart
	zone.Anchored = true
	zone.CanCollide = false
	zone.Parent = workspace
	game.Debris:AddItem(zone, elementConfig.Duration)

	if cframe then
		zone.CFrame = cframe
	elseif position then
		zone.CFrame = CFrame.new(position)
	end

	spawnSound(elementConfig.Sound, zone.Position)

	if elementConfig.Debris then
		spawnDebrisParts(zone.CFrame.Position, zone.Size.X * 20, 60, elementConfig.Duration, rotateToNegative90(zone.CFrame))
	end

	task.delay(elementConfig.Duration - 1, function()
		fadeEmittersToTransparent(zone, 1)
	end)

	while zone and zone.Parent do
		local now = tick()

		for _, instance in ipairs(zone:GetDescendants()) do
			if instance:IsA("ParticleEmitter") and instance:GetAttribute("EmitDelay") then
				task.wait(instance:GetAttribute("EmitDelay") :: number)
				instance:Emit(instance:GetAttribute("EmitCount"))
			end
		end
		
		hitboxes[now] = Hitbox.CreateHitbox()
		hitboxes[now].Size = zone.Size
		hitboxes[now].CFrame = zone.CFrame
		hitboxes[now].Visualizer = false
		hitboxes[now].Parent = workspace

		hitboxes[now].Touched:Connect(function(hit : BasePart, humanoid : Humanoid?)
			if humanoid and humanoid:IsA("Humanoid") and humanoid.Parent ~= character then
				humanoid:TakeDamage(elementConfig.Damage)
				spawnSound("rbxassetid://137171473068941", hit.Position)
			end
		end)
		hitboxes[now]:Start()

		task.wait(elementConfig.DOT or elementConfig.Duration)
		hitboxes[now]:Destroy()
	end
end
local function throwBall(character: Model, hrp: BasePart, targetPos: Vector3, element: string, elementConfig: { [string]: any })
	local origin = hrp.Position
	local gravityVec = Vector3.new(0, -workspace.Gravity, 0)
	local flightTime = elementConfig.FlightTime
	local displacement = targetPos - origin

	-- Compute initial velocity
	local v0 = (displacement - 0.5 * gravityVec * (flightTime^2)) / flightTime

	-- Spawn the ball
	local ball = ReplicatedStorage.Models
		:FindFirstChild(element.."Attack")
		:FindFirstChild(element.."Ball")
		:Clone() :: BasePart
	ball.CFrame = CFrame.new(origin)
	ball.Parent = workspace
	RunService.Heartbeat:Wait()
	ball.AssemblyLinearVelocity = v0

	local ballSize = ball.Size
	local radius = ballSize.X * 0.25
	local startTime = tick()

	local lastPosition = origin

	local conn : RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function(dt)
		local currentTime = tick() - startTime
		local currentPosition = ball.Position

		if currentTime >= flightTime then
			conn:Disconnect()
			local placementCF = getGroundPlacementCFrame(currentPosition, ball) or CFrame.new(currentPosition)
			local rotatedCF = rotateToNegative90(placementCF)
			placeZone(nil, rotatedCF, element, elementConfig, character)
			ball:Destroy()
			return
		end
		local Players = game:GetService("Players")
		local workspace = game:GetService("Workspace")

		local function getSurfaceAlignedCFrame(position: Vector3, travelDir: Vector3, ball: BasePart)
			-- Build a RaycastParams to ignore NPCs, players, and the ball itself
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.IgnoreWater = true

			local ignoreList : {Instance} = {}

			-- Ignore NPCs
			local npcsFolder = workspace:FindFirstChild("NPCs")

			for _, npc in ipairs(npcsFolder:GetChildren()) do
				table.insert(ignoreList, npc)
			end

			-- Ignore all player characters
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr.Character then
					table.insert(ignoreList, plr.Character)
				end
			end
			
			table.insert(ignoreList, ball)

			params.FilterDescendantsInstances = ignoreList

			-- Raycast down from a bit above the impact point
			local rayOrigin    = position + Vector3.new(0, 5, 0)
			local rayDirection = Vector3.new(0, -50, 0)
			local downHit      = workspace:Raycast(rayOrigin, rayDirection, params)

			-- Grab the downward normal (or fallback)
			local surfPos, surfNormal
			if downHit then
				surfPos    = downHit.Position
				surfNormal = downHit.Normal.Unit
			else
				surfPos    = position
				surfNormal = Vector3.yAxis
			end

			-- Two cases: walls vs. floors/slopes
			if math.abs(surfNormal.Y) < 0.2 then
				-- wall case: keep zone upright but face into the wall
				local up      = Vector3.yAxis
				local right   = up:Cross(surfNormal).Unit
				local forward = surfNormal:Cross(up).Unit
				return CFrame.fromMatrix(surfPos + up * 0.02, right, up, forward)
			else
				-- floor/slope case: orient to ground-normal + travel direction
				local up = surfNormal

				-- Project travelDir onto the ground plane for a stable forward
				local forward = (travelDir - up * travelDir:Dot(up))
				if forward.Magnitude < 0.01 then
					forward = Vector3.zAxis
					if math.abs(up:Dot(forward)) > 0.99 then
						forward = Vector3.xAxis
					end
				end
				forward = forward.Unit

				local right = up:Cross(forward).Unit
				forward    = right:Cross(up).Unit

				return CFrame.fromMatrix(surfPos + up * 0.02, right, up, forward)
			end
		end

		-- Inside throwBall function:
		local direction = currentPosition - lastPosition
		local distance = direction.Magnitude

		if distance > 0 then
			local ignoreList = NPCs
			
			local castParams = RaycastParams.new()
			castParams.FilterType = Enum.RaycastFilterType.Exclude
			table.insert(ignoreList, ball)

			-- Add other players to ignore list
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr.Character and plr ~= Players:GetPlayerFromCharacter(character) then
					table.insert(ignoreList, plr.Character)
				end
			end
			castParams.FilterDescendantsInstances = ignoreList
			-- Perform spherecast for collision detection
			local result = workspace:Spherecast(lastPosition, radius, direction, castParams)

			if result then
    conn:Disconnect()
    
    -- Get surface information from collision
    local surfacePosition = result.Position
    local surfaceNormal = result.Normal
    
    -- Get travel direction (current velocity)
    local travelDir = ball.AssemblyLinearVelocity.Unit
    
    -- Create properly aligned CFrame
    local surfaceCFrame = getSurfaceAlignedCFrame(surfacePosition, surfaceNormal, ball)
    
    -- Apply rotation alignment
    local placementCF = rotateToNegative90(surfaceCFrame)
    placeZone(nil, placementCF, element, elementConfig, character)
    ball:Destroy()
    return
end
		end

		lastPosition = currentPosition
	end)
end


castRemote.OnServerEvent:Connect(function(player: Player, targetPos: Vector3)
	local character: Model? = player.Character or player.CharacterAdded:Wait()
	if not character then return end

	local config : Configuration? = character:FindFirstChild("Configuration") :: Configuration or character:WaitForChild("Configuration", 3) :: Configuration
	if not config then return end

	local currentElement : StringValue = config:FindFirstChild("CurrentElement") :: StringValue or config:WaitForChild("CurrentElement", 3) :: StringValue
	local elementName = currentElement.Value

	local currentElementSettings = elementSettings[elementName]

	if not lastCast[player] then
		lastCast[player] = {}
	end

	local playerCooldowns = lastCast[player]
	local lastUsed = playerCooldowns[elementName] or 0
	local now = tick()
	local cooldown = currentElementSettings.Cooldown or 0

	if now - lastUsed < cooldown then
		return
	end
	cooldownUpdateEvent:FireClient(player, elementName)

	playerCooldowns[elementName] = now

	local hrp: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not hrp then return end

	local origin = hrp.Position
	local displacement = targetPos - origin

	if displacement.Magnitude > currentElementSettings.Range then return end 

	if currentElementSettings.Thrown then
		throwBall(character, hrp, targetPos, elementName, currentElementSettings)
	else
		local ignoreList : {Instance} = NPCs
		local rayOrigin = targetPos + Vector3.new(0, 10, 0)
		local rayDirection = Vector3.new(0, -50, 0)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		-- Exclude character and player parts to avoid hitting self
		
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				table.insert(ignoreList, player.Character)
			end
		end
		
		params.FilterDescendantsInstances = ignoreList
		local rayResult = workspace:Raycast(rayOrigin, rayDirection, params)

		local finalCFrame
		if rayResult then
			local hitPos = rayResult.Position
			local hitNormal = rayResult.Normal.Unit

			local upVector = hitNormal
			if upVector.Y < 0.1 then
				upVector = Vector3.yAxis
			end

			-- Choose an arbitrary forward vector not colinear with upVector
			local forwardVector = Vector3.new(0, 0, 1)
			if math.abs(upVector:Dot(forwardVector) :: number) > 0.99 then
				forwardVector = Vector3.new(1, 0, 0)
			end

			local rightVector = forwardVector:Cross(upVector).Unit
			forwardVector = upVector:Cross(rightVector).Unit

			-- Position the zone slightly above the surface
			finalCFrame = CFrame.fromMatrix(hitPos + upVector * 0.05, rightVector, upVector, -forwardVector)
		else
			finalCFrame = CFrame.new(targetPos)
		end

		local rotatedCF = rotateToNegative90(finalCFrame)
		placeZone(nil, rotatedCF, elementName, currentElementSettings, character)
	end
end)