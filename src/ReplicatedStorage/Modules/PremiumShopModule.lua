-- PremiumShopModule.lua

local PremiumShop = {
	
    [3316115753] = {
		productKey = "ScrollPack5",
		rewards = {
			{ type = "Scroll", id = "SummonScroll_Common", amount = 5 }
		},
		oneTime = false,
		maxPurchases = nil,
		name = "5x Beschwörungsrollen",
		description = "Gibt dir 5 Scrolls für die Einheit-Beschwörung.",
		icon = "rbxassetid://123456789"
	},

    [3281499155] = {
		productKey = "ScrollPack5",
		rewards = {
			{ type = "Scroll", id = "SummonScroll_Common", amount = 5 }
		},
		oneTime = false,
		maxPurchases = 3,
		name = "5x Beschwörungsrollen",
		description = "Gibt dir 5 Scrolls für die Einheit-Beschwörung.",
		icon = "rbxassetid://123456789"
	}

	-- Weitere Produkte können hier hinzugefügt werden
}

return PremiumShop