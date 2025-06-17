--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")


--// Modules
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")
local RewardService = require(Modules:WaitForChild("RewardService"))


--// Debug
local DEBUG = true
local function log(...) if DEBUG then print("[🛒 ShopServer]", ...) end end
local function warnf(...) if DEBUG then warn("[🛒 ShopServer]", ...) end end

--// DevProduct-Belohnungen (aus ItemData)
local DevProductRewards = {
	[12345678] = {
		{ id = "Scroll_Alpha", amount = 1 },
	},
	[23456789] = {
		{ id = "Evo_StarPiece", amount = 2 },
	},
}

--// Verarbeitung
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		warnf("Spieler nicht gefunden bei Kauf:", receiptInfo.PlayerId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId
	local rewards = DevProductRewards[productId]

	if not rewards then
		warnf("Unbekanntes Produkt:", productId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local success = RewardService.GrantRewards(player, rewards)
	if not success then
		warnf("Reward fehlgeschlagen für", player.Name, "→ Produkt:", productId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	log("Kauf verarbeitet:", productId, "→", player.Name)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
