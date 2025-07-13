--!strict
-- TowerDefense/EnemyManager.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

--// Modules
local EnemyData = require(ReplicatedStorage.Modules.EnemyDataModule)

--// Workspace
local pathFolder = Workspace:WaitForChild("EnemyPath", 10)
if not pathFolder then
	warn("❌ EnemyPath nicht gefunden nach 10 Sekunden!")
	error("EnemyPath fehlt")
end

local enemiesFolder = Workspace:FindFirstChild("Enemies") or Instance.new("Folder")
enemiesFolder.Name = "Enemies"
enemiesFolder.Parent = Workspace

--// State
local baseHP = 100

--// Modul
local EnemyManager = {}

function EnemyManager:Init()
	print("✅ EnemyManager bereit")
end

function EnemyManager:SpawnEnemy(enemyType: string)
	print("🚀 SpawnEnemy gestartet für:", enemyType)

	local data = EnemyData[enemyType]
	if not data then
		warn("❌ Gegnerdaten fehlen für:", enemyType)
		return
	end

	local template = ServerStorage:FindFirstChild(enemyType)
	if not template or not template:IsA("Model") then
		warn("❌ Gegner-Modell fehlt oder ungültig:", enemyType)
		return
	end

	print("📦 Gegner-Modell gefunden:", template.Name)

	local enemy = template:Clone()
	enemy.Parent = enemiesFolder
	enemy:SetAttribute("HP", data.HP)
	enemy:SetAttribute("Speed", data.Speed)

	task.spawn(function()
		local points = pathFolder:GetChildren()

		table.sort(points, function(a, b)
			local aNum = tonumber(a.Name)
			local bNum = tonumber(b.Name)
			return (aNum or math.huge) < (bNum or math.huge)
		end)

		for _, point in ipairs(points) do
			if not enemy.Parent then return end

			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				warn("❌ Kein Humanoid im Gegner:", enemy.Name)
				return
			end

			humanoid:MoveTo(point.Position)
			humanoid.MoveToFinished:Wait()
			task.wait(0.05)
		end

		if enemy.Parent then
			baseHP -= data.DamageToBase
			print("💥 Gegner erreicht Basis! Base HP:", baseHP)
			enemy:Destroy()
		end
	end)
end

return EnemyManager
