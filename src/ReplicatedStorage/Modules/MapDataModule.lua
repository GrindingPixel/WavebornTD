--!strict
-- MapDataModule.lua

--// World & Stage Map Data
local MapData = {

	["Lobby"] = {
		DisplayName = "Lobby",
		PlaceId     = 84670806766416, -- Beispiel-PlaceId, anpassen!

		Stages = {
			{
				StageId = 1,
				Name = "Lobby Stage",
			},
		},
	},
		
	--🌍 Spirit Realm
	["SpiritRealm"] = {
		DisplayName = "Spirit Realm",
		PlaceId     = 128061510848823,

		Stages = {
			{
				StageId = 1,
				Name = "The Beginning",
				WaveConfig = {
					WaveCount = 2,
					TotalEnemies = 5,
					MinEnemiesPerWave = 1,
					BossScaling = 2.5,
					SpawnRandomSeed = 42,
					BossWaves = {},
					GroupPool = {
						{ type = "Basic", count = 1, delay = 0.4, weight = 5 },
					},
				},
				Rewards = {
					{ type = "Eclipsium", amount = 100 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
			{
				StageId = 2,
				Name = "Ruined Alley",
				WaveConfig = {
					WaveCount = 15,
					TotalEnemies = 400,
					MinEnemiesPerWave = 20,
					BossScaling = 2.5,
					SpawnRandomSeed = 42,
					BossWaves = { 5, 10, 15 },
					GroupPool = {
						{ type = "Basic", count = 5, delay = 0.4, weight = 5 },
						{ type = "Fast", count = 4, delay = 0.3, weight = 3 },
					},
				},
				Rewards = {
					{ type = "Eclipsium", amount = 100 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
				}
			},
			{
				StageId = 3,
				Name = "Underground Nest",
				WaveConfig = {
					WaveCount = 15,
					TotalEnemies = 400,
					MinEnemiesPerWave = 20,
					BossScaling = 2.5,
					SpawnRandomSeed = 42,
					BossWaves = { 5, 10, 15 },
					GroupPool = {
						{ type = "Basic", count = 5, delay = 0.4, weight = 5 },
						{ type = "Fast", count = 4, delay = 0.3, weight = 3 },
						{ type = "Tank", count = 2, delay = 0.8, weight = 2 },
						{ type = "Miniboss", count = 1, delay = 0.0, weight = 1 },
					},
				},
				Rewards = {
					{ type = "Gold", amount = 200 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
			{
				StageId = 4,
				Name = "The Beginning",
				WaveConfig = {
					WaveCount = 2,
					TotalEnemies = 5,
					MinEnemiesPerWave = 1,
					BossScaling = 2.5,
					SpawnRandomSeed = 42,
					BossWaves = {},
					GroupPool = {
						{ type = "Basic", count = 1, delay = 0.4, weight = 5 },
					},
				},
				Rewards = {
					{ type = "Eclipsium", amount = 100 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
			{
				StageId = 5,
				Name = "Ruined Alley",
				WaveConfig = {
					WaveCount = 15,
					TotalEnemies = 400,
					MinEnemiesPerWave = 20,
					BossScaling = 2.5,
					SpawnRandomSeed = 42,
					BossWaves = { 5, 10, 15 },
					GroupPool = {
						{ type = "Basic", count = 5, delay = 0.4, weight = 5 },
						{ type = "Fast", count = 4, delay = 0.3, weight = 3 },
						{ type = "Tank", count = 2, delay = 0.8, weight = 2 },
						{ type = "Miniboss", count = 1, delay = 0.0, weight = 1 },
					},
				},
				Rewards = {
					{ type = "Gold", amount = 150 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
				}
			},
			{
				StageId = 6,
				Name = "Underground Nest",
				WaveConfig = {
					WaveCount = 1,
					TotalEnemies = 2,
					MinEnemiesPerWave = 1,
					BossScaling = 2.5,
					SpawnRandomSeed = 43,
					BossWaves = { 5, 10, 15 },
					GroupPool = {
						{ type = "Basic", count = 5, delay = 0.4, weight = 5 },
					},
				},
				Rewards = {
					{ type = "Gold", amount = 200 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				},
				NextStage = {
        			MapName = "City_of_Ashes",
        			StageId = 1
      			}
			},	
		},
	},

	--🌆 City of Ashes
	["City_of_Ashes"] = {
		DisplayName = "City of Ashes",
		PlaceId     = 91395451659768,

		Stages = {
			{
				StageId = 1,
				Name = "Ash Gate",
				WaveConfig = {
					WaveCount = 2,
					TotalEnemies = 5,
					MinEnemiesPerWave = 1,
					BossScaling = 2.5,
					SpawnRandomSeed = 42,
					BossWaves = {},
					GroupPool = {
						{ type = "Basic", count = 1, delay = 0.4, weight = 5 },
					},
				},
				Rewards = {
					{ type = "Eclipsium", amount = 100 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
			{
				StageId = 2,
				Name = "Forgotten Quarters",
				WaveConfig = {
					WaveCount = 15,
					TotalEnemies = 400,
					MinEnemiesPerWave = 20,
					BossScaling = 2.5,
					SpawnRandomSeed = 42,
					BossWaves = { 5, 10, 15 },
					GroupPool = {
						{ type = "Basic", count = 5, delay = 0.4, weight = 5 },
						{ type = "Fast", count = 4, delay = 0.3, weight = 3 },
						{ type = "Tank", count = 2, delay = 0.8, weight = 2 },
						{ type = "Miniboss", count = 1, delay = 0.0, weight = 1 },
					},
				},
				Rewards = {
					{ type = "Gold", amount = 150 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
				}
			},
			{
				StageId = 3,
				Name = "Inner Sanctum",
				WaveConfig = {
					WaveCount = 15,
					TotalEnemies = 400,
					MinEnemiesPerWave = 20,
					BossScaling = 2.5,
					SpawnRandomSeed = 42,
					BossWaves = { 5, 10, 15 },
					GroupPool = {
						{ type = "Basic", count = 5, delay = 0.4, weight = 5 },
						{ type = "Fast", count = 4, delay = 0.3, weight = 3 },
						{ type = "Tank", count = 2, delay = 0.8, weight = 2 },
						{ type = "Miniboss", count = 1, delay = 0.0, weight = 1 },
					},
				},
				Rewards = {
					{ type = "Gold", amount = 200 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			}
		}	--🌆 City of Ashes (noch ohne WaveConfig – TODO analog SpiritRealm ergänzen)

	}	--🗌 Weitere Welten folgen
}

return MapData




























































--[[!strict
-- MapDataModule.lua

--// World & Stage Map Data
local MapData = {

	--🌍 Spirit Realm
	["SpiritRealm"] = {
		DisplayName = "Spirit Realm",
		PlaceId     = 91395451659768,

		Stages = {
			{
				StageId = 1,
				Name = "The Beginning",
				WaveConfig = {
					{ type = "Basic", count = 5, delay = 1 }
				},
				Rewards = {
					{ type = "Gold", amount = 100 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
			{
				StageId = 2,
				Name = "Ruined Alley",
				WaveConfig = {
					{ type = "Basic", count = 3, delay = 0.5 },
					{ type = "Fast", count = 4, delay = 0.3 },
				},
				Rewards = {
					{ type = "Gold", amount = 150 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
				}
			},
			{
				StageId = 3,
				Name = "Underground Nest",
				WaveConfig = {
					{ type = "Basic", count = 3, delay = 0.5 },
					{ type = "Fast", count = 4, delay = 0.3 },
				},
				Rewards = {
					{ type = "Gold", amount = 200 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
			{
				StageId = 4,
				Name = "The Beginning",
				WaveConfig = {
					{ type = "Basic", count = 5, delay = 1 }
				},
				Rewards = {
					{ type = "Gold", amount = 100 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
			{
				StageId = 5,
				Name = "Ruined Alley",
				WaveConfig = {
					{ type = "Basic", count = 3, delay = 0.5 },
					{ type = "Fast", count = 4, delay = 0.3 },
				},
				Rewards = {
					{ type = "Gold", amount = 150 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
				}
			},
			{
				StageId = 6,
				Name = "Underground Nest",
				WaveConfig = {
					{ type = "Basic", count = 3, delay = 0.5 },
					{ type = "Fast", count = 4, delay = 0.3 },
				},
				Rewards = {
					{ type = "Gold", amount = 200 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
		},
	},

	--🌆 City of Ashes
	["City_of_Ashes"] = {
		DisplayName = "City of Ashes",
		PlaceId     = 91395451659768,

		Stages = {
			{
				StageId = 1,
				Name = "Ash Gate",
				WaveConfig = {
					{ type = "Basic", count = 5, delay = 1 }
				},
				Rewards = {
					{ type = "Gold", amount = 200 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
			{
				StageId = 2,
				Name = "Forgotten Quarters",
				WaveConfig = {
					{ type = "Basic", count = 3, delay = 0.5 },
					{ type = "Fast", count = 4, delay = 0.3 },
				},
				Rewards = {
					{ type = "Gold", amount = 250 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
				}
			},
			{
				StageId = 3,
				Name = "Inner Sanctum",
				WaveConfig = {
					{ type = "Basic", count = 3, delay = 0.5 },
					{ type = "Fast", count = 4, delay = 0.3 },
				},
				Rewards = {
					{ type = "Gold", amount = 300 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
			{
				StageId = 4,
				Name = "The Beginning",
				WaveConfig = {
					{ type = "Basic", count = 5, delay = 1 }
				},
				Rewards = {
					{ type = "Gold", amount = 100 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
			{
				StageId = 5,
				Name = "Ruined Alley",
				WaveConfig = {
					{ type = "Basic", count = 3, delay = 0.5 },
					{ type = "Fast", count = 4, delay = 0.3 },
				},
				Rewards = {
					{ type = "Gold", amount = 150 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
				}
			},
			{
				StageId = 6,
				Name = "Underground Nest",
				WaveConfig = {
					{ type = "Basic", count = 3, delay = 0.5 },
					{ type = "Fast", count = 4, delay = 0.3 },
				},
				Rewards = {
					{ type = "Gold", amount = 200 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
		},
	},

	--🗼 Mirai-Tokyo
	["Mirai-Tokyo"] = {
		DisplayName = "Mirai-Tokyo",
		PlaceId     = 91395451659768,

		Stages = {
			{
				StageId = 1,
				Name = "Ash Gate",
				WaveConfig = {
					{ type = "Basic", count = 5, delay = 1 }
				},
				Rewards = {
					{ type = "Gold", amount = 200 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
			{
				StageId = 2,
				Name = "Forgotten Quarters",
				WaveConfig = {
					{ type = "Basic", count = 3, delay = 0.5 },
					{ type = "Fast", count = 4, delay = 0.3 },
				},
				Rewards = {
					{ type = "Gold", amount = 250 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
				}
			},
			{
				StageId = 3,
				Name = "Inner Sanctum",
				WaveConfig = {
					{ type = "Basic", count = 3, delay = 0.5 },
					{ type = "Fast", count = 4, delay = 0.3 },
				},
				Rewards = {
					{ type = "Gold", amount = 300 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
			{
				StageId = 4,
				Name = "The Beginning",
				WaveConfig = {
					{ type = "Basic", count = 5, delay = 1 }
				},
				Rewards = {
					{ type = "Gold", amount = 100 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
			{
				StageId = 5,
				Name = "Ruined Alley",
				WaveConfig = {
					{ type = "Basic", count = 3, delay = 0.5 },
					{ type = "Fast", count = 4, delay = 0.3 },
				},
				Rewards = {
					{ type = "Gold", amount = 150 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 2 },
				}
			},
			{
				StageId = 6,
				Name = "Underground Nest",
				WaveConfig = {
					{ type = "Basic", count = 3, delay = 0.5 },
					{ type = "Fast", count = 4, delay = 0.3 },
				},
				Rewards = {
					{ type = "Gold", amount = 200 },
					{ type = "Scroll", id = "SummonScroll_Common", amount = 1 },
				}
			},
		},
	},

	-- 💡 Weitere Welten können hier folgen:
	-- ["Raid"] = { ... },
	-- ["Trial"] = { ... },
}

return MapData
]]