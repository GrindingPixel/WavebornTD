-- ServerScriptService.Modules.PlayerDataTemplate.lua

local DefaultPlayerData = {
	-- Spieler-Informationen
	Player = {
		Name = "",
		UserId = "",
		Level = 1,
		Exp = 0,
		-- Currency
		Eclipsium = 10000,
		TDEclipsium = 500,
		Gems = 50,
			-- 🕒 Statistiken
		TimePlayed = 0, -- Sekunden
		LastLogin = os.time(),
		TotalEclipsium = 0,
		TotalGems = 0,
		TotalSummons = 0,
		TotalReroll_Token = 0,
		TotalAttribute_Token = 0,
--[[	TotalMVP = 0,
		TotalMatches = 0,
		TotalStages = 0,
		TotalRaids = 0,
		TotalTowerClears = 0,
		TotalQuestsCompleted = 0, 
		HighestWave = 0, ]]
		TotalKills = 0,
		TotalWins = 0,
		TotalLosses = 0,
	
	},

	-- 📦 Items (z. B. Scrolls, EXP-Food)
	Inventory = {
		Scroll = {},
		Token = {},
		Material = {},
		Evo = {},
		Cosmetics = {},
	},

	-- Settings
	Settings = {
		AutoWaveEnabled = false,
		RestartMode = "teleport", -- "seamless" oder "teleport"
	},

	-- 🗺️ Stage
	Teleport = {
		SelectedStage = {
			MapName = "",
			StageId = 0,
		}
	},
	-- 🧙‍♂️ Units
	Units = {
		-- Beispielstruktur:
		-- ["UNIT_A1B2C3"] = {
		--     Id = "Issoi_Highschool",
		--     StarLevel = 3,
		--     Level = 1,
		--     Exp = 0,
		--     Traits = {},
		--     Skin = nil,
		--     IsLocked = false
		-- }
		},

	-- 🧠 Aktive Slots
	EquippedUnits = { nil, nil, nil, nil, nil, nil },

	-- 📋 Quests
	QuestProgress = {
		Daily    = {},
		Weekly   = {},
		Story    = {},
		Special  = {},
		Trials   = {},
		Progress = {},
	},

	-- 🔧 Upgrades
	Upgrades = {
		InventorySize = 30,
		TraitSlots = 1,
	},

	-- 🗓️ Sonstige Zustände
	Login = {
		LastLogin = os.time(),
		ClaimedToday = false
	},

	-- 🎟 Battlepass
	Battlepass = {
		Level = 0,
		EXP = 0,
		Claimed = {},
		HasPremium = false,
	},

	--	🛒 Shop-Daten
	Purchases = {
		-- Beispielstruktur:
		-- ["PRODUCT_ID"] = {
		--     Count = 1,
		--     LastPurchase = os.time()
		-- }
	}
}

return DefaultPlayerData
