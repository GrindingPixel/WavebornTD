-- BattlepassInfoProvider.lua
-- Typ: ModuleScript

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local ItemData = require(ReplicatedStorage.Modules:WaitForChild("ItemDataModule"))

--// Konfiguration
local SEASON_SEED = 20221522 -- oder dynamisch einstellbar

-- Belohnungspool (IDs müssen in ItemData existieren)
local FreeRewardsPool = {
	{ id = "SummonScroll", amount = 1, type = "Item" },
	{ id = "Attribute_Token", amount = 1, type = "Item" },
	{ id = "Universal_Fragment", amount = 1, type = "Item" },
	{ id = "Reroll_Token", amount = 1, type = "Item" },
	{ id = "Medal_Ruby", amount = 1, type = "Item" },
}

-- EXP-Kurve
local function getEXPForLevel(level)
	return 100 + (level - 1) * 25
end

-- Battlepass generieren
local function generateBattlepassData(seed)
	math.randomseed(seed)
	local pool = table.clone(FreeRewardsPool)
	local shuffled = {}

	while #pool > 0 do
		local i = math.random(1, #pool)
		table.insert(shuffled, table.remove(pool, i))
	end

	local data = {}

	for level = 1, 100 do
		local rewardIndex = ((level - 1) % #shuffled) + 1
		local base = table.clone(shuffled[rewardIndex])
		local premium = table.clone(base)
		premium.amount += 1

		data[level] = {
			expRequired = getEXPForLevel(level),
			free = { base },
			premium = { premium },
		}
	end

	return data
end

--// Modulstruktur
local module = {}

local battlepassData = generateBattlepassData(SEASON_SEED) -- 💡 nur hier lokal erzeugen

function module.Regenerate(newSeed)
	SEASON_SEED = newSeed or SEASON_SEED
	battlepassData = generateBattlepassData(SEASON_SEED)
	warn("[BattlepassInfoProvider] Neuer Battlepass mit Seed", SEASON_SEED, "generiert")
end

function module.GetSeasonData()
	return battlepassData
end

function module.GetSeasonSeed()
	return SEASON_SEED
end

function module.GetLevelData(level)
	return battlepassData[level]
end

function module.GetEXPRequirement(level)
	local entry = battlepassData[level]
	return entry and entry.expRequired or 0
end

function module.GetMaxLevel()
	return 100
end

return module
