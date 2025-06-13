-- TeleportStageHandler.server.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Teleport"):WaitForChild("TeleportStageRequest")

-- Beispiel-Ziel: TestMap für jetzt
local TEST_PLACE_ID = 91395451659768 -- 🟡 HIER deine echte PlaceId eintragen

remote.OnServerEvent:Connect(function(player, worldName, stageId)
	print("📦 TeleportStageRequest empfangen von", player.Name)
	print("🌍 Welt:", worldName, "🗺️ Stage:", stageId)

	-- Optional: Überprüfen ob worldName/stageId gültig sind

	-- Teleport ausführen
	local success, result = pcall(function()
		TeleportService:Teleport(TEST_PLACE_ID, player)
	end)

	if success then
		print("✅ Teleport erfolgreich gestartet für", player.Name)
	else
		warn("❌ Teleport fehlgeschlagen:", result)
	end
end)
