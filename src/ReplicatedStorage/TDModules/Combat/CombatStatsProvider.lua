-- CombatStatsProvider.lua
-- Gibt die Kampfwerte einer UnitId zurück, dynamisch je nach Upgrade-Level

--!strict

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local UnitStats = require(ReplicatedStorage.UnitStatsModule)
local UpgradeConfig = require(ReplicatedStorage.TDModules.Systems.UpgradeConfig)

--// Typdefinition
type CombatStats = {
	PlacementCost: number,
	Damage: number,
	Range: number,
	SPA: number,
	AbilityDamage: number,
	TotalKills: number
}

local CombatStatsProvider = {}

function CombatStatsProvider.GetStats(unitId: string, upgradeLevel: number?): CombatStats
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

	-- Absicherung gegen fehlende Werte
	local baseDamage = typeof(stats.Damage) == "number" and stats.Damage or 0
	local baseRange = typeof(stats.Range) == "number" and stats.Range or 0
	local baseSPA = typeof(stats.SPA) == "number" and stats.SPA or 0
	local basePlacementCost = typeof(stats.PlacementCost) == "number" and stats.PlacementCost or 0
	local abilityDamage = typeof(stats.AbilityDamage) == "number" and stats.AbilityDamage or 0
	local totalKills = typeof(stats.TotalKills) == "number" and stats.TotalKills or 0

	local rawMaxLevel = UnitStats.GetStat(unitId, 0, "MaxUpgradeLevel")
	local maxUpgradeLevel = typeof(rawMaxLevel) == "number" and rawMaxLevel or 0
	local level = math.clamp(upgradeLevel or 0, 0, maxUpgradeLevel)

	local scaledDamage = baseDamage * (1 + UpgradeConfig.DamageMultiplierPerLevel * level)
	local scaledRange = baseRange * (1 + UpgradeConfig.RangeMultiplierPerLevel * level)
	local scaledSPA = baseSPA * (1 + UpgradeConfig.SPAMultiplierPerLevel * level)

	local result: CombatStats = {
		PlacementCost  = basePlacementCost,
		Damage         = math.floor(scaledDamage),
		Range          = math.floor(scaledRange * 10) / 10,
		SPA            = math.max(UpgradeConfig.MinSPA, math.floor(scaledSPA * 10) / 10),
		AbilityDamage  = abilityDamage,
		TotalKills     = totalKills
	}

	return result
end

return CombatStatsProvider
