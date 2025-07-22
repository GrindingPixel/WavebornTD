-- EnemyTypesModule.lua

local EnemyTypes = {}

EnemyTypes["Basic"] = {
	MaxHealth = 100,
	BaseSpeed = 8,
	Type = "Ground"
}

EnemyTypes["Fast"] = {
	MaxHealth = 80,
	BaseSpeed = 14,
	Type = "Ground"
}

EnemyTypes["BossEnemy"] = {
	MaxHealth = 1000,
	BaseSpeed = 6,
	Type = "Ground"
}

EnemyTypes["FlyerEnemy"] = {
	MaxHealth = 90,
	BaseSpeed = 10,
	Type = "Air"
}

return EnemyTypes
