-- DamageSystem.lua
-- ServerScriptService.TowerDefense.Combat.DamageSystem

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local CombatStatsProvider = require(ReplicatedStorage.TDModules.Combat.CombatStatsProvider)
local UnitTargetingModule = require(ReplicatedStorage.TDModules.Combat.UnitTargetingModule)

--// remotes
local ProfileChanged = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")

--// Constants
local UnitsFolder = Workspace:WaitForChild("Units")
local EnemiesFolder = Workspace:WaitForChild("Enemies")

--// Debug
local DEBUG = true
local function log(...)
	if DEBUG then print(...) end
end

--// Module
local DamageSystem = {}

--// Aktive Schleifen-Map (jetzt nach TUUID getrennt)
local activeAttackLoops: { [string]: boolean } = {}

--// Gegner in Reichweite (HRP only)
local function getEnemiesInRange(position: Vector3, range: number)
	local result = {}

	for _, enemy in ipairs(EnemiesFolder:GetChildren()) do
		local hrp = enemy:FindFirstChild("HumanoidRootPart")
		local health = enemy:FindFirstChild("Health")

		if enemy:IsA("Model") and hrp and health then
			local dist = (hrp.Position - position).Magnitude
			if dist <= range then
				table.insert(result, enemy)
			end
		end
	end

	return result
end

--// Angriffsschleife starten
local function beginAttackLoop(towerModel: Model, unitId: string, player: Player)
	local uuid = towerModel:GetAttribute("UUID")
	local tuuid = towerModel:GetAttribute("TUUID")

	if not uuid then warn("[DamageSystem] ❌ Kein UUID auf Tower-Modell!") return end
	if not tuuid then warn("[DamageSystem] ❌ Kein TUUID auf Tower-Modell!") return end

	if activeAttackLoops[tuuid] then return end
	activeAttackLoops[tuuid] = true

	task.spawn(function()
		while towerModel and towerModel.Parent == UnitsFolder do
			local hrp = towerModel:FindFirstChild("HumanoidRootPart")
			if not hrp then break end

			local stats = CombatStatsProvider.GetStats(unitId, towerModel:GetAttribute("UpgradeLevel") or 0)
			local range, spa, damage = stats.Range, stats.SPA, stats.Damage

			local targets = getEnemiesInRange(hrp.Position, range)
			local targetingMode = towerModel:GetAttribute("TargetingMode") or "Nearest"
			local target = UnitTargetingModule.GetTarget(targets, targetingMode)

			if target and target:FindFirstChild("Health") then
				local health = target.Health
				log(`💥 {unitId} ({tuuid}) greift {target.Name} an → HP vor: {health.Value}`)
				health.Value = math.max(health.Value - damage, 0)

				if health.Value <= 0 then
					log(`☠️ {target.Name} wurde getötet von {tuuid}`)
					target:Destroy()
					ProfileWrapper:AddTDEclipsium(player, 20)
					ProfileWrapper:AddBattlepassEXP(player, 5)
					ProfileWrapper:IncrementUnitKills(player, uuid, 1, true) -- Profil-relevant
					-- LiveSync an Client senden
					ProfileWrapper:Sync(player, "TDEclipsium")
				end
			end

			task.wait(spa)
		end

		-- Entfernen aus aktiven Loops
		activeAttackLoops[tuuid] = nil
	end)
end

--// Tower registrieren
function DamageSystem.RegisterTower(towerModel: Model, unitId: string, player: Player)
	if not towerModel:IsDescendantOf(UnitsFolder) then
		warn("[DamageSystem] ❌ Tower nicht im UnitsFolder!")
		return
	end

	beginAttackLoop(towerModel, unitId, player)
end

return DamageSystem
