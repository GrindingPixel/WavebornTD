-- ServerScriptService.Modules.PlayerDataTemplate.lua

local DefaultPlayerData = {
	-- 💰 Währungen
	Gold = 1000,
	Gems = 50,

	-- 📦 Items (z. B. Scrolls, EXP-Food)
	Inventory = {
		["Scroll_Basic"] = 3,
		["XP_Food"] = 1,
	},

	-- 🧙‍♂️ Units
	Units = {
		["Issoi_Highschool"] = {
			Level = 1,
			XP = 0,
			Equipped = false,
			Trait = nil,
			SkillTree = {}
		}
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
		Level = 1,
		EXP = 0,
		Claimed = {},
	}
}

return DefaultPlayerData
