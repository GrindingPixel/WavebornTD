--!strict
-- TowerDefense/WaveManager.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TowerDefense = ServerScriptService:WaitForChild("TowerDefense")

--// Module
local EnemyManager = require(TowerDefense:WaitForChild("EnemyManager"))

--// Konfiguration
local EnemyData = require(ReplicatedStorage.Modules.EnemyDataModule)
local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")

--// Debug
local DEBUG = true
local function log(...: any)
	if DEBUG then
		print("[WaveManager]", ...)
	end
end

--// Typdefinitionen
export type WaveGroup = {
	type: string,
	count: number,
	delay: number,
}

export type WaveConfig = { [number]: { WaveGroup } }

--// Wellen-Config
local waveConfig: WaveConfig = {
	[1] = {
		{ type = "Basic", count = 5, delay = 1 },
	},
	[2] = {
		{ type = "Basic", count = 3, delay = 0.5 },
		{ type = "Fast", count = 4, delay = 0.3 },
	},
}

--// Modul
local WaveManager = {}

function WaveManager:Init(): ()
	log("✅ WaveManager bereit")
end

function WaveManager:StartWave(waveNumber: number): ()
	local wave = waveConfig[waveNumber]
	if not wave then
		warn("❌ Unbekannte Wave:", waveNumber)
		return
	end

	log("🌊 Starte Wave:", waveNumber)
	for _, group in ipairs(wave) do
		log("→", group.type, "x", group.count)
	end

	task.spawn(function()
		for _, group in ipairs(wave) do
			if group and group.type then
				for _ = 1, group.count do
					log("🚀 Spawne Gegner:", group.type)
					EnemyManager:SpawnEnemy(group.type)
					task.wait(group.delay)
				end
			else
				warn("⚠️ Ungültige Gruppendaten in Wave:", waveNumber)
			end
		end
	end)
end

return WaveManager
