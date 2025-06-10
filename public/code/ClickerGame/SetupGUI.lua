local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Replica = require(ReplicatedStorage.ReplicaClient)

local Fusion = require(ReplicatedStorage.Frameworks.Fusion)
local scoped, peek, Children = Fusion.scoped, Fusion.peek, Fusion.Children
local Theme = require(ReplicatedStorage.GUIData.GUITheme)

local GUIElements = ReplicatedStorage.GUIElements

local RebirthRemote = ReplicatedStorage.Remotes.Rebirth

local scope = scoped(Fusion, {
	ShopPreview = require(GUIElements.ShopPreview),
	MessageBox = require(GUIElements.MessageBox),
	TextButton = require(GUIElements.SubComponents.TextButton),
	ImageButton = require(GUIElements.SubComponents.ImageButton),
	ImageLabel = require(GUIElements.SubComponents.ImageLabel),
	TextLabel = require(GUIElements.SubComponents.TextLabel),
	Tooltip = require(GUIElements.Tooltip)
})

local player = game:GetService("Players").LocalPlayer
if not player then return end

Replica.RequestData() 

local Items = require(ReplicatedStorage.GUIData.ShopItems)

local SNAP_THRESHOLD = 100

local TOOLTIP_W = 10
local OFFSET_Y  = 10 

local CPS = scope:Value(0)

local WINDOW_SIZE = 5                     
local cpsHistory = {}                     
for i = 1, WINDOW_SIZE do
	cpsHistory[i] = 0
end
local currentSecondClicks = 0  

local function registerClick()
	currentSecondClicks += 1
end

task.spawn(function()
	while true do
		task.wait(1)

		table.remove(cpsHistory, 1)
		table.insert(cpsHistory, currentSecondClicks)

		currentSecondClicks = 0

		local sum = 0
		for _, num in ipairs(cpsHistory) do
			sum += num
		end
		local avgCPS = sum / WINDOW_SIZE

		CPS:set(avgCPS)
	end
end)


local themeOverride = scope:Value("light")

local rebirthPrice = scope:Value(50000)
local SizeValue = scope:Value(UDim2.fromScale(0.4, 0.2))

local RotationValue = scope:Value(0)
local showMessageBox = scope:Value(false)
local TooltipText = scope:Value("")
local TooltipPos = scope:Value(UDim2.fromOffset(0,0))
local TooltipVisible = scope:Value(false)
local inventoryState = scope:Value({})
local brainrotAmountValue  = scope:Value(0)
local brainrotPerClickValue = scope:Value(1)
local brainrotMultiplierValue = scope:Value(1)
local brainrotTotalValue = scope:Value(0)
local rebirthsValue = scope:Value(1)
local brainrotPerClickDisplay = scope:Value(0)

local function updatePerClick()
	local base   = peek(brainrotPerClickValue)
	local multi  = peek(brainrotMultiplierValue)
	local reb    = peek(rebirthsValue)

	local real   = base * multi * reb
	brainrotPerClickDisplay:set(real)
end

local springSize = scope:Spring(SizeValue)
local springRotation = scope:Spring(RotationValue)
local brainrotSpring = scope:Spring(brainrotAmountValue, 3, 1.2)
local brainrotPerClickSpring = scope:Spring(brainrotPerClickDisplay)

local getAvailableItems = function() return nil end

