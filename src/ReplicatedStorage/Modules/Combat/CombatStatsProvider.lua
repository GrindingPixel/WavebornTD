-- CombatStatsProvider.lua
-- Gibt die Kampfwerte einer UnitId zurück

local UnitStats = require(game:GetService("ReplicatedStorage").Modules.UnitStatsModule)

local CombatStatsProvider = {}

function CombatStatsProvider.GetStats(unitId)
	local stats = UnitStats[unitId]
	if not stats then
		warn("[CombatStatsProvider] ⚠️ Keine Stats für UnitId:", unitId)
		return {
			PlacementCost  = 0,
	        Damage         = 0,
	        Range          = 0,
	        SPA            = 0,
	        AbilityDamage  = 0,
	        TotalKills     = 0
		}
	end
	return stats
end

return CombatStatsProvider
