--!strict
-- Modules/StageTeleportService.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")

--// Module
local MapData = require(ReplicatedStorage.Modules.MapDataModule)
local MapDataUtils = require(ReplicatedStorage.Modules.MapDataUtils)
local ProfileService = require(ServerScriptService.Modules.ProfileService)

--// Debug Helper
local DEBUG = true
local function log(...: any)
	if DEBUG then
		print("[StageTeleportService]", ...)
	end
end

--// Public API
local StageTeleportService = {}

function StageTeleportService.TeleportToStage(player: Player, worldName: string, stageId: number)
	log("📦 TeleportToStage:", player.Name, "→", worldName, "Stage", stageId)

	-- Stage validieren (außer Lobby)
	if worldName ~= "Lobby" then
		local stage = MapDataUtils.GetStageById(worldName, stageId)
		if not stage then
			warn("[StageTeleportService] ❌ Ungültige Stage:", worldName, stageId)
			return false
		end
	end

	-- Welt validieren
	local worldData = MapData[worldName]
	if not worldData or not worldData.PlaceId then
		warn("[StageTeleportService] ❌ Kein gültiger PlaceId für Welt:", worldName)
		return false
	end

	-- Stage im Profil speichern
	if worldName ~= "Lobby" then
                local success = ProfileService:SetSelectedStage(player, worldName, stageId)
		if not success then
			warn("[StageTeleportService] ❌ Konnte SelectedStage nicht speichern")
			return false
		end
	end

	log("💾 SelectedStage gespeichert für", player.Name, "→", worldName, "Stage", stageId)

	-- Teleport ausführen
	local ok, result = pcall(function()
		return TeleportService:Teleport(worldData.PlaceId, player)
	end)

	if ok then
		log("✅ Teleport erfolgreich zu", worldName, "Stage", stageId)
		return true
	else
		warn("[StageTeleportService] ❌ Fehler beim Teleport:", result)
		return false
	end
end

return StageTeleportService
