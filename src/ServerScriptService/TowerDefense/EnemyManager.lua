--!strict
-- TowerDefense/EnemyManager.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

--// Modules
local EnemyTypes = require(ReplicatedStorage.TDModules.Enemy.EnemyTypesModule)
local EnemyUtilities = require(ReplicatedStorage.TDModules.Enemy.EnemyUtilities)
local MatchStateModule = require(ServerScriptService.TowerDefense.MatchStateModule)

--// Path Setup
local pathFolder = Workspace:WaitForChild("EnemyPath")
local startPoint = pathFolder:WaitForChild("Start")
local endPoint = pathFolder:WaitForChild("Ende")

--// Enemies Folder
local enemiesFolder = Workspace:FindFirstChild("Enemies") or Instance.new("Folder")
enemiesFolder.Name = "Enemies"
enemiesFolder.Parent = Workspace

--// Base HP
local baseHP = 100
local matchLost = false

--// CollisionGroup Setter
local function setCollisionGroup(model: Model, groupName: string)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = groupName
		end
	end
end

--// Module
local EnemyManager = {}

function EnemyManager:Init()
	print("✅ EnemyManager ready")

	-- Base Hit Detection
	if not endPoint:IsA("BasePart") then
		error("❌ EndPoint must be a BasePart!")
	end

	endPoint.Touched:Connect(function(hit)
		local enemy = hit:FindFirstAncestorWhichIsA("Model")
		if enemy and enemy:IsDescendantOf(enemiesFolder) and not enemy:GetAttribute("ReachedEnd") then
			enemy:SetAttribute("ReachedEnd", true)
			baseHP -= 50
			print("💥", enemy.Name, "reached base. Base HP now:", baseHP)
			enemy:Destroy()

			if baseHP <= 0 and not matchLost then
				matchLost = true
				print("💀 Base destroyed – triggering match loss")
				MatchStateModule.EndMatch("Defeat")
			end
		end
	end)
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
		warn("❌ Enemy model not found:", enemyId)
		return
	end

	local enemy = template:Clone()
	enemy.Name = enemyId .. "_Wave" .. tostring(wave)
	enemy.Parent = enemiesFolder
	setCollisionGroup(enemy, "Enemy")

	local maxHP = math.floor(data.MaxHealth * (1 + 0.1 * wave))
	local speed = data.BaseSpeed
	local enemyType = data.Type or "Ground"

	enemy:SetAttribute("MaxHP", maxHP)
	enemy:SetAttribute("CurrentHP", maxHP)
	enemy:SetAttribute("Speed", speed)
	enemy:SetAttribute("Type", enemyType)

	EnemyUtilities.ApplyHealthBar(enemy, maxHP)

	local hrp = enemy:FindFirstChild("HumanoidRootPart")
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		warn("❌ Enemy missing HRP or Humanoid:", enemy.Name)
		enemy:Destroy()
		return
	end

	enemy:MoveTo(startPoint.Position)

	task.spawn(function()
		local pathPoints = {}
		for _, obj in ipairs(pathFolder:GetChildren()) do
			if tonumber(obj.Name) then
				table.insert(pathPoints, obj)
			end
		end
		table.sort(pathPoints, function(a, b)
			return tonumber(a.Name) < tonumber(b.Name)
		end)
		table.insert(pathPoints, endPoint)

		for i, point in ipairs(pathPoints) do
			if not enemy:IsDescendantOf(workspace) then return end

			local dist = (hrp.Position - point.Position).Magnitude
			enemy:SetAttribute("PathProgress", i)
			enemy:SetAttribute("DistanceToGoal", dist)

			humanoid:MoveTo(point.Position)
			local success = humanoid.MoveToFinished:Wait(5)
			if not success then break end
		end

		if enemy:IsDescendantOf(workspace) and not enemy:GetAttribute("ReachedEnd") then
			warn("⚠️ Enemy did not reach End, but path completed:", enemy.Name)
			enemy:Destroy()
		end
	end)
end

--// Rückgabe der verbleibenden Gegner
function EnemyManager:GetAliveEnemyCount(): number
	local count = 0
	for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		if enemy:IsA("Model") and not enemy:GetAttribute("ReachedEnd") then
			count += 1
		end
	end
	return count
end

return EnemyManager
