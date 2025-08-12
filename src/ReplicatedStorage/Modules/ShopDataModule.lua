-- ShopDataModule.lua

local ShopItems = {
	GoldPack1 = {
		Name = "Gold Paket 1",
		Currency = "Gems",
		Price = 50,
		Reward = { type = "Gold", amount = 500 },
	},
	SummonScroll1 = {
		Name = "Beschwörungsrolle",
		Currency = "Gold",
		Price = 100,
		Reward = { type = "Item", id = "SummonScroll", amount = 1 },
	},
}

return ShopItems
