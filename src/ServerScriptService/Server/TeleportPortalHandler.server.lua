local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local portals = workspace:WaitForChild("Portals")
local storyPortal = portals:WaitForChild("StoryPortal")
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Teleport"):WaitForChild("OpenMapSelection")

storyPortal.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		remote:FireClient(player)
	end
end)
