-- UnitStatsModule.lua
-- ReplicatedStorage.Modules.UnitStatsModule

--!strict

--// Modul
local DebugLogger = require(game:GetService("ReplicatedStorage").Modules:WaitForChild("DebugLogger"))
local UnitStats = {}
local log = DebugLogger.new("UnitStatsModule")

--// Statdaten einzelner Units
local StatsData = {
	["Issoi_HighSchool"] = {
		MaxUpgradeLevel = 6,
		PlacementCost  = 500,
		Damage         = 15000,
		Range          = 250,
		SPA            = 4.0,
		AbilityDamage  = 50,
	}
}

function UnitStats.GetStat(unitName: string, level: number, stat: string)
        local data = StatsData[unitName]
        if not data then
                log:Warn(`⚠️ Keine Statdaten für Unit '{unitName}' gefunden`)
                return nil
        end

	return data[stat]
end

function UnitStats.GetAllStats(unitName: string)
	return StatsData[unitName]
end


--// Rückgabe
return UnitStats
