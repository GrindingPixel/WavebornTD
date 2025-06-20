--// BattlepassInfoProvider.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local ItemDataModule = require(ReplicatedStorage.Modules:WaitForChild("ItemDataModule"))

--// State
local SEASON_SEED = 46446
local battlepassData = {}
local MAX_LEVEL = 100

--// Setup
local function getEXPForLevel(level)
	return math.floor(100 * math.pow(1.12, level - 1))
end

local function pickRandom(list)
	if typeof(list) == "table" and #list > 0 then
		return list[math.random(1, #list)]
	end
	return nil
end

-- Eingebauter RewardPool
local RewardPool = {
	Scrolls = { "SummonScroll" },
	Tokens = { "Reroll_Token", "Attribute_Token" },
	Materials = { "Universal_Fragment" },
	Units = { "Issoi_Highschool" }
}

local function generateBattlepassData(seed)
	math.randomseed(seed or os.time())
	local data = {}

	for i = 1, MAX_LEVEL do
		local rewardType
		local rewardId
		local amount = 1

		if i % 10 == 0 then
			rewardType = "Unit"
			rewardId = pickRandom(RewardPool.Units)
		elseif i % 2 == 0 then
			rewardType = "Item"
			rewardId = pickRandom(RewardPool.Scrolls)
		else
			rewardType = "Item"
			rewardId = pickRandom(RewardPool.Tokens)
		end

		local freeReward = {
			type = rewardType,
			id = rewardId,
			amount = amount,
		}

		local premiumReward = {
			type = rewardType,
			id = rewardId,
			amount = amount * 3,
		}

		data[i] = {
			freeReward = freeReward,
			premiumReward = premiumReward,
		}
	end

	return data
end

--// API
local BattlepassInfoProvider = {}

function BattlepassInfoProvider.Regenerate(seed)
	SEASON_SEED = seed or SEASON_SEED
	battlepassData = generateBattlepassData(SEASON_SEED)
end

function BattlepassInfoProvider.GetLevelData(level)
	return battlepassData[level]
end

function BattlepassInfoProvider.GetEXPRequirement(level)
	return getEXPForLevel(level)
end

function BattlepassInfoProvider.GetMaxLevel()
	return MAX_LEVEL
end

function BattlepassInfoProvider.GetSeasonSeed()
	return SEASON_SEED
end

function BattlepassInfoProvider.GetSeasonData()
	return {
		Seed = SEASON_SEED,
		MaxLevel = MAX_LEVEL,
	}
end

--// Init
BattlepassInfoProvider.Regenerate(SEASON_SEED)

return BattlepassInfoProvider
