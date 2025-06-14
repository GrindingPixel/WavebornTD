-- UnitAbilitiesModule.lua
-- ReplicatedStorage.Modules.UnitAbilitiesModule

--// Modul
local UnitAbilities = {}

--// Datenstruktur: Beispiel-Unit mit passiven und aktiven Fähigkeiten
UnitAbilities["Issoi_Highschool"] = {
	Passive = {
		{
			name = "Bleed Boost",
			description = "Increases bleed damage dealt by 15%"
		},
		{
			name = "Night Walker",
			description = "Moves faster at night stages"
		}
	},

	Active = {
		{
			name = "Shadow Strike",
			description = "Deals AoE damage and applies blind for 3s",
			cooldown = 12
		}
	}
}

-- Weitere Units können hier ergänzt werden
-- UnitAbilities["Neue_Unit"] = { Passive = {...}, Active = {...} }

--// Rückgabe
return UnitAbilities
