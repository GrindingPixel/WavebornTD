-- InventoryDataModule.lua

local InventoryData = {}

-- Test-Items: Scrolls, Medaillen, EXP-Food, Evo-Mats, Cosmetics
InventoryData.Items = {
	{ id = "scroll_common", name = "Common Summon Scroll", type = "Scroll", quantity = 3, image = "rbxassetid://12345678" },
	{ id = "scroll_rare", name = "Rare Summon Scroll", type = "Scroll", quantity = 1, image = "rbxassetid://87654321" },
	{ id = "medal_attr", name = "Attribute Medal", type = "Medal", quantity = 5, image = "rbxassetid://13579246" },
	{ id = "exp_food", name = "EXP Food (Small)", type = "EXP", quantity = 10, image = "rbxassetid://24681357" },
	{ id = "evo_stone", name = "Evolution Stone", type = "Evo", quantity = 2, image = "rbxassetid://11112222" },
	{ id = "cosmetic_hat", name = "Cosmetic: Hat", type = "Cosmetic", quantity = 1, image = "rbxassetid://99998888" },
}

return InventoryData
