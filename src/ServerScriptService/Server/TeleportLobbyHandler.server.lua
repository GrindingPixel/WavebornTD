-- TeleportLobbyHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")

--// Remotes
local teleportRemote = ReplicatedStorage.Remotes.Teleport:WaitForChild("TeleportToAreaRequest")

--// Targets
local targetFolder = Workspace:WaitForChild("FastTeleport")

--// Event Handler
teleportRemote.OnServerEvent:Connect(function(player, areaName)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local target = targetFolder:FindFirstChild(areaName)
	if not target then
		warn("[TeleportLobbyHandler] ⚠️ Ungültiges Zielgebiet:", areaName)
		return
	end

	print("[TeleportLobbyHandler] 📦 Teleportiere", player.Name, "nach", areaName)
	character:PivotTo(target.CFrame + Vector3.new(0, 3, 0))
end)
