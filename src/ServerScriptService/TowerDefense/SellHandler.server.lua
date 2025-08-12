--!strict

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService:WaitForChild("Modules")

--// Modules
local ProfileService = require(Modules.ProfileService)
local UnitsDataModule = require(ReplicatedStorage.Modules.UnitDataModule)
local UpgradeConfig = require(ReplicatedStorage.TDModules.Systems.UpgradeConfig)
local UnitStatModule = require(ReplicatedStorage.Modules.UnitStatsModule)

--// Remotes
local SellTowerRequest = ReplicatedStorage.Remotes.TowerDefenseEvents:WaitForChild("SellTowerRequest")
local ProfileChanged = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")

--// Konstante
local REFUND_MULTIPLIER = 0.6

--// Logik
SellTowerRequest.OnServerEvent:Connect(function(player: Player, payload: { tuuid: string, uuid: string }?)
	if typeof(payload) ~= "table" or typeof(payload.tuuid) ~= "string" or typeof(payload.uuid) ~= "string" then
		warn(`[SellHandler] ❌ Ungültiger Payload von {player.Name} erhalten:`, payload)
		return
	end

	local tuuid = payload.tuuid
	local uuid = payload.uuid

        local profile = ProfileService:GetProfile(player)
	if not profile then
		warn(`[SellHandler] ❌ Kein Profil für Spieler {player.Name} gefunden`)
		return
	end

	local model = nil
	for _, child in ipairs(Workspace.Units:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("TUUID") == tuuid then
			model = child
			break
		end
	end

	if not model then
		warn(`[SellHandler] ❌ Kein Modell mit TUUID {tuuid} in Workspace.Units gefunden`)
		return
	end

	if model:GetAttribute("OwnerId") ~= player.UserId then
		warn(`[SellHandler] ❌ Spieler {player.Name} versucht fremden Tower zu verkaufen`)
		return
	end

	local unitId = model:GetAttribute("UnitId")
	if not unitId then
		warn(`[SellHandler] ❌ Modell enthält kein UnitId-Attribut`)
		return
	end

	local unitMeta = UnitsDataModule.GetUnitData(unitId)
	if not unitMeta then
		warn(`[SellHandler] ❌ UnitId '{unitId}' nicht im UnitsDataModule gefunden!`)
		return
	end

	local baseCost = UnitStatModule.GetStat(unitId, 0, "PlacementCost") or 0
	local upgradeLevel = model:GetAttribute("UpgradeLevel") or 0

	local totalUpgradeCost = 0
	for i = 0, upgradeLevel - 1 do
		totalUpgradeCost += math.floor(baseCost * (UpgradeConfig.CostMultiplierPerLevel ^ i))
	end

	local refund = math.floor((baseCost + totalUpgradeCost) * REFUND_MULTIPLIER)
	profile.Data.Player.TDEclipsium += refund

	ProfileChanged:FireClient(player, "TDEclipsium", profile.Data.Player.TDEclipsium)
	model:Destroy()

	print(`[SELL] {player.Name} verkauft {unitId} (Lvl {upgradeLevel}) für +{refund} TDE`)
end)
