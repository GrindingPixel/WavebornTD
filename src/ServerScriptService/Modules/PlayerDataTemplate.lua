-- ServerScriptService.Modules.PlayerDataTemplate.lua

local DefaultPlayerData = {
	-- 💰 Währungen
	TDEclipsium = 500,
	Gems = 50,
	Eclipsium = 10000,

	-- 📦 Items (z. B. Scrolls, EXP-Food)
	Inventory = {
	Scroll = {},
	Token = {},
	Material = {},
	Evo = {},
	Cosmetics = {},
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
