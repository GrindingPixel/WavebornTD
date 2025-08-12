--!strict
-- TowerDefense/TeleportStageHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")

local DebugLogger = require(ReplicatedStorage.Modules:WaitForChild("DebugLogger"))
local log = DebugLogger.new("TeleportStageHandler")

--// Modules
local MapData = require(ReplicatedStorage.Modules.MapDataModule)
local MapDataUtils = require(ReplicatedStorage.Modules.MapDataUtils)
local ProfileStoreWrapper = require(ServerScriptService.Modules.ProfileStoreWrapper)

--// Remote
local remote = ReplicatedStorage.Remotes.Teleport:WaitForChild("TeleportStageRequest")

--// Event Handler
remote.OnServerEvent:Connect(function(player: Player, worldName: string, stageId: number)
        log("📦 TeleportStageRequest erhalten von", player.Name, "→", worldName, stageId)

	-- Stage validieren
	local stage = MapDataUtils.GetStageById(worldName, stageId)
	if not stage then
		warn("[TeleportStageHandler] ❌ Ungültige Stage:", worldName, stageId)
		return
	end

	-- Welt validieren
	local worldData = MapData[worldName]
	if not worldData or not worldData.PlaceId then
		warn("[TeleportStageHandler] ❌ Kein gültiger PlaceId für Welt:", worldName)
		return
	end

	-- Stage im Profil speichern
	local success = ProfileStoreWrapper:SetSelectedStage(player, worldName, stageId)
	if not success then
		warn("[TeleportStageHandler] ❌ Konnte SelectedStage nicht speichern")
		return
	end

	log("💾 SelectedStage gespeichert für", player.Name, "→", worldName, "Stage", stageId)

	-- Teleport ausführen
	local ok, result = pcall(function()
		return TeleportService:Teleport(worldData.PlaceId, player)
	end)

	if ok then
		log("✅ Teleport ausgeführt für", player.Name)
	else
		warn("[TeleportStageHandler] ❌ Teleport fehlgeschlagen:", result)
	end
end)
