--!strict
-- TowerDefense/WaveManager.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

--// Remotes
local NextWaveAvailable = Remotes.TowerDefenseEvents:WaitForChild("NextWaveAvailable")

--// Modules
local EnemyManager = require(ServerScriptService.TowerDefense.EnemyManager)

--// Typen
export type WaveGroup = {
	type: string,
	count: number,
	delay: number,
}
export type WaveData = { [number]: { WaveGroup } }

--// Debug
local DEBUG = true
local function log(...: any)
	if DEBUG then
		print("[WaveManager]", ...)
	end
end

--// Modul
local WaveManager = {
	GeneratedWaves = {} :: WaveData,
	CurrentWave = 0,
	TotalWaves = 0,
	IsSpawning = false,
}

--// Generator
local function generateWaveData(config): WaveData
	local waveCount = config.WaveCount or 10
	local totalEnemies = config.TotalEnemies or 100
	local minPerWave = config.MinEnemiesPerWave or 10
	local bossWaves = config.BossWaves or {}
	local pool = config.GroupPool or {}
	local rng = Random.new(config.SpawnRandomSeed or tick())

	local waves: WaveData = {}
	local enemyTypes = {}

	for _, entry in ipairs(pool) do
		table.insert(enemyTypes, entry)
	end

	local enemiesPerWave = math.floor(totalEnemies / waveCount)

	for i = 1, waveCount do
		local groups = {}

		if table.find(bossWaves, i) then
			table.insert(groups, { type = "Boss_Stage" .. tostring(i), count = 1, delay = 0 })
		end

		local left = math.max(enemiesPerWave, minPerWave)
		while left > 0 do
			local choice = rng:NextInteger(1, #enemyTypes)
			local group = enemyTypes[choice]
			if left - group.count < 0 then break end
			table.insert(groups, { type = group.type, count = group.count, delay = group.delay })
			left -= group.count
		end

		waves[i] = groups
	end

	return waves
end

--// Init mit Konfig
function WaveManager:Init(config)
	if config and config.AutoGenerate then
		self.GeneratedWaves = generateWaveData(config.AutoGenerate)
		self.TotalWaves = #self.GeneratedWaves
		self.CurrentWave = 0
		self.IsSpawning = false

		if config.AutoGenerate.DebugWaveOutput then
			for waveIndex, groups in pairs(self.GeneratedWaves) do
				log("Welle", waveIndex)
				for _, g in ipairs(groups) do
					log(" ", g.count, "x", g.type)
				end
			end
		end
	else
		warn("⚠️ Keine AutoGenerate-Konfig gefunden in WaveManager:Init")
	end

	log("✅ WaveManager initialisiert")
end

--// Startet nächste Welle
function WaveManager:StartWave(waveNumber: number?)
	if self.IsSpawning then return end

	local nextWave = waveNumber or (self.CurrentWave + 1)
	if nextWave > self.TotalWaves then
		log("🏁 Alle Wellen abgeschlossen – kein weiterer Start")
		return
	end

	self.CurrentWave = nextWave
	local wave = self.GeneratedWaves[self.CurrentWave]
	if not wave then
		warn("❌ Unbekannte Welle:", self.CurrentWave)
		return
	end

	log("🌊 Starte Wave #", self.CurrentWave)
	self.IsSpawning = true

	task.spawn(function()
		for _, group in ipairs(wave) do
			for _ = 1, group.count do
				local success, err = pcall(function()
					EnemyManager:SpawnEnemy(group.type, self.CurrentWave)
				end)
				if not success then warn("❌ Spawn-Fehler:", err) end
				task.wait(group.delay)
			end
		end

		self.IsSpawning = false
		log("✅ Letzter Gegner in Wave #", self.CurrentWave, "gespawnt")

		if self.CurrentWave < self.TotalWaves then
			log("⏱ Nächste Welle startet automatisch in 5 Sekunden")
			task.delay(5, function()
				self:StartWave(self.CurrentWave + 1)
			end)
		else
			log("🏁 Letzte Welle erreicht – kein weiterer Start")
		end
	end)
end

--// Dummy für Kompatibilität – wird nicht mehr verwendet
function WaveManager:OnWaveCleared()
	log("⚠️ OnWaveCleared wird nicht mehr verwendet (AutoWave deaktiviert)")
end

return WaveManager
