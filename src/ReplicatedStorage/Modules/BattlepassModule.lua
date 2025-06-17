-- BattlepassModule.lua

local module = {}

-- Belohnungspool (echte ItemIDs aus ItemDataModule)
module.FreeRewardsPool = {
	{ id = "Scroll_Alpha", amount = 1, type = "Item" },
	{ id = "Evo_StarPiece", amount = 1, type = "Item" },
	{ id = "Medal_Ruby", amount = 1, type = "Item" },
	{ id = "Skin_PinkDragon", amount = 1, type = "Item" },
	{ id = "EXP_MeatSmall", amount = 1, type = "Item" },
}

-- Infinity-Rewards (für Level > 100)
module.InfinityRewards = {
	{ id = "Scroll_Alpha", amount = 2, type = "Item" },
	{ id = "EXP_MeatSmall", amount = 3, type = "Item" },
	{ id = "Medal_Ruby", amount = 2, type = "Item" },
}

-- EXP pro Level (kann später dynamisch skaliert werden)
local function getEXPForLevel(level)
	return 100 + (level - 1) * 25
end

-- Battlepass generieren
function module.GenerateBattlepassSeason(seed)
	math.randomseed(seed or os.time())
	local shuffled = {}

	-- 1. Shuffle Free-Pool (Zufallsreihenfolge ohne Duplikate)
	local pool = table.clone(module.FreeRewardsPool)
	while #pool > 0 do
		local index = math.random(1, #pool)
		table.insert(shuffled, table.remove(pool, index))
	end

	-- 2. 100 Level erzeugen
	local battlepass = {}

	for level = 1, 100 do
		local reward = shuffled[((level - 1) % #shuffled) + 1]
		local free = table.clone(reward)
		local premium = table.clone(reward)
		premium.amount = premium.amount + 1

		battlepass[level] = {
			expRequired = getEXPForLevel(level),
			free = { free },
			premium = { premium },
		}
	end

	return battlepass
end

-- Exportierte Daten
local SEED = 123456
module.Data = module.GenerateBattlepassSeason(SEED)
module.SeasonSeed = SEED

return module
