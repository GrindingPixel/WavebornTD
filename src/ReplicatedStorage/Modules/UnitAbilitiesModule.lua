-- UnitAbilitiesModule.lua

local UnitAbilities = {}

UnitAbilities["Issoi_Highschool"] = {
	Passive = {
		{
			name = "Bleed Boost",
			description = "Increases bleed damage dealt by 15%."
		},
		{
			name = "Night Walker",
			description = "Moves faster at night stages."
		}
	},
	Active = {
		{
			name = "Shadow Strike",
			cooldown = 12,
			description = "Deals AoE damage and applies blind for 3s."
		}
	}
}

-- weitere Units kannst du wie oben hinzufügen

return UnitAbilities
