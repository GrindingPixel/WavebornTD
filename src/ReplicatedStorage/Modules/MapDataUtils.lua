--!strict
-- MapDataUtils.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local MapData = require(ReplicatedStorage.Modules.MapDataModule)

--// Typen
export type WaveGroup = {
	type: string,
	count: number,
	delay: number,
}
export type WaveData = { [number]: { WaveGroup } }

--// Module
local MapDataUtils = {}

--// Hilfsfunktion: Holt eine Stage anhand von Weltname + StageId
function MapDataUtils.GetStageById(worldName: string, stageId: number)
	local world = MapData[worldName]
	if not world or not world.Stages then return nil end

	for _, stage in ipairs(world.Stages) do
		if stage.StageId == stageId then
			return stage
		end
	end

	return nil
end

function MapDataUtils.GetPlaceId(mapName: string): number?
	local entry = MapData[mapName]
	if entry and entry.PlaceId then
		return entry.PlaceId
	end
	return nil
end

--// Interner Generator: erzeugt vollständige Wellenstruktur aus Konfig
local function generateWaveData(config): WaveData
	local waveCount = config.WaveCount or 10
	local totalEnemies = config.TotalEnemies or 100
	local minPerWave = config.MinEnemiesPerWave or 10
	local bossScaling = config.BossScaling or 2.5
	local bossWaves = config.BossWaves or {}
	local pool = config.GroupPool or {}
	local rng = Random.new(config.SpawnRandomSeed or tick())

	local waves: WaveData = {}
	local enemyTypes = {}
	local weights = {}

	for _, entry in ipairs(pool) do
		table.insert(enemyTypes, entry)
		table.insert(weights, entry.weight or 1)
	end

	local enemiesPerWave = math.floor(totalEnemies / waveCount)

	for i = 1, waveCount do
		local groups = {}
		local count = 0

		if table.find(bossWaves, i) then
			table.insert(groups, { type = "Boss_Stage" .. tostring(i), count = 1, delay = 0 })
			count += 1
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

--// Hauptfunktion: Erzeugt Wellenplan aus einer Stage
function MapDataUtils.BuildWavePlan(stage: any): WaveData
	if not stage or not stage.WaveConfig then
		warn("⚠️ BuildWavePlan: Ungültige Stage oder fehlende WaveConfig")
		return {}
	end

	return generateWaveData(stage.WaveConfig)
end

--// Rückgabe
return MapDataUtils
