--!strict
-- TowerDefense/MatchServerHandler.server.lua

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TowerDefense = ServerScriptService:WaitForChild("TowerDefense")

--// Remotes
local StartWaveRequest = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("StartWaveRequest")

--// Module
local Modules = ServerScriptService:WaitForChild("Modules")
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))

local WaveManager = require(TowerDefense:WaitForChild("WaveManager"))
local EnemyManager = require(TowerDefense:WaitForChild("EnemyManager"))

--// Einstellungen
local DEBUG = true
local function log(...: any)
	if DEBUG then
		print("[MatchServerHandler]", ...)
	end
end

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

--// Event-Handler
StartWaveRequest.OnServerEvent:Connect(function(player)
	log("📦 Match-Start von", player.Name)
	if WaveManager and WaveManager.StartWave then
		WaveManager:StartWave(1)
	else
		warn("❌ WaveManager.StartWave konnte nicht aufgerufen werden")
	end
end)
