game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAppearanceLoaded:Wait()

	local taintedColors = {
		"Dark orange",
		"CGA brown",
		"Brown",
		"Tr. Brown",
		"Black",
		"Black metallic",
		"Fawn brown",
		"Medium brown",
		"Light orange brown",
		"Pastel brown",
		"Reddish brown"
	}

	local char = player.Character

	for i, v in ipairs(char:GetChildren()) do
		if v:IsA("BasePart") == true then 
			for x, y in ipairs(taintedColors) do
				if v.BrickColor == BrickColor.new(y) then
 					player:Kick("You're black.")	
					warn("BLACK BODYPART DETECTED: ".. tostring(v).. " | SHADE OF BLACK: ".. tostring(v.BrickColor))
					return
				end
			end
		end
	end
	warn("Maybe you survive this time.")
end)
