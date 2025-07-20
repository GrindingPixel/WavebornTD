--!strict
-- TowerDefense/WaveManager.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TowerDefense = ServerScriptService:WaitForChild("TowerDefense")

--// Modules
local EnemyManager = require(TowerDefense.EnemyManager)
local MatchStateModule = require(TowerDefense.MatchStateModule)

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

--// State
local currentWave = 0
local waveCount = #waveConfig

--// Modul
local WaveManager = {}

function WaveManager:Init(): ()
	log("✅ WaveManager bereit")
end

-- Starte bestimmte Wave (manuell durch NextWave)
function WaveManager:StartWave(waveNumber: number): ()
	local wave = waveConfig[waveNumber]
	if not wave then
		warn("❌ Unbekannte Wave:", waveNumber)
		return
	end

	currentWave = waveNumber
	log("🌊 Starte Wave", currentWave, "/", waveCount)

	for _, group in ipairs(wave) do
		log("→", group.type, "x", group.count)
	end

	task.spawn(function()
		for _, group in ipairs(wave) do
			if group and group.type then
				for _ = 1, group.count do
					log("🚀 Spawne Gegner:", group.type, waveNumber)
					EnemyManager:SpawnEnemy(group.type, waveNumber)
					task.wait(group.delay)
				end
			else
				warn("⚠️ Ungültige Gruppendaten in Wave:", waveNumber)
			end
		end

		-- Verzögerung, danach prüfen ob Gegner alle besiegt wurden
		task.delay(3, function()
			WaveManager:CheckNextStep()
		end)
	end)
end

function WaveManager:CheckNextStep()
	local alive = EnemyManager:GetAliveEnemyCount()
	log("👀 Gegner verbleibend:", alive)

	if alive == 0 then
		if currentWave < waveCount then
			self:StartWave(currentWave + 1)
		else
			log("🎉 Alle Waves abgeschlossen – Victory!")
			MatchStateModule.EndMatch("Victory")
		end
	else
		log("⏳ Gegner noch aktiv – warte...")
		task.delay(2, function()
			WaveManager:CheckNextStep()
		end)
	end
end

return WaveManager
