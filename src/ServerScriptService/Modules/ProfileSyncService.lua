-- ProfileSyncService.lua (Server)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Remotes
local ProfileChanged = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")

--// Module
local ProfileSyncService = {}

function ProfileSyncService:Send(player, key, data)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
	if typeof(key) ~= "string" then return end
	if data == nil then return end

	ProfileChanged:FireClient(player, {
		key = key,
		data = data,
	})
end

return ProfileSyncService
