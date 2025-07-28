-- ItemDataModule.lua

local ItemData = {
	["exp"] = {
		displayName = "EXP",
		iconId = "rbxassetid://90673547927063",
		category = "Experience",
		desc = "Used to level up your player profile.",
	},
	["bpexp"] = {
		displayName = "BP EXP",
		iconId = "rbxassetid://78063301899765",
		category = "Experience",
		desc = "Used to level up your Battle Pass.",
	},
	["SummonScroll_Common"] = {
		displayName = "Common Summon Scroll",
		iconId = "rbxassetid://91235668959527",
		category = "Scroll",
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
	["Eclipsium"] = {
		displayName = "Eclipsium",
		iconId = "rbxassetid://120116668302098",
		category = "Eclipsium",
		rarity = "Common",
		desc = "Currency used for various upgrades and purchases.",
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


-- Catergory = reward.type
