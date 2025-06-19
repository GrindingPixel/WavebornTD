-- QuestDataModule.lua

local QuestData = {

	-- 🔁 Daily Quests (wechseln täglich)
	Daily = {
		{
			id = "1",
			title = "Summon 3 Units",
			description = "Use the Summon system 3 times",
			type = "Summon",
			goal = 3,
			rewards = {
				{ type = "Gold", amount = 100 },
				{ type = "Item", id = "Scroll_Basic", amount = 1 }
			}
		},
		{
			id = "D_002",
			title = "Clear 2 Stages",
			description = "Complete any 2 stages",
			type = "StageClear",
			goal = 2,
			rewards = {
				{ type = "Item", id = "XP_Food", amount = 1 }
			}
		},
	},

	-- 📆 Weekly Quests
	Weekly = {
		{
			id = "W_001",
			title = "Win 3 Raids",
			description = "Defeat 3 Raid bosses",
			type = "RaidWin",
			goal = 3,
			rewards = {
				{ type = "Gold", amount = 500 }
			}
		},
		{
			id = "W_002",
			title = "Upgrade a Unit 5 times",
			description = "Level up any Unit 5 times",
			type = "UnitLevelUp",
			goal = 5,
			rewards = {
				{ type = "Item", id = "Scroll_Boss", amount = 1 }
			}
		}
	},

	-- 🧩 Story Quests
	Story = {
		{
			id = "S_001",
			title = "Unlock World 2",
			description = "Finish the last stage in Spirit Realm",
			type = "WorldUnlock",
			goal = 1,
			rewards = {
				{ type = "Gold", amount = 300 }
			}
		}
	},

	-- 🎁 Spezial-Events
	Special = {
		-- Kann z. B. mit Datum aktiviert werden
	},

	-- 🧪 Trials (Test oder Endgame-Challenges)
	Trials = {
		-- z. B. Tower-Limit-Challenge etc.
	},

	-- 📈 Progress-basierte Quests
	Progress = {
		{
			id = "P_001",
			title = "Reach Account Level 15",
			description = "Grind your way up to Level 15",
			type = "PlayerLevel",
			goal = 15,
			rewards = {
				{ type = "Gold", amount = 250 },
				{ type = "Item", id = "Scroll_Premium", amount = 1 }
			}
		}
	}
}

return QuestData
