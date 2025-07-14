--!strict
-- TowerDefense/EnemyManager.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

--// Modules
local EnemyTypes = require(ReplicatedStorage.Modules.Enemy.EnemyTypesModule)
local EnemyUtilities = require(ReplicatedStorage.Modules.Enemy.EnemyUtilities)

--// Workspace
local pathFolder = Workspace:WaitForChild("EnemyPath", 10)
if not pathFolder then
	warn("❌ EnemyPath not found after 10 seconds!")
	error("Missing EnemyPath")
end

local enemiesFolder = Workspace:FindFirstChild("Enemies") or Instance.new("Folder")
enemiesFolder.Name = "Enemies"
enemiesFolder.Parent = Workspace

--// State
local baseHP = 100

--// Module
local EnemyManager = {}

function EnemyManager:Init()
	print("✅ EnemyManager ready")
end

function EnemyManager:SpawnEnemy(enemyId: string, wave: number)
	print("🚀 Spawning enemy:", enemyId, "[Wave", wave, "]")

	local data = EnemyTypes[enemyId]
	if not data then
		warn("❌ Enemy type not found:", enemyId)
		return
	end

	local template = ServerStorage:FindFirstChild(enemyId)
	if not template or not template:IsA("Model") then
		warn("❌ Enemy model missing or invalid:", enemyId)
		return
	end

	local enemy = template:Clone()
	enemy.Name = enemyId .. "_Wave" .. tostring(wave)
	enemy.Parent = enemiesFolder

	local maxHP = math.floor(data.MaxHealth * (1 + 0.1 * wave))
	local speed = data.BaseSpeed
	local enemyType = data.Type or "Ground"

	enemy:SetAttribute("MaxHP", maxHP)
	enemy:SetAttribute("CurrentHP", maxHP)
	enemy:SetAttribute("Speed", speed)
	enemy:SetAttribute("Type", enemyType)

	EnemyUtilities.ApplyHealthBar(enemy, maxHP)

	task.spawn(function()
		local points = pathFolder:GetChildren()
		table.sort(points, function(a, b)
			local aNum = tonumber(a.Name)
			local bNum = tonumber(b.Name)
			return (aNum or math.huge) < (bNum or math.huge)
		end)

		for i, point in ipairs(points) do
			if not enemy.Parent then return end

			local hrp = enemy:FindFirstChild("HumanoidRootPart")
			if not hrp then
				warn("❌ Missing HumanoidRootPart in enemy:", enemy.Name)
				return
			end

			local distance = (hrp.Position - point.Position).Magnitude
			enemy:SetAttribute("PathProgress", i)
			enemy:SetAttribute("DistanceToGoal", distance)

			local bodyVel = Instance.new("BodyVelocity")
			bodyVel.Velocity = (point.Position - hrp.Position).Unit * speed
			bodyVel.MaxForce = Vector3.new(1e5, 0, 1e5)
			bodyVel.Parent = hrp
			while (hrp.Position - point.Position).Magnitude > 1 do
				task.wait(0.05)
			end
			bodyVel:Destroy()
		end

		if enemy.Parent then
			baseHP -= 10
			print("💥 Enemy reached base! Base HP:", baseHP)
			enemy:Destroy()
		end
	end)
end

return EnemyManager
