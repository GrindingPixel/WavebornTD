-- EnemyUtilities.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyUtilities = {}

function EnemyUtilities.ApplyHealthBar(enemyModel: Model, maxHP: number)
	local billboard = ReplicatedStorage.Assets:WaitForChild("HealthBar"):Clone()
	billboard.Parent = enemyModel:FindFirstChild("HumanoidRootPart")
	billboard.MaxHP.Value = maxHP
	billboard.CurrentHP.Value = maxHP
end

return EnemyUtilities
