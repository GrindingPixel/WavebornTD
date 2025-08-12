-- ProfileSyncService.lua (Server)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DebugLogger = require(ReplicatedStorage.Modules:WaitForChild("DebugLogger"))

--// Remotes
local ProfileChanged = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")

--// Module
local ProfileSyncService = {}
local log = DebugLogger.new("ProfileSyncService")

function ProfileSyncService:Send(player, key, data)
        log("📡 Sende LiveSync:", key, "→", player.Name)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
	if typeof(key) ~= "string" then return end
	if data == nil then return end

	ProfileChanged:FireClient(player, key, data)
end


return ProfileSyncService
