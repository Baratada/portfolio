-- Store cooldown timestamps per element
local lastCastTimes : {[string]: number} = {}
local players = game:GetService("Players")
local uis = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local player : Player? = players.LocalPlayer
if not player then return end

local character : Model? = player.Character :: Model or player.CharacterAdded:Wait() :: Model
if not character then return end

local humanoid : Humanoid? = character:WaitForChild("Humanoid", 3) :: Humanoid
if not humanoid then return end

local hrp : BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart
if not hrp then return end

local config : Configuration? = character:FindFirstChild("Configuration") :: Configuration or character:WaitForChild("Configuration", 3) :: Configuration
if not config then return end

local elementSettings : {[string]: any} = require(replicatedStorage.Modules.ElementSettings) :: { [string]: any }

local currentElement : StringValue = config:FindFirstChild("CurrentElement") :: StringValue or config:WaitForChild("CurrentElement", 3) :: StringValue
local camera : Camera? = workspace.CurrentCamera
local mouse : Mouse = player:GetMouse()
local castRemote : RemoteEvent = game:GetService("ReplicatedStorage").Remotes.CastSpellEvent

uis.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)  
	if gameProcessedEvent or not camera then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local elementName = currentElement.Value
		local cooldown = elementSettings[elementName].Cooldown or 0
		local now = tick()

		-- Check cooldown
		if lastCastTimes[elementName] and now - lastCastTimes[elementName] < cooldown then
			-- Play fail sound
			local sound = Instance.new("Sound")
			sound.Parent = game:GetService("SoundService")
			sound.SoundId = "rbxassetid://3779045779"
			sound:Play()
			sound.Stopped:Wait()
			sound:Destroy()
			return
		end

		local rayLength = elementSettings[elementName].Range

		local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
		local extendedRay = Ray.new(unitRay.Origin, unitRay.Direction * rayLength)	

		local hitPart, position = workspace:FindPartOnRay(extendedRay, character)

		if not hitPart then
			-- Play fail sound
			local sound = Instance.new("Sound")
			sound.Parent = game:GetService("SoundService")
			sound.SoundId = "rbxassetid://3779045779"
			sound:Play()
			sound.Stopped:Wait()
			sound:Destroy()
			return
		end

		-- Passed cooldown check & valid target
		lastCastTimes[elementName] = now

		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://119658929303259"
		local animator = humanoid:WaitForChild("Animator") :: Animator
		local track = animator:LoadAnimation(animation)
		track:Play()

		track.Stopped:Connect(function()
			animation:Destroy()
		end)

		castRemote:FireServer(position)
	end
end)