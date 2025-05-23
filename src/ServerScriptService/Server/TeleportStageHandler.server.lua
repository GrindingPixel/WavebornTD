-- TeleportStageHandler.server.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Teleport"):WaitForChild("TeleportStageRequest")

-- ✅ Placeholder-Verarbeitung – wird später ersetzt durch echte Map-Teleports
remote.OnServerEvent:Connect(function(player, worldName, stageId)
	print("📦 TeleportStageRequest empfangen von", player.Name)
	print("🌍 Welt:", worldName, "🗺️ Stage:", stageId)

	-- ❗ später:
	-- 1. Validierung
	-- 2. Teleport zur TD-Map oder Ort
end)
