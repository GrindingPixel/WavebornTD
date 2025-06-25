-- ShopServerHandler.server.lua

--// Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local ProfileStoreWrapper = require(game.ServerScriptService.Modules:WaitForChild("ProfileStoreWrapper"))
local PremiumShop = require(ReplicatedStorage.Modules:WaitForChild("PremiumShopModule"))

--// ProcessReceipt
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local profile = ProfileStoreWrapper:GetProfile(player)
	if not profile then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local productId = receiptInfo.ProductId
	local data = PremiumShop[productId]

	if not data then
		warn("[SHOP] Unbekannte ProductId:", productId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Initialisiere Kauf-Tracking
	profile.Data.Purchases = profile.Data.Purchases or {}
	local purchaseCount = profile.Data.Purchases[productId] or 0

	-- One-Time-Kauf blockieren
	if data.oneTime and purchaseCount > 0 then
		warn("[SHOP] One-Time-Produkt wurde erneut gekauft:", productId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Limit prüfen
	if data.maxPurchases and purchaseCount >= data.maxPurchases then
		warn("[SHOP] Kauf-Limit erreicht für ProductId:", productId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Kauf registrieren
	profile.Data.Purchases[productId] = purchaseCount + 1

	-- Belohnung vergeben
	ProfileStoreWrapper:GrantRewards(player, data.rewards)

	print("[SHOP] ✅ Kauf abgeschlossen:", productId, "→", data.productKey)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
