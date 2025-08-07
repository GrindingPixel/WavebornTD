-- UnitDataModule.lua
-- ReplicatedStorage.Modules.UnitDataModule

--// Daten
local Units = {}

--// Basisdaten aller Unit-Arten
Units.BaseUnits = {
	Issoi_HighSchool = {
		name       = "Issoi",
		image      = "rbxassetid://12345678",
		modelName  = "Issoi_HighSchool",
		type       = "HybridGround",
		trait      = "DragonKing",
		BaseStar   = 5,
		MaxStar    = 12
	},

	test_dummy = {
		name       = "Test Dummy",
		image      = "",
		modelName  = "test_dummy",
		type       = "Ground",
		trait      = "None",
		BaseStar   = 4,
		MaxStar    = 12
	},

	rukia = {
		name       = "Rukia",
		image      = "rbxassetid://12345678",
		modelName  = "rukia",
		type       = "HybridAir",
		trait      = "IceQueen",
		BaseStar   = 1,
		MaxStar    = 12
	},

	ichigo = {
		name       = "Ichigo",
		image      = "rbxassetid://12345678",
		modelName  = "ichigo",
		type       = "HybridGround",
		trait      = "SoulReaper",
		BaseStar   = 1,
		MaxStar    = 12
	},
}

--// API
local UnitDataModule = {}

function UnitDataModule.GetUnitData(unitId)
	return Units.BaseUnits[unitId]
end

function UnitDataModule.GetAllUnitIds()
	local ids = {}
	for id in pairs(Units.BaseUnits) do
		table.insert(ids, id)
	end
	return ids
end

--// Rückgabe
return UnitDataModule
