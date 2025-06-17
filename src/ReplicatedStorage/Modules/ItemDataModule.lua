-- ItemDataModule.lua

local ItemData = {
	["Scroll_Alpha"] = {
		displayName = "Alpha Scroll",
		iconId = "rbxassetid://1234567890",
		category = "Summon",
		rarity = "Rare",
		desc = "Used to summon rare units.",
	},
	["Evo_StarPiece"] = {
		displayName = "Star Piece",
		iconId = "rbxassetid://9876543210",
		category = "Evo",
		rarity = "Epic",
		desc = "Evolution material for powerful units.",
	},
	["Skin_PinkDragon"] = {
		displayName = "Pink Dragon Skin",
		iconId = "rbxassetid://555666777",
		category = "Cosmetic",
		rarity = "Legendary",
		desc = "A cosmetic skin for your unit.",
	},
	["EXP_MeatSmall"] = {
		displayName = "Small EXP Meat",
		iconId = "rbxassetid://1122334455",
		category = "EXP",
		rarity = "Common",
		desc = "Grants 500 EXP to a unit.",
	},
	["Medal_Ruby"] = {
		displayName = "Ruby Medal",
		iconId = "rbxassetid://9988776655",
		category = "Medal",
		rarity = "Uncommon",
		desc = "Awarded for completing daily missions.",
	},
}

-- Hilfsfunktion zur sicheren Abfrage
function ItemData.GetMeta(id)
	return ItemData[id]
end

return ItemData
