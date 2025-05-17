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
	},
    rukia = {
        name = "Rukia",
        image = "rbxassetid://12345678",
        modelName = "rukia",
        rarity = "Epic",
        type = "HybridAir",
        trait = "IceQueen",
        stats = {
            damage = 12000,
            range = 40,
            spa = 3.0,
            crit = 15
        }
    },
    ichigo = {
        name = "Ichigo",
        image = "rbxassetid://12345678",
        modelName = "ichigo",
        rarity = "Legendary",
        type = "HybridGround",
        trait = "SoulReaper",
        stats = {
            damage = 15000,
            range = 50,
            spa = 2.0,
            crit = 20
        }
    },
}


return Units
