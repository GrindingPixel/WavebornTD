--!strict
-- TowerDefense/WaveManager.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

--// Remotes
local TDRemotes = Remotes:WaitForChild("TowerDefenseEvents")
local ShowPlayButton = TDRemotes:WaitForChild("ShowPlayButton")
local NextWaveAvailable = TDRemotes:WaitForChild("NextWaveAvailable")

--// Modules
local EnemyManager = require(ServerScriptService.TowerDefense.EnemyManager)
local ProfileStoreWrapper = require(ServerScriptService.Modules.ProfileStoreWrapper)
local MatchStateModule = require(ServerScriptService.TowerDefense.MatchStateModule)

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
	AutoWaveEnabled = false,
	AliveEnemies = 0, -- ✅ NEU: Eigener Counter
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

	local basePerWave = math.floor(totalEnemies / waveCount)
	local rest = totalEnemies % waveCount

	for i = 1, waveCount do
		local waveEnemyCount = basePerWave
		if i == waveCount then
			waveEnemyCount += rest
		end

		local groups = {}

		if table.find(bossWaves, i) then
			table.insert(groups, { type = "Boss_Stage" .. tostring(i), count = 1, delay = 0 })
			waveEnemyCount -= 1
		end

		waveEnemyCount = math.max(waveEnemyCount, minPerWave)

		while waveEnemyCount > 0 do
			local choice = rng:NextInteger(1, #enemyTypes)
			local group = enemyTypes[choice]

			if group.count <= waveEnemyCount then
				table.insert(groups, {
					type = group.type,
					count = group.count,
					delay = group.delay,
				})
				waveEnemyCount -= group.count
			else
				break
			end
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
		self.AliveEnemies = 0

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

--// Setzt AutoWave-Einstellung
function WaveManager:SetAutoWaveEnabled(enabled: boolean)
	self.AutoWaveEnabled = enabled
	log("🔁 AutoWaveEnabled auf", enabled)
end

function WaveManager:StartWave(waveNumber: number?)
	log("📥 StartWave aufgerufen mit:", waveNumber or "nil", "→ Aktuelle Welle:", self.CurrentWave)

	if self.IsSpawning then
		log("⚠️ StartWave abgebrochen – IsSpawning = true")
		return
	end

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
					local enemy = EnemyManager:SpawnEnemy(group.type, self.CurrentWave)

					if enemy and enemy:IsA("Model") then
						local humanoid = enemy:FindFirstChildOfClass("Humanoid")
						if humanoid then
							self.AliveEnemies += 1 -- ✅ Beim Spawn hochzählen
							log("🧮 AliveEnemies:", self.AliveEnemies)

							humanoid.Died:Connect(function()
								self.AliveEnemies -= 1
								log("💀 Gegner besiegt – AliveEnemies:", self.AliveEnemies)
								self:CheckVictoryCondition()
							end)
						end
					end
				end)
				if not success then warn("❌ Spawn-Fehler:", err) end
				task.wait(group.delay)
			end
		end

		self.IsSpawning = false
		log("✅ Letzter Gegner in Wave #", self.CurrentWave, "gespawnt")

		task.defer(function()
			self:CheckVictoryCondition()
		end)

		if self.CurrentWave < self.TotalWaves then
			task.delay(5, function()
				if self.AutoWaveEnabled then
					log("⏱ AutoWave aktiv beim Timeout – starte nächste Welle")
					self:StartWave(self.CurrentWave + 1)
				else
					log("⏹ AutoWave deaktiviert beim Timeout – Spielerstart erforderlich")
					for _, player in ipairs(Players:GetPlayers()) do
						local profile = ProfileStoreWrapper:GetProfile(player)
						if profile then
							ShowPlayButton:FireClient(player)
						end
					end
				end
			end)
		else
			log("🏁 Letzte Welle erreicht – kein weiterer Start")
		end
	end)
end

--// Prüft, ob Match gewonnen ist (nur via AliveEnemies Counter)
function WaveManager:CheckVictoryCondition()
	log("📊 [VictoryCheck] AliveEnemies:", self.AliveEnemies, " | Wave:", self.CurrentWave, "/", self.TotalWaves)

	if self.CurrentWave >= self.TotalWaves and self.AliveEnemies <= 0 then
		log("🏆 MatchVictory-Bedingung erfüllt – sende EndMatch(Victory)")
		MatchStateModule.EndMatch("Victory")
	end
end

function WaveManager:OnWaveCleared()
	log("⚠️ OnWaveCleared wird nicht mehr verwendet (AutoWave deaktiviert)")
end

function WaveManager:Reset()
	log("🔁 WaveManager Reset gestartet")

	self.CurrentWave = 0
	self.AliveEnemies = 0
	self.IsSpawning = false
	self.GeneratedWaves = {}
end


return WaveManager
