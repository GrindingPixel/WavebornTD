-- UnitStatsModule.lua
-- ReplicatedStorage.Modules.UnitStatsModule

--// Modul
local UnitStats = {}

--// Statdaten einzelner Units
UnitStats["Issoi_HighSchool"] = {
	PlacementCost  = 500,
	Damage         = 130,
	Range          = 25,
	SPA            = 4.0,
	AbilityDamage  = 220,
	TotalKills     = 184
}

-- Weitere Units können so ergänzt werden:
-- UnitStats["MyCoolUnit"] = {
--     PlacementCost  = ...,
--     Damage         = ...,
--     Range          = ...,
--     SPA            = ...,
--     AbilityDamage  = ...,
--     TotalKills     = ...
-- }

--// Rückgabe
return UnitStats
