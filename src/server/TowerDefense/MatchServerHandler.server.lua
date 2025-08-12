--!strict
-- TowerDefense/MatchServerHandler.server.lua

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// Module-Struktur
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TDRemotes = Remotes:WaitForChild("TowerDefenseEvents")
local Modules = ServerScriptService:WaitForChild("Modules")
local TowerDefense = ServerScriptService:WaitForChild("TowerDefense")

--// Module
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local WaveManager = require(TowerDefense:WaitForChild("WaveManager"))
local EnemyManager = require(TowerDefense:WaitForChild("EnemyManager"))
local MatchStateModule = require(TowerDefense:WaitForChild("MatchStateModule"))
local MapDataUtils = require(ReplicatedStorage:WaitForChild("MapDataUtils"))
local ProfileSyncService = require(Modules:WaitForChild("ProfileSyncService"))


--// Remotes
local StartWaveRequest 		= TDRemotes:WaitForChild("StartWaveRequest")
local SetTDEclipsium 		= TDRemotes:WaitForChild("SetTDEclipsium")
local MatchResultAction 	= TDRemotes:WaitForChild("MatchResultAction")
local ShowStartButton 		= TDRemotes:WaitForChild("ShowStartButton")
local SetAutoWaveEnabled 	= ReplicatedStorage.Remotes.Settings:WaitForChild("SetAutoWaveEnabled")
local SetSeamlessEnabled 	= ReplicatedStorage.Remotes.Settings:WaitForChild("SetSeamlessEnabled")

--// Debug
local DEBUG = true
local function log(...: any)
	if DEBUG then
		print("[MatchServerHandler]", ...)
	end
end

--// State
local matchStarted = false

--// Initialisierung
if EnemyManager and EnemyManager.Init then
	EnemyManager:Init()
else
	warn("⚠️ EnemyManager.Init fehlt oder EnemyManager nicht korrekt geladen")
end

EnemyManager:SetOnBaseDestroyed(function()
	MatchStateModule.EndMatch("Defeat")
end)

log("✅ MatchServerHandler bereit")

--// Startgeld setzen (Debug oder Tutorial)
SetTDEclipsium.OnServerEvent:Connect(function(player)
	local profile = ProfileWrapper:GetProfile(player)
	if not profile then return end

	profile.Data.Player.TDEclipsium = 20000
	ProfileSyncService:Send(player, "TDEclipsium", profile.Data.Player.TDEclipsium)
end)

--// AutoWave vom Client setzen
SetAutoWaveEnabled.OnServerEvent:Connect(function(player, enabled: boolean)
	log("🔁 AutoWave von", player.Name, "→", enabled)
	ProfileWrapper:SetSetting(player, "AutoWaveEnabled", enabled)

	if matchStarted then
		WaveManager:SetAutoWaveEnabled(enabled)
	end
end)

SetSeamlessEnabled.OnServerEvent:Connect(function(player, enabled: boolean)
	log("⚙️ SeamlessRestart von", player.Name, "→", enabled)
	local mode = enabled and "seamless" or "teleport"
	ProfileWrapper:SetSetting(player, "RestartMode", mode)
end)

