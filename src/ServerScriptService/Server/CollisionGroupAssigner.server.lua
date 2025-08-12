--!strict
-- CollisionGroupAssigner.server.lua

local Players = game:GetService("Players")

local function assignCharacterGroup(character: Model)
	task.wait(0.1)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Player"
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(assignCharacterGroup)
	if player.Character then
		assignCharacterGroup(player.Character)
	end
end)
