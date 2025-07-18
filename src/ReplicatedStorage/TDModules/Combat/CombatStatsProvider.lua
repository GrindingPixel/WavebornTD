-- CombatStatsProvider.lua
-- Gibt die Kampfwerte einer UnitId zurück, dynamisch je nach Upgrade-Level

--!strict

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local UnitStats = require(ReplicatedStorage.Modules.UnitStatsModule)
local UpgradeConfig = require(ReplicatedStorage.TDModules.Systems.UpgradeConfig)

local CombatStatsProvider = {}

function CombatStatsProvider.GetStats(unitId: string, upgradeLevel: number?): {
	PlacementCost: number,
	Damage: number,
	Range: number,
	SPA: number,
	AbilityDamage: number,
	TotalKills: number
}
	local stats = UnitStats.GetAllStats(unitId)
	if not stats then
		warn("[CombatStatsProvider] ⚠️ Keine Stats für UnitId:", unitId)
		return {
			PlacementCost  	= 0,
			Damage         	= 0,
			Range          	= 0,
			SPA            	= 0,
			AbilityDamage  	= 0,
			TotalKills     	= 0
		}
	end

	local level = math.clamp(upgradeLevel or 0, 0, UnitStats.GetStat(unitId, 0, "MaxUpgradeLevel"))


	local scaledDamage = stats.Damage * (1 + UpgradeConfig.DamageMultiplierPerLevel * level)
	local scaledRange = stats.Range * (1 + UpgradeConfig.RangeMultiplierPerLevel * level)
	local scaledSPA = stats.SPA * (1 + UpgradeConfig.SPAMultiplierPerLevel * level)

	return {
		PlacementCost  = stats.PlacementCost,
		Damage         = math.floor(scaledDamage),
		Range          = math.floor(scaledRange * 10) / 10,
		SPA            = math.max(UpgradeConfig.MinSPA, math.floor(scaledSPA * 10) / 10),
		AbilityDamage  = stats.AbilityDamage or 0,
		TotalKills     = stats.TotalKills or 0
	}
end

return CombatStatsProvider
