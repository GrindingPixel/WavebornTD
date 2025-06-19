-- BattlepassInfoProvider.server.lua
-- Typ: ModuleScript

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ItemData = require(ReplicatedStorage.Modules:WaitForChild("ItemDataModule"))

--// Konfiguration
local SEASON_SEED = 123456 -- später austauschbar für neue Seasons

-- Belohnungspool (nur IDs die in ItemData existieren)
local FreeRewardsPool = {
	{ id = "Scroll_Alpha", amount = 1, type = "Item" },
	{ id = "Evo_StarPiece", amount = 1, type = "Item" },
	{ id = "Medal_Ruby", amount = 1, type = "Item" },
	{ id = "Skin_PinkDragon", amount = 1, type = "Item" },
	{ id = "EXP_MeatSmall", amount = 1, type = "Item" },
}

-- EXP-Kurve
local function getEXPForLevel(level)
	return 100 + (level - 1) * 25
end

-- Battlepass Datenstruktur generieren
local function generateBattlepassData(seed)
	math.randomseed(seed)
	local pool = table.clone(FreeRewardsPool)
	local shuffled = {}

	-- Shuffle Belohnungen (keine Duplikate bis einmal komplett durch)
	while #pool > 0 do
		local index = math.random(1, #pool)
		table.insert(shuffled, table.remove(pool, index))
	end

	local data = {}

	for level = 1, 100 do
		local rewardIndex = ((level - 1) % #shuffled) + 1
		local baseReward = table.clone(shuffled[rewardIndex])
		local premiumReward = table.clone(baseReward)
		premiumReward.amount += 1

		data[level] = {
			expRequired = getEXPForLevel(level),
			free = { baseReward },
			premium = { premiumReward },
		}
	end

	return data
end

-- Server-seitig gecachte Daten
local battlepassData = generateBattlepassData(SEASON_SEED)

-- Exportierte Schnittstelle
local module = {}

function module.GetSeasonData()
	return battlepassData
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