Replica.OnNew("PlayerData", function(replica)
	local player = replica.Tags.Player
	if not player or not Players:FindFirstChild(player.Name) or player ~= Players.LocalPlayer then return end

	getAvailableItems = function(totalBrainrot: number, ownedItems: { string }): { [string]: Items.Item }
		local available = {}

		for Key, itemData in pairs(Items) do
			if totalBrainrot >= (itemData.Price * ((replica.Data.Inventory[itemData.Name] or 0) + 1) / 4) then
				available[itemData.Name] = itemData
			end
		end

		return available
	end

	brainrotAmountValue:set(replica.Data.Brainrot or 0)
	brainrotPerClickValue:set(replica.Data.BrainrotPerClick * replica.Data.BrainrotMultiplier or 1)
	brainrotMultiplierValue:set(replica.Data.BrainrotMultiplier or 1)
	brainrotTotalValue:set(replica.Data.TotalBrainrotEarned)
	rebirthsValue:set(replica.Data.Rebirths or 1)
	inventoryState:set(replica.Data.Inventory or {})
	updatePerClick()

	
	replica:OnSet({"Brainrot"}, function(new)
		local disp = peek(brainrotAmountValue)
		
		brainrotAmountValue:set(new)
		
		if math.abs(new - disp) > SNAP_THRESHOLD then
			brainrotSpring:setPosition(new - SNAP_THRESHOLD)
		end
	end)
	
	replica:OnSet({"TotalBrainrotEarned"}, function(new)
		brainrotTotalValue:set(new)
	end)
	
	replica:OnSet({"BrainrotPerClick"},function(new) 
		brainrotPerClickValue:set(new)
		updatePerClick()
	end)
	
	replica:OnSet({"BrainrotMultiplier"},function(new)
		brainrotMultiplierValue:set(new)
		updatePerClick()
	end)
	
	replica:OnSet({"Rebirths"},function(new)
		rebirthsValue:set(new)
		updatePerClick()
	end)
	
	replica:OnSet({"Inventory"}, function(new)
		inventoryState:set(new)
	end)
	
	replica:OnSet({"RebirthPrice"}, function(new)
		rebirthPrice:set(new)
	end)
end)
	
