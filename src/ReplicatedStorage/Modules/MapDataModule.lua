-- MapDataModule.lua

local MapData = {
	Test1 = {
		DisplayName = "Spiele Welt 1",
		Stages = {
			{
				StageId = 1,
				Name = "Stage 1",
				Rewards = {
					{ type = "Scroll", id = "CommonScroll", amount = 1 },
					{ type = "Gold", amount = 100 }
				}
			},
			{
				StageId = 2,
				Name = "Stage 2",
				Rewards = {
					{ type = "Scroll", id = "RareScroll", amount = 1 },
					{ type = "EXP", amount = 150 }
				}
			},
			{
				StageId = 3,
				Name = "Bosskampf",
				Rewards = {
					{ type = "Medal", id = "BossMedal", amount = 1 }
				}
			}
		}
	},

	Test2 = {
		DisplayName = "Spiele Welt 2",
		Stages = {
			{
				StageId = 1,
				Name = "Dunkle Pfade",
				Rewards = {
					{ type = "Gold", amount = 200 },
					{ type = "EXP", amount = 100 }
				}
			}
		}
	}
}

return MapData
