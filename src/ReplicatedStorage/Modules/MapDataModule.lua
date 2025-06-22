-- MapDataModule.lua

--// World & Stage Map Data
local MapData = {

	--🌍 Spirit Realm
	["SpiritRealm"] = {
		DisplayName = "Spirit Realm",
		PlaceId     = 91395451659768,

		Stages = {
			{ StageId = 1, Name = "The Beginning", Rewards = {
				{ type = "Gold", amount = 100 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
			}},
			{ StageId = 2, Name = "Ruined Alley", Rewards = {
				{ type = "Gold", amount = 150 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
			}},
			{ StageId = 3, Name = "Underground Nest", Rewards = {
				{ type = "Gold", amount = 200 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
			}},
			{ StageId = 4, Name = "The Beginning", Rewards = {
				{ type = "Gold", amount = 100 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
			}},
			{ StageId = 5, Name = "Ruined Alley", Rewards = {
				{ type = "Gold", amount = 150 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
			}},
			{ StageId = 6, Name = "Underground Nest", Rewards = {
				{ type = "Gold", amount = 200 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
			}},
		},
	},

	--🌆 City of Ashes
	["City_of_Ashes"] = {
		DisplayName = "City of Ashes",
		PlaceId     = 91395451659768,

		Stages = {
			{ StageId = 1, Name = "Ash Gate", Rewards = {
				{ type = "Gold", amount = 200 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
			}},
			{ StageId = 2, Name = "Forgotten Quarters", Rewards = {
				{ type = "Gold", amount = 250 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
			}},
			{ StageId = 3, Name = "Inner Sanctum", Rewards = {
				{ type = "Gold", amount = 300 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
			}},
			{ StageId = 4, Name = "The Beginning", Rewards = {
				{ type = "Gold", amount = 100 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
			}},
			{ StageId = 5, Name = "Ruined Alley", Rewards = {
				{ type = "Gold", amount = 150 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
			}},
			{ StageId = 6, Name = "Underground Nest", Rewards = {
				{ type = "Gold", amount = 200 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
			}},
		},
	},

	--🗼 Mirai-Tokyo
	["Mirai-Tokyo"] = {
		DisplayName = "City of Ashes",
		PlaceId     = 91395451659768,

		Stages = {
			{ StageId = 1, Name = "Ash Gate", Rewards = {
				{ type = "Gold", amount = 200 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
			}},
			{ StageId = 2, Name = "Forgotten Quarters", Rewards = {
				{ type = "Gold", amount = 250 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
			}},
			{ StageId = 3, Name = "Inner Sanctum", Rewards = {
				{ type = "Gold", amount = 300 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
			}},
			{ StageId = 4, Name = "The Beginning", Rewards = {
				{ type = "Gold", amount = 100 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
			}},
			{ StageId = 5, Name = "Ruined Alley", Rewards = {
				{ type = "Gold", amount = 150 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
			}},
			{ StageId = 6, Name = "Underground Nest", Rewards = {
				{ type = "Gold", amount = 200 },
				{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
			}},
		},
	},

	-- 💡 Weitere Welten können hier folgen:
	-- ["Raid"] = { ... },
	-- ["Trial"] = { ... },
}

return MapData
