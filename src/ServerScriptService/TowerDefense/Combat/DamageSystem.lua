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

--// Constants
local UnitsFolder = Workspace:WaitForChild("Units")
local EnemiesFolder = Workspace:WaitForChild("Enemies")

--// Module
local DamageSystem = {}

--// Get all enemies in range
local function getEnemiesInRange(position: Vector3, range: number)
	local result = {}

	print("📡 Checking enemies in range from:", position, "Range:", range)

	for _, enemy in ipairs(EnemiesFolder:GetChildren()) do
		if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Health") then
			local hrp = enemy.HumanoidRootPart
			local dist = (hrp.Position - position).Magnitude

			print(enemy.Name, "→ Distanz:", dist)

			if dist <= range then
				print("✅", enemy.Name, "ist IN Reichweite!")
				table.insert(result, enemy)
			else
				print("❌", enemy.Name, "ist ZU WEIT WEG.")
			end
		else
			print("⚠️", enemy.Name, "ist ungültig (kein HRP oder Health?)")
		end
	end

	print("🎯 Gefundene Ziele:", #result)
	return result
end


--// Begin attack loop for tower
local function beginAttackLoop(towerModel: Model, unitId: string, player: Player)
	local stats = CombatStatsProvider.GetStats(unitId)
	local range = stats.Range
	local spa = stats.SPA
	local damage = stats.Damage

	local uuid = towerModel:GetAttribute("UUID")
	if not uuid then warn("[DamageSystem] ❌ No UUID on tower model!") return end

	task.spawn(function()
		while towerModel and towerModel.Parent == UnitsFolder do
			local hrp = towerModel:FindFirstChild("HumanoidRootPart")
			if not hrp then break end

			-- 🟢 Visualisiere Reichweite für Debug
			local circle = Instance.new("Part")
			circle.Anchored = true
			circle.CanCollide = false
			circle.Transparency = 0.8
			circle.Material = Enum.Material.ForceField
			circle.Shape = Enum.PartType.Ball
			circle.Size = Vector3.new(range * 2, 0.2, range * 2)
			circle.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 0.1, 0))
			circle.Color = Color3.fromRGB(0, 255, 0)
			circle.Parent = workspace
			game:GetService("Debris"):AddItem(circle, 1.5)

			-- 🎯 Zielsuche
			local targets = getEnemiesInRange(hrp.Position, range)
			print("🔍", unitId, "findet", #targets, "Ziele")

			local targetingMode = towerModel:GetAttribute("TargetingMode") or "Nearest"
			local target = UnitTargetingModule.GetTarget(targets, targetingMode)

			if target and target:FindFirstChild("Health") then
				print("💥", unitId, "greift", target.Name, "an! HP vor:", target.Health.Value)
				target.Health.Value = math.max(target.Health.Value - damage, 0)

				if target.Health.Value <= 0 then
					print("☠️", target.Name, "wurde getötet!")
					target:Destroy()
					ProfileWrapper:AddTDEclipsium(player, 20)
					ProfileWrapper:AddBattlepassEXP(player, 5)
					ProfileWrapper:IncrementUnitKills(player, uuid, 1, true)
				end
			else
				print("❌ Kein gültiges Ziel in Reichweite für", unitId)
			end

			task.wait(spa)
		end
	end)
end


--// Register tower for damage system
function DamageSystem.RegisterTower(towerModel: Model, unitId: string, player: Player)
	if not towerModel:IsDescendantOf(UnitsFolder) then
		warn("[DamageSystem] Tower is not in UnitsFolder!")
		return
	end
	beginAttackLoop(towerModel, unitId, player)
end

--// Return module
return DamageSystem
