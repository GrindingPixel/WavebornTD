-- ItemDataModule.lua

local ItemData = {
	["SummonScroll"] = {
		displayName = "Common Summon Scroll",
		iconId = "rbxassetid://91235668959527",
		category = "Summon",
		rarity = "Common",
		desc = "Used to summon rare to epic units.",
	},
	["Attribute_Token"] = {
		displayName = "Attribute Token",
		iconId = "rbxassetid://83291346465775",
		category = "Token",
		rarity = "Epic",
		desc = "Token used to upgrade unit attributes.",
	},
	["Reroll_Token"] = {
		displayName = "Reroll Token",
		iconId = "rbxassetid://134383472964237",
		category = "Token",
		rarity = "Divine",
		desc = "Token used to reroll unit traits.",
	},
	["Universal_Fragment"] = {
		displayName = "Univversal_Fragment",
		iconId = "rbxassetid://114136021497469",
		category = "Material",
		rarity = "Legendary",
		desc = "Material used for universal upgrades.",
	}
}

-- Hilfsfunktion zur sicheren Abfrage
function ItemData.GetMeta(id)
	return ItemData[id]
end

return ItemData
