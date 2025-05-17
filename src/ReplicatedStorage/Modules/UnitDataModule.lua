-- UnitDataModule.lua

local Units = {}

-- Basisdaten zu jeder Unit-Art
Units.BaseUnits = {
	Issoi_HighSchool = {
		name = "Issoi",
		image = "rbxassetid://12345678",
		rarity = "Rare",
		type = "HybridGround",
		trait = "DragonKing",
		stats = {
			damage = 9000,
			range = 30,
			spa = 2.5,
			crit = 10
		}
	},
	test_dummy = {
		name = "Test Dummy",
		image = "",
		modelName = "test_dummy",
		rarity = "Common",
		type = "Ground",
		trait = "None",
		stats = {}
	}
}


return Units
