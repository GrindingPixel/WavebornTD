-- BattlepassModule.lua

--// Module
local module = {}

--// Pools

-- ✅ Pool für mögliche Free-Rewards
module.FreeRewardsPool = {
	{ image = "rbxassetid://107020734473072", label = "100 Eclipsium" },
	{ image = "rbxassetid://83291346465775", label = "1x Attribute Medaillion" },
	{ image = "rbxassetid://134383472964237", label = "1x Reroll Medaillion" },
	{ image = "rbxassetid://114136021497469", label = "5x Universal Fragment" },
	{ image = "rbxassetid://91235668959527", label = "1x Summoning Scroll" },
}

-- ✅ Pool für mögliche Premium-Rewards
module.PremiumRewardsPool = {
	{ image = "rbxassetid://107020734473072", label = "200 Eclipsium" },
	{ image = "rbxassetid://83291346465775", label = "2x Attribute Medaillion" },
	{ image = "rbxassetid://134383472964237", label = "2x Reroll Medaillion" },
	{ image = "rbxassetid://114136021497469", label = "10x Universal Fragment" },
	{ image = "rbxassetid://91235668959527", label = "2x Summoning Scroll" },
}

-- ✅ Infinity Mode Pool
module.InfinityRewardsPool = {
	{ image = "rbxassetid://83291346465775", label = "1x Attribute Medaillion" },
	{ image = "rbxassetid://134383472964237", label = "1x Reroll Medaillion" },
	{ image = "rbxassetid://91235668959527", label = "1x Summoning Scroll" },
}

--// Methoden

-- 🔥 Battlepass-Generation (einmal pro Season)
function module.GenerateBattlepassSeason(seed)
	math.randomseed(seed or os.time())
	local freeRewards = {}
	local premiumRewards = {}

	for i = 1, 100 do
		local freePick    = module.FreeRewardsPool[math.random(1, #module.FreeRewardsPool)]
		local premiumPick = module.PremiumRewardsPool[math.random(1, #module.PremiumRewardsPool)]
		table.insert(freeRewards, freePick)
		table.insert(premiumRewards, premiumPick)
	end

	return freeRewards, premiumRewards
end

--// Tests (nur für lokale Simulation, später ersetzen durch serverseitige Daten)

-- ✅ Battlepass-Daten für die aktuelle Season erzeugen
local SEED = 123456
local freeRewards, premiumRewards = module.GenerateBattlepassSeason(SEED)

-- 🎯 Aktuelles Level (Einfluss auf Locks im UI)
module.CurrentLevel = 7

-- 💎 Premiumstatus für Sichtbarkeit & Sperren
module.HasPremium = true

-- 📊 EXP-Balken Testdaten
module.TestEXP = {
	Level = 23,
	EXP = 180,
	MaxEXP = 4200,
}

--// Exportierte Daten
module.FreeRewards      = freeRewards
module.PremiumRewards   = premiumRewards
module.SeasonSeed       = SEED

--// Debug
print("✅ BattlepassModule erfolgreich geladen!")
print("Beispiel Reward [1]:", freeRewards[1].label, freeRewards[1].image)

return module
