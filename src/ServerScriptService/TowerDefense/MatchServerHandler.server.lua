--!strict
-- TowerDefense/MatchServerHandler.server.lua

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TowerDefense           = ServerScriptService:WaitForChild("TowerDefense")

--// Module
local Modules = ServerScriptService:WaitForChild("Modules")
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))

local WaveManager         = require(TowerDefense:WaitForChild("WaveManager"))
local EnemyManager        = require(TowerDefense:WaitForChild("EnemyManager"))
local MatchStateModule    = require(TowerDefense:WaitForChild("MatchStateModule"))

--// Remotes
local StartWaveRequest    = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("StartWaveRequest")
local SetTDEclipsium      = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("SetTDEclipsium")
local ProfileChanged      = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")

--// Debug
local DEBUG = true
local function log(...: any)
	if DEBUG then
		print("[MatchServerHandler]", ...)
	end
end

--// Modul
local MatchServerHandler = {}

--// Initialisierung
if WaveManager and WaveManager.Init then
	WaveManager:Init()
else
	warn("⚠️ WaveManager.Init fehlt oder WaveManager nicht korrekt geladen")
end

if EnemyManager and EnemyManager.Init then
	EnemyManager:Init()
else
	warn("⚠️ EnemyManager.Init fehlt oder EnemyManager nicht korrekt geladen")
end

log("✅ MatchServerHandler bereit")

--// SetTDEclipsium: Match-Startgeld setzen (nach Play-Button)
SetTDEclipsium.OnServerEvent:Connect(function(player)
	local profile = ProfileWrapper:GetProfile(player)
	if profile then
		profile.Data.TDEclipsium = 20000
		ProfileChanged:FireClient(player, "TDEclipsium", profile.Data.TDEclipsium)
		log("💰 TDEclipsium gesetzt für", player.Name)
	end
end)

--// StartWaveRequest: Erste Welle starten
StartWaveRequest.OnServerEvent:Connect(function(player)
	log("🌊 Match-Start / Wave beginnt von", player.Name)

	-- Spieler registrieren für MatchState (zukünftig auch Gruppen)
	MatchStateModule.RegisterPlayers({ player })

	if WaveManager and WaveManager.StartWave then
		WaveManager:StartWave(1)
	else
		warn("❌ WaveManager.StartWave konnte nicht aufgerufen werden")
	end
end)

return MatchServerHandler
