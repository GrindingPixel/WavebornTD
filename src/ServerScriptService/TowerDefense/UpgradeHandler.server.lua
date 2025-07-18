--!strict

--// Services
local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local Workspace             = game:GetService("Workspace")
local Players               = game:GetService("Players")
local ServerScriptService   = game:GetService("ServerScriptService")
local Modules               = ServerScriptService:WaitForChild("Modules")

--// Modules
local ProfileStoreWrapper = require(Modules.ProfileStoreWrapper)
local CombatStatsProvider = require(ReplicatedStorage.TDModules.Combat.CombatStatsProvider)
local UnitsDataModule = require(ReplicatedStorage.Modules.UnitDataModule)
local UpgradeConfig = require(ReplicatedStorage.TDModules.Systems.UpgradeConfig)
local UnitStatModule = require(ReplicatedStorage.Modules.UnitStatsModule)

--// Remotes
local UpgradeTowerRequest = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("UpgradeTowerRequest")

--// Hauptlogik
UpgradeTowerRequest.OnServerEvent:Connect(function(player: Player, payload: { tuuid: string, uuid: string }?)
	if typeof(payload) ~= "table" or typeof(payload.tuuid) ~= "string" then return end
	local tuuid = payload.tuuid
	local uuid = payload.uuid -- optional, wird nur für EXP verwendet

	local profile = ProfileStoreWrapper:GetProfile(player)
	if not profile then return end

	-- Turm-Model per TUUID suchen
	local model: Model? = nil
	for _, child in ipairs(Workspace.Units:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("TUUID") == tuuid then
			model = child
			break
		end
	end

	if not model then
		warn(`[Upgrade] ❌ Kein Modell mit TUUID {tuuid} gefunden`)
		return
	end

	if model:GetAttribute("OwnerId") ~= player.UserId then
		warn(`[Upgrade] ❌ Spieler {player.Name} versucht fremden Tower zu upgraden`)
		return
	end

	local unitId = model:GetAttribute("UnitId")
	if not unitId then
		warn(`[Upgrade] ❌ Modell hat kein UnitId-Attribut`)
		return
	end

	local currentLevel = model:GetAttribute("UpgradeLevel") or 0
	print("🔍 Server-UpgradeLevel:", currentLevel)
	local maxLevel = UnitStatModule.GetStat(unitId, 0, "MaxUpgradeLevel")

		if currentLevel >= maxLevel then
		warn(`[Upgrade] ❌ Tower bereits auf Max-Level ({currentLevel} >= {maxLevel})`)
		return
	end

	local baseData = UnitsDataModule.GetUnitData(unitId)
	local baseCost = UnitStatModule.GetStat(unitId, 0, "PlacementCost") or 0
	print("💰 BaseCost (server):", baseCost)

	local upgradeCost = math.floor(baseCost * (UpgradeConfig.CostMultiplierPerLevel ^ currentLevel))
	print("📈 UpgradeCost (server):", upgradeCost)

	if profile.Data.TDEclipsium < upgradeCost then
		warn(`[Upgrade] ❌ Nicht genug TDEclipsium für Upgrade`)
		return
	end

	-- Abziehen & Sync
	profile.Data.TDEclipsium -= upgradeCost
	ReplicatedStorage.Remotes.Profile.ProfileChanged:FireClient(player, "TDEclipsium", profile.Data.TDEclipsium)


	-- Upgrade durchführen
	local newLevel = currentLevel + 1
	model:SetAttribute("UpgradeLevel", newLevel)

	-- Neue Stats berechnen
	local stats = CombatStatsProvider.GetStats(unitId, newLevel)
	model:SetAttribute("DMG", stats.Damage)
	model:SetAttribute("RANGE", stats.Range)
	model:SetAttribute("SPA", stats.SPA)

	-- Optional: Fortschrift registrieren
	if uuid then
		ProfileStoreWrapper:IncrementUnitKills(player, uuid, 0, true) -- für eventuelle Upgrade-Tracker
	end

	print(`[Upgrade] {player.Name} upgraded {unitId} (Level {newLevel}) für {upgradeCost} TDE`)
end)