--// Wellenstart (Initial oder Folge-Welle)
StartWaveRequest.OnServerEvent:Connect(function(player, mode)
	log("📡 StartWaveRequest vom Client erhalten – Mode:", mode or "nil")

	if mode == "NextWave" then
		if not matchStarted then
			warn("⚠️ Match noch nicht gestartet – NextWave ignoriert")
			return
		end
		WaveManager:StartWave()
		return
	end

	-- Spielstart
	if matchStarted then
		warn("⚠️ Match bereits gestartet – Init ignoriert")
		return
	end

	log("🌊 Starte Match von:", player.Name)
	matchStarted = true

	-- Profil laden
	local profile = ProfileWrapper:GetProfile(player)
	if not profile then
		warn("❌ Kein Profil für", player.Name)
		return
	end

	local teleportData = ProfileWrapper:GetSelectedStage(player)
	print("📦 teleportData =", teleportData)
	if not teleportData or teleportData.MapName == "" or teleportData.StageId <= 0 then
		warn("❌ Kein gültiger SelectedStage im Profil:", player.Name)
		return
	end

	log("🧭 Spieler ausgewählte Stage:", teleportData.MapName, teleportData.StageId)

	local stage = MapDataUtils.GetStageById(teleportData.MapName, teleportData.StageId)
	if not stage then
		warn("❌ MapDataUtils konnte Stage nicht finden:", teleportData.MapName, teleportData.StageId)
		return
	end

	-- Spieler registrieren + Stage übergeben
	MatchStateModule.RegisterPlayers({ player }, stage)

	-- Wellenlogik initialisieren
	WaveManager:Init({ AutoGenerate = stage.WaveConfig })
	log("📦 Wellenplan generiert mit", stage.WaveConfig.WaveCount, "Wellen")

	-- AutoWave synchronisieren
	local settings = ProfileWrapper:GetSettings(player)
	WaveManager:SetAutoWaveEnabled(settings.AutoWaveEnabled == true)

	-- Erste Welle starten
	WaveManager:StartWave(1)
end)

MatchResultAction.OnServerEvent:Connect(function(player, action)
	local selectedStage = ProfileWrapper:GetSelectedStage(player)
	local mapName = selectedStage.MapName
	local stageId = selectedStage.StageId

	local StageTeleportService = require(Modules:WaitForChild("StageTeleportService"))
	local MapData = require(ReplicatedStorage.MapDataModule)

	if action == "Leave" then
		log("🚪 Leave-Button gedrückt – zurück zur Lobby.")
		StageTeleportService.TeleportToStage(player, "Lobby", 0)
		return

	elseif action == "Restart" then
		local restartMode = ProfileWrapper:GetSettings(player).RestartMode or "teleport"

		if restartMode == "seamless" then
			log("🔁 Seamless Restart – Reset MatchState in aktueller Instanz für", player.Name)

			MatchStateModule.Reset()
			WaveManager:Reset()
			EnemyManager:Reset()
			matchStarted = false

			local profile = ProfileWrapper:GetProfile(player)
			if profile then
				profile.Data.Player.TDEclipsium = nil
			end

			local ShowStartButton = TDRemotes:FindFirstChild("ShowStartButton")
			if ShowStartButton then
				ShowStartButton:FireClient(player)
			end

			return
		end

		log("🔁 Restart – teleportiere erneut zu", mapName, "Stage", stageId)
		StageTeleportService.TeleportToStage(player, mapName, stageId)
		return

	elseif action == "Continue" then
		local profile = ProfileWrapper:GetProfile(player)
		if not profile then return end

		if mapName == "" or stageId == 0 then
			warn("[Continue] Kein gültiger SelectedStage gesetzt.")
			return
		end

		local nextStage = stageId + 1
		local mapInfo = MapData[mapName]

		if mapInfo and mapInfo.Stages and mapInfo.Stages[nextStage] then
			ProfileWrapper:SetSelectedStage(player, mapName, nextStage)
			StageTeleportService.TeleportToStage(player, mapName, nextStage)
			return
		else
			warn("[Continue] Kein nächstes Stage gefunden für:", mapName, "→", nextStage)
			return
		end

	elseif action == "Next" then
		local mapInfo = MapData[mapName]
		local stageInfo = nil

		if mapInfo and mapInfo.Stages then
			for _, stage in pairs(mapInfo.Stages) do
				if stage.StageId == stageId then
					stageInfo = stage
					break
				end
			end
		end

		if stageInfo and stageInfo.NextStage then
			local nextMap = stageInfo.NextStage.MapName
			local nextStageId = stageInfo.NextStage.StageId
			log("➡️ NextStage: teleportiere", player.Name, "→", nextMap, "Stage", nextStageId)

			ProfileWrapper:SetSelectedStage(player, nextMap, nextStageId)
			StageTeleportService.TeleportToStage(player, nextMap, nextStageId)
		else
			warn("[Next] Kein NextStage definiert für", mapName, "Stage", stageId)
		end
	end
end)





return
