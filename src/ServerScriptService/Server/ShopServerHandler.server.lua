-- ShopServerHandler.server.lua

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

--// Modules
local ServerDebounce = require(ReplicatedStorage.Modules.ServerDebounce)
local RewardService   = require(script.Parent:WaitForChild("RewardService"))

--// Remotes
local shopFolder = ReplicatedStorage.Remotes:FindFirstChild("Shop") or Instance.new("Folder")
shopFolder.Name = "Shop"
shopFolder.Parent = ReplicatedStorage

local purchaseEvent = Instance.new("RemoteEvent")
purchaseEvent.Name = "ShopPurchaseRequest"
purchaseEvent.Parent = shopFolder

--// Debug
local DEBUG = true
local function log(...) if DEBUG then print("[🛒 ShopServerHandler]", ...) end end
local function warnf(...) if DEBUG then warn("[❌ ShopServerHandler]", ...) end end

--// Test-Shopdaten
local ShopItems = {
	["ScrollPack1"] = {
		cost = 0, -- 0 = nicht monetär
		rewards = {
			{ type = "Item", id = "Scroll_Basic", amount = 3 },
		},
	},

	["GoldPack1"] = {
		cost = 100, -- DevProductId (hier als Beispiel)
		rewards = {
			{ type = "Gold", amount = 250 },
		},
	},

	["StarterPack"] = {
		cost = 200, -- DevProductId
		rewards = {
			{ type = "Gold", amount = 500 },
			{ type = "Item", id = "Scroll_Boss", amount = 2 },
		},
	}
}

--// DevProduct-Verarbeitung
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	for itemKey, data in pairs(ShopItems) do
		if data.cost == receiptInfo.ProductId then
			log("💳 DevProduct erkannt:", itemKey, "→ Belohnung")
			RewardService:Give(player, data.rewards)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	warnf("❌ Unbekannter ProductId:", receiptInfo.ProductId)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

--// Shop-Kauf-Event
purchaseEvent.OnServerEvent:Connect(function(player, itemKey)
	if ServerDebounce:Block(player, "Shop_" .. itemKey, 2) then return end

	local item = ShopItems[itemKey]
	if not item then
		warnf("Ungültiger ShopKey:", itemKey)
		return
	end

	if item.cost > 0 then
		log("💰 Monetärer Kauf → Starte Kauf für:", itemKey)
		MarketplaceService:PromptProductPurchase(player, item.cost)
	else
		log("🎁 Kostenloser Shopkauf:", itemKey)
		RewardService:Give(player, item.rewards)
	end
end)
