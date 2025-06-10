local Fusion = require(game:GetService("ReplicatedStorage").Frameworks.Fusion)
type UsedAs<T> = Fusion.UsedAs<T>
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local function TextButton(
	scope: Fusion.Scope,
	props: {
		Text: UsedAs<string>,
		Position: UsedAs<UDim2>,
		Size: UsedAs<UDim2>,
		BG: UsedAs<Color3>,
		FG: UsedAs<Color3>,
		Rotation: UsedAs<number?>,
		Activated: UsedAs<() -> ()>
	}
)
	
	return scope:New "TextButton" {
		BackgroundColor3 = props.BG,
		TextColor3 = props.FG,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = props.Size,
		Position = props.Position,
		TextScaled = true,
		AutoButtonColor = true,
		Font = Enum.Font.BuilderSansExtraBold,
		Text = props.Text,
		Rotation = props.Rotation or 0,
		
		[OnEvent "Activated"] = function()
			if props.Activated then
				props.Activated()
			end
		end,
		
		[Children] = {
			scope:New "UIGradient" {
				Offset = Vector2.new(0,.1),
				Rotation = 90,
				Color = ColorSequence.new({ColorSequenceKeypoint.new(0, peek(props.BG)), ColorSequenceKeypoint.new(1, peek(props.FG))})
			},
			scope:New "UICorner" {},
			scope:New "UIStroke" {
				Thickness = 2,
				Color = props.BG
			},
			scope:New "UIStroke"{
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Transparency = 0.5,
				Color = props.FG
			}
		}
	}
end

return TextButton
