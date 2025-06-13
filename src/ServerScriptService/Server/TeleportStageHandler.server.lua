-- TeleportStageHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")

--// Modules
local MapData           = require(ReplicatedStorage.Modules.MapDataModule)
local MapDataUtils      = require(ReplicatedStorage.Modules.MapDataUtils)

--// Remote
local remote = ReplicatedStorage.Remotes.Teleport:WaitForChild("TeleportStageRequest")

remote.OnServerEvent:Connect(function(player, worldName, stageId)
	print("📦 TeleportStageRequest empfangen:", player.Name, worldName, stageId)

	local stage = MapDataUtils.GetStageById(worldName, stageId)
	if not stage then
		warn("❌ Ungültige Stage:", worldName, stageId)
		return
	end

	local worldData = MapData[worldName]
	if not worldData or not worldData.PlaceId then
		warn("❌ Kein gültiger PlaceId für Welt:", worldName)
		return
	end

	local success, result = pcall(function()
		return TeleportService:Teleport(worldData.PlaceId, player)
	end)

	if success then
		print("✅ Teleport gestartet für", player.Name)
	else
		warn("❌ Teleport fehlgeschlagen:", result)
	end
end)
