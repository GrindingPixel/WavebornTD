-- TeleportLobbyHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

--// Remote
local teleportRemote = ReplicatedStorage.Remotes.Teleport:WaitForChild("TeleportToAreaRequest")

--// Targets
local targetFolder = workspace:WaitForChild("FastTeleport")

--// Event
teleportRemote.OnServerEvent:Connect(function(player, areaName)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local target = targetFolder:FindFirstChild(areaName)
	if not target then
		warn("[TeleportLobbyHandler] Ungültiges Zielgebiet:", areaName)
		return
	end

	character:PivotTo(target.CFrame + Vector3.new(0, 3, 0))
end)