Theme.currentTheme:is(themeOverride):during(function()
	local rawBgColor = scope:Computed(function(use)
		local themeName = use(themeOverride)
		scope:Tween(Theme.colors.background[themeName])
		return Theme.colors.background[themeName]
	end)

	local rawTextColor = scope:Computed(function(use)
		local themeName = use(themeOverride)
		return Theme.colors.text[themeName]
	end)
	
	local imageId = scope:Computed(function(use)
		local themeName = use(themeOverride)
		return Theme.symbols.mode[themeName]
	end)
	
	local bgColor = scope:Tween(rawBgColor)
	local textColor = scope:Tween(rawTextColor)

	local previews = scope:Computed(function(use)
		local components = {}
		local available = getAvailableItems(use(brainrotTotalValue), use(inventoryState))
		
		if not available then return end
		
		for _, item in pairs(available) do
			table.insert(components,
				scope:ShopPreview {
					LabelText = item.Name,
					ImageId = item.Image,
					Price = scope:Computed(function()
						local inv = peek(inventoryState)
						local c = inv[item.Name] or 0
						return item.Price * (c + 1)
					end),
					BG = bgColor,
					FG = textColor,
					LayoutOrder = item.Id,
					Brainrot = use(brainrotAmountValue),

					MouseEnter = function(x,y)
						TooltipText:set(("+" .. (item.Addition or 0)) .. "/" .. (item.Multiplier and item.Multiplier + 1 or 1) .. "x")
						TooltipPos:set( UDim2.fromOffset(x - TOOLTIP_W - 15, y - OFFSET_Y) )
						TooltipVisible:set(true)
					end,
					MouseMoved = function(x,y)
						TooltipPos:set( UDim2.fromOffset(x - TOOLTIP_W - 15, y - OFFSET_Y) )
					end,
					MouseLeave = function()
						TooltipVisible:set(false)
					end,
				}
			)
		end
		return components
	end)
	
	local gui = scope:New "ScreenGui" {
		Parent = player.PlayerGui,
		IgnoreGuiInset = true,
		Name = "MainGUI",
		[Children] = {
			scope:Computed(function(use)
				if not use(TooltipVisible) then return nil end
				return scope:Tooltip {
					Text = TooltipText,
					Position = TooltipPos,
					BG = bgColor,
					FG = textColor,
				}
			end),
			scope:Computed(function(use)
				if not use(showMessageBox) then return nil end
				return scope:MessageBox {
					Text = "Are you sure you want to rebirth? Rebirthing gives a permanent 2x multiplier but resets all your brainrot.",
					Price = use(rebirthPrice),
					BG = bgColor,
					FG = textColor,
					Activated = function()
						showMessageBox:set(false)
						RebirthRemote:FireServer()
					end,
					Cancelled = function()
						showMessageBox:set(false)
					end
				}
			end),
			scope:New "Frame"{
				Name = "Stats",
				Size = UDim2.fromScale(.25, .25),
				Position = UDim2.fromScale(.2, .5),
				BackgroundColor3 = bgColor,
				[Children] = {
					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Horizontal,
						Wraps = true,
						SortOrder = Enum.SortOrder.LayoutOrder
					},
					scope:TextLabel {
						Text = scope:Computed(function(use)
							return string.format("Rebirths: %d", use(rebirthsValue))
						end),

						Size = UDim2.fromScale(1, .2),
						BG = Color3.new(1, 0.454902, 0.882353),
						FG = Color3.new(1,1,1),
					},
					scope:TextLabel {
						Text = scope:Computed(function(use)
							return string.format("Raw Brainrot Per Click: %.2f", use(brainrotPerClickValue))
						end),

						Size = UDim2.fromScale(1, .2),
						BG = Color3.new(1, 0.454902, 0.882353),
						FG = Color3.new(1,1,1),
					},
					scope:TextLabel {
						Text = scope:Computed(function(use)
							return string.format("Multiplier: %.2f", use(brainrotMultiplierValue))
						end),

						Size = UDim2.fromScale(1, .2),
						BG = Color3.new(1, 0.454902, 0.882353),
						FG = Color3.new(1,1,1),
					}
				}
			},
			scope:New "Frame"{
				Name = "Background",
				Size = UDim2.fromScale(1,1),
				BackgroundColor3 = bgColor,
				[Children] = {
					scope:ImageButton {
						ImageId = imageId,
						Size = UDim2.fromScale(.025,.05),
						Position = UDim2.fromScale(.09, .035),
						BG = bgColor,
						FG = textColor,
						ZIndex = 5,

						Activated = function()
							local current = peek(themeOverride)
							themeOverride:set((current == "light") and "dark" or "light")
						end
					},
					scope:ImageButton {
						ImageId = "rbxassetid://6514213123",
						Size = UDim2.fromScale(.025,.05),
						Position = UDim2.fromScale(.12, .035),
						BG = bgColor,
						FG = textColor,
						ZIndex = 5,

						Activated = function()
							showMessageBox:set(not peek(showMessageBox))
						end
					},
					scope:New "UIGradient" {
						Rotation = 90,
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
							ColorSequenceKeypoint.new(1, Color3.new(0.392157, 0.356863, 0.345098)),
						}),
					}
				}
			},
			scope:New "Frame" {
				Name = "BrainrotCount",
				Size = UDim2.fromScale(0.3, 0.1),
				Position = UDim2.fromScale(0.9, 0.2),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,				
				[Children] = {
					scope:TextLabel{
						Text = scope:Computed(function(use)
							return string.format("%.2f Brainrot", use(brainrotSpring))
						end),
						
						Size = UDim2.fromScale(1, 1),
						Position = UDim2.fromScale(0,0),
						BG = Color3.new(1, 0.454902, 0.882353),
						FG = Color3.new(1,1,1),
					},
					scope:ImageLabel{
						ImageId = "rbxassetid://133190294289442",
						BG = Color3.new(1, 0.454902, 0.882353),
						FG = Color3.new(1,1,1),
						Size = UDim2.fromScale(0.2, 1.2),
						Position = UDim2.fromScale(0.50, -0.5),
						Rotation = 35
					},
					scope:TextButton{
						Text = "BUY 1 MILLION BRAINROT!",
						Size = UDim2.fromScale(.5, .25),
						Position = UDim2.fromScale(0,-.5),
						BG = Color3.new(1, 0.454902, 0.882353),
						FG = Color3.new(1,1,1),
						Activated = function()
							MarketplaceService:PromptProductPurchase(player, 3302105575)
						end,
					},
					scope:TextLabel {
						Text = scope:Computed(function(use)
							return string.format("Clicks per second: %.2f", use(CPS)/5)
						end),
						Size = UDim2.fromScale(0.5, 0.25),
						Position = UDim2.fromScale(0, -1),
						BG = Color3.fromRGB(255, 200, 0),
						FG = Color3.new(0, 0, 0),
						ZIndex = 3
					},
				}
			},
			scope:TextButton {
				Size = springSize,
				Position = UDim2.fromScale(0.5, 0.8),
				Rotation = springRotation,
				Text = scope:Computed(function(use)
					return string.format("+ %.2f Brainrot!", use(brainrotPerClickSpring))
				end),
				BG = Color3.new(1, 0.454902, 0.882353),
				FG = Color3.new(1,1,1),

				Activated = function()
					SizeValue:set(UDim2.fromScale(0.35, 0.175))
					registerClick()

					task.delay(0.15, function()
						SizeValue:set(UDim2.fromScale(0.4, 0.2))
					end)

					local targetAngle = math.random(-15, 15)
					RotationValue:set(targetAngle)
					task.delay(0.2, function()
						RotationValue:set(0)
					end)
					require(ReplicatedStorage.Utility.SFXPlayer).PlayAttached("Click", game:GetService("SoundService"), {SoundId = "rbxassetid://6895079853", Volume = 2, Pitch = 1.5})
					spawnMovingImageLabel()
					local RequestBrainrot = ReplicatedStorage.Remotes:WaitForChild("RequestBrainrot")
					RequestBrainrot:FireServer()
				end,
			},
			
			scope:New "ScrollingFrame" {
				Name = "Shop",
				Size = UDim2.fromScale(0.45, 0.35),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = bgColor,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				[Children] = scope:Computed(function(use)
					local children = {
						scope:New "UIGradient" {
							Rotation = 90,
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
								ColorSequenceKeypoint.new(1, Color3.new(0.392157, 0.356863, 0.345098)),
							}),
						},
						scope:New "UIAspectRatioConstraint" {
							AspectRatio = 16 / 9,
							DominantAxis = Enum.DominantAxis.Height,
						},
						scope:New "UICorner" {},
						scope:New "UIStroke" {
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = use(textColor),
							Transparency = 0.5,
						},
						scope:New "UIListLayout" {
							FillDirection = Enum.FillDirection.Horizontal,
							Wraps = true,
							SortOrder = Enum.SortOrder.LayoutOrder
						},
					}

					local previewComponents = use(previews) or {}
					for _, preview in ipairs(previewComponents) do
						table.insert(children, preview)
					end

					return children
				end),
			}
		}
	}
	function spawnMovingImageLabel()
		local startX = math.random()
		local startY = math.random()

		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Image = "rbxassetid://133190294289442"
		imageLabel.Size = UDim2.fromScale(0.025, 0.05)
		imageLabel.Position = UDim2.fromScale(startX, startY)
		imageLabel.BackgroundTransparency = 1
		imageLabel.ZIndex = 10

		local startRotation = math.random(0, 360)
		imageLabel.Rotation = startRotation

		imageLabel.Parent = gui

		local tweenService = game:GetService("TweenService")
		local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local targetRotation = math.random(0, 360)

		local tween = tweenService:Create(imageLabel, tweenInfo, {
			Position = UDim2.fromScale(0.85, 0.15),
			Rotation = targetRotation,
			ImageTransparency = 1
		})

		tween:Play()

		tween.Completed:Connect(function()
			imageLabel:Destroy()
		end)
	end
end)

