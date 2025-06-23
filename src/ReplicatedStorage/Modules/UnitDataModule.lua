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
		BaseStar   = 3,
		MaxStar    = 12,
		stats      = {
			damage = 9000,
			range  = 30,
			spa    = 2.5,
			crit   = 10
		}
	},

	test_dummy = {
		name       = "Test Dummy",
		image      = "",
		modelName  = "test_dummy",
		type       = "Ground",
		trait      = "None",
		BaseStar   = 1,
		MaxStar    = 12,
		stats      = {}
	},

	rukia = {
		name       = "Rukia",
		image      = "rbxassetid://12345678",
		modelName  = "rukia",
		type       = "HybridAir",
		trait      = "IceQueen",
		BaseStar   = 4,
		MaxStar    = 12,
		stats      = {
			damage = 12000,
			range  = 40,
			spa    = 3.0,
			crit   = 15
		}
	},

	ichigo = {
		name       = "Ichigo",
		image      = "rbxassetid://12345678",
		modelName  = "ichigo",
		type       = "HybridGround",
		trait      = "SoulReaper",
		BaseStar   = 5,
		MaxStar    = 12,
		stats      = {
			damage = 15000,
			range  = 50,
			spa    = 2.0,
			crit   = 20
		}
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
