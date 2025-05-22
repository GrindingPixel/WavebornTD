-- ServerScriptService/TeleportPortalHandler.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local portalsFolder = workspace:WaitForChild("Portals")
local storyPortal = portalsFolder:WaitForChild("StoryPortal")

local openGuiRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Teleport"):WaitForChild("OpenMapSelection")

storyPortal.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		openGuiRemote:FireClient(player)
	end
end)
