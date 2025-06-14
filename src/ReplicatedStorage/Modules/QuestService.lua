-- QuestService.lua
-- ReplicatedStorage.Modules.QuestService

--// Modul
local QuestService = {}

--// Testquests
QuestService.Quests = {

	Daily = {
		{
			id = 1,
			title = "Summon 3 Units",
			description = "Use summon 3x",
			goal = 3,
			progress = 3,
			rewards = {
				{ image = "rbxassetid://1234567890" },
				{ image = "rbxassetid://987654321" }
			}
		},
		{
			id = 2,
			title = "Win 1 Raid",
			description = "Complete any raid once",
			goal = 1,
			progress = 0,
			rewards = {
				{ image = "rbxassetid://456789123" }
			}
		},
	},

	Weekly = {
		{
			id = 101,
			title = "Reach Level 20",
			description = "Get account level 20",
			goal = 20,
			progress = 17,
			rewards = {
				{ image = "rbxassetid://44556677" }
			}
		}
	},

	-- Weitere Kategorien folgen analog (Story, Special, Trials, Progress)

}

--// Rückgabe
return QuestService
