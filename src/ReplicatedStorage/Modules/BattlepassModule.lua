-- ReplicatedStorage > BattlepassModule

local module = {}

-- ✅ Pool für mögliche Free-Rewards
module.FreeRewardsPool = {
	{ image = "rbxassetid://107020734473072", label = "100 Eclipsium" },
	{ image = "rbxassetid://83291346465775", label = "1x Attribute Medaillion" },
	{ image = "rbxassetid://134383472964237", label = "1x Reroll Medaillion" },
	{ image = "rbxassetid://114136021497469", label = "5x Universal Fragment" },
	{ image = "rbxassetid://91235668959527", label = "1x Summoning Scroll" }
}

-- ✅ Pool für Premium-Rewards
module.PremiumRewardsPool = {
	{ image = "rbxassetid://107020734473072", label = "200 Eclipsium" },
	{ image = "rbxassetid://83291346465775", label = "2x Attribute Medaillion" },
	{ image = "rbxassetid://134383472964237", label = "2x Reroll Medaillion" },
	{ image = "rbxassetid://114136021497469", label = "10x Universal Fragment" },
	{ image = "rbxassetid://91235668959527", label = "2x Summoning Scroll" }
}

-- ✅ Infinity Mode Pool
module.InfinityRewardsPool = {
	{ image = "rbxassetid://83291346465775", label = "1x Attribute Medaillion" },
	{ image = "rbxassetid://134383472964237", label = "1x Reroll Medaillion" },
	{ image = "rbxassetid://91235668959527", label = "1x Summoning Scroll" }
}

-- 🔥 Methode: Zufällige Verteilung generieren (einmal pro Season)
function module.GenerateBattlepassSeason(seed)
	math.randomseed(seed or os.time())
	local freeRewards = {}
	local premiumRewards = {}

	-- 100 Level generieren
	for i = 1, 100 do
		local freePick = module.FreeRewardsPool[math.random(1, #module.FreeRewardsPool)]
		local premiumPick = module.PremiumRewardsPool[math.random(1, #module.PremiumRewardsPool)]
		table.insert(freeRewards, freePick)
		table.insert(premiumRewards, premiumPick)
	end

	return freeRewards, premiumRewards
end

-- ✅ Direkt beim Laden generieren (für diese Season)
local SEED = 123456 -- Fester Seed für Testzwecke
local freeRewards, premiumRewards = module.GenerateBattlepassSeason(SEED)

-- 🧪 TEST-STEUERUNG ------------------------------

-- 🎯 Aktuelles Level (ändert Locks)
module.CurrentLevel = 7

-- 💎 Premiumzugang an/aus
module.HasPremium = true  -- false = zeigt Lock bei Premium

-- 📊 EXP-Balken-Konfiguration
module.TestEXP = {
	Level = 23,     -- Angezeigter Level oben
	EXP = 180,     -- Aktuelle EXP
	MaxEXP = 4200   -- Nächster Level bei 200
}

-- ⚠️ Wenn du echtes Server-System baust, diese Werte NICHT verwenden!

-- -----------------------------------------------

module.FreeRewards = freeRewards
module.PremiumRewards = premiumRewards
module.SeasonSeed = SEED  -- nur Info

print("✅ BattlepassModule erfolgreich geladen!")
print("Beispiel Reward [1]:", freeRewards[1].label, freeRewards[1].image)

return module
