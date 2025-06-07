export type ElementData = {
	Range: number,
	Damage: number,
	Cooldown: number,
	DOT: number?,
	Duration: number,
	Thrown: boolean?,
	FlightTime: number?,
	Sound: string,
	Color: Color3,
	Debris: boolean?
}

local elementSettings: {[string]: ElementData} = {
	Lightning = {
		Range = 140,
		Damage = 20,
		Cooldown = 15,
		Duration = 5,
		Sound = "rbxassetid://4961240438",
		Color = Color3.fromRGB(0, 200, 255),
		Debris = true
	},
	Poison = {
		Range = 90,
		Damage = 5,
		Cooldown = 8,
		DOT = 1,
		Duration = 10,
		Thrown = true,
		FlightTime = 1,
		Sound = "rbxassetid://5656490592",
		Color = Color3.fromRGB(111, 255, 0)
	},
	Water = {
		Range = 180,
		Damage = 10,
		Cooldown = 3,
		DOT = nil,
		Duration = 1,
		Thrown = true,
		FlightTime = 0.43,
		Sound = "rbxassetid://142431247",
		Color = Color3.fromRGB(0, 255, 225),
		Debris = true
	},
	Life = {
		Range = 40,
		Damage = -5,
		Cooldown = 10,
		DOT = 1,
		Duration = 5,
		Thrown = true,
		FlightTime = 2,
		Sound = "rbxassetid://122551013489891",
		Color = Color3.fromRGB(234, 255, 0)
	},
}
return elementSettings