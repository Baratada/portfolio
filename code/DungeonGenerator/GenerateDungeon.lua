local ServerScriptService = game:GetService("ServerScriptService")


local DungeonGenerator = require(ServerScriptService.DungeonGeneration:WaitForChild("DungeonGenerator"))

local dungeon = DungeonGenerator.GenerateDungeon("Hokma", 50, CFrame.new(0,13.5,0)) -- Generate the dungeon with theme "Hokma", 50 max rooms, and starting position at 0, 13.5, 0

print(dungeon)

