--!strict
-- TowerDefense/EnemyManager.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

--// Modules
local EnemyTypes = require(ReplicatedStorage.TDModules.Enemy.EnemyTypesModule)
local EnemyUtilities = require(ReplicatedStorage.TDModules.Enemy.EnemyUtilities)

--// Enemies Folder
local enemiesFolder = Workspace:FindFirstChild("Enemies") or Instance.new("Folder")
enemiesFolder.Name = "Enemies"
enemiesFolder.Parent = Workspace

--// Path Root
local pathRoot = Workspace:WaitForChild("EnemyPath")
local globalEnd = pathRoot:FindFirstChild("Ende")

--// Base HP
local baseHP = 100
local matchLost = false

--// Callback
local onBaseDestroyed: (() -> ())? = nil

--// CollisionGroup Setter
local function setCollisionGroup(model: Model, groupName: string)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = groupName
		end
	end
end

--// Pfad-Aufbereitung
local function getAvailablePaths(): { Folder }
	local paths = {}

	local hasSubPaths = false
	for _, child in ipairs(pathRoot:GetChildren()) do
		if child:IsA("Folder") and child.Name:match("^EnemyPath%d+") then
			table.insert(paths, child)
			hasSubPaths = true
		end
	end

	if not hasSubPaths then
		table.insert(paths, pathRoot)
	end

	return paths
end

local function getPathData(pathFolder: Folder)
	local start = pathFolder:FindFirstChild("Start")
	local localEnd = pathFolder:FindFirstChild("Ende") or globalEnd

	if not start or not start:IsA("BasePart") then
		error("❌ Path start point missing or invalid in: " .. pathFolder:GetFullName())
	end

	if not localEnd or not localEnd:IsA("BasePart") then
		error("❌ End point missing or invalid for path: " .. pathFolder:GetFullName())
	end

	local pathPoints = {}
	for _, obj in ipairs(pathFolder:GetChildren()) do
		if tonumber(obj.Name) then
			table.insert(pathPoints, obj)
		end
	end
	table.sort(pathPoints, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)

	table.insert(pathPoints, localEnd)
	return start, pathPoints, localEnd
end

--// Modul
local EnemyManager = {}

function EnemyManager:SetOnBaseDestroyed(callback: () -> ())
	onBaseDestroyed = callback
end

function EnemyManager:Init()
	print("✅ EnemyManager ready")

	if not globalEnd or not globalEnd:IsA("BasePart") then
		error("❌ Global EndPoint (EnemyPath.Ende) missing or invalid!")
	end

	globalEnd.Touched:Connect(function(hit)
		local enemy = hit:FindFirstAncestorWhichIsA("Model")
		if enemy and enemy:IsDescendantOf(enemiesFolder) and not enemy:GetAttribute("ReachedEnd") then
			enemy:SetAttribute("ReachedEnd", true)
			baseHP -= 10
			print("💥", enemy.Name, "reached base. Base HP now:", baseHP)
			enemy:Destroy()

			if baseHP <= 0 and not matchLost then
				matchLost = true
				print("💀 Base destroyed – triggering match loss")
				if onBaseDestroyed then
					onBaseDestroyed()
				end
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

	local paths = getAvailablePaths()
	if #paths == 0 then
		warn("❌ No valid enemy paths found.")
		return
	end

	local selectedPath = paths[math.random(1, #paths)]
	local startPoint, pathPoints, endPoint = getPathData(selectedPath)

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
	for i, point in ipairs(pathPoints) do
		if not enemy:IsDescendantOf(workspace) then return end

		if point:IsA("BasePart") then
			local dist = (hrp.Position - point.Position).Magnitude
			enemy:SetAttribute("PathProgress", i)
			enemy:SetAttribute("DistanceToGoal", dist)

			humanoid:MoveTo(point.Position)
			local success = humanoid.MoveToFinished:Wait(5)
			if not success then break end
		else
			warn("⚠️ Ignoring non-BasePart path point:", point:GetFullName())
		end
	end

	if enemy:IsDescendantOf(workspace) and not enemy:GetAttribute("ReachedEnd") then
		warn("⚠️ Enemy did not reach End, but path completed:", enemy.Name)
		enemy:SetAttribute("ReachedEnd", true)
		enemy:Destroy()
	end
end)


	return enemy
end

function EnemyManager.ClearEnemies()
	for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		if enemy:IsA("Model") then
			enemy:Destroy()
		end
	end
end

function EnemyManager:Reset()
	matchLost = false
	baseHP = 100
end

return EnemyManager
