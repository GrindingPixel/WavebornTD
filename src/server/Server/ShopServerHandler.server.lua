-- ShopServerHandler.server.lua

--// Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugLogger = require(ReplicatedStorage:WaitForChild("DebugLogger"))
local log = DebugLogger.new("ShopServerHandler")

--// Modules
local ProfileWrapper = require(game.ServerScriptService.Modules:WaitForChild("ProfileStoreWrapper"))
local PremiumShop = require(ReplicatedStorage:WaitForChild("PremiumShopModule"))
local ProfileSyncService = require(game.ServerScriptService.Modules:WaitForChild("ProfileSyncService"))

--// Remotes
local GetPurchases = ReplicatedStorage.Remotes.Profile:WaitForChild("GetPurchases")


-- Prüfe, ob der Spieler bereits gekauft hat
	GetPurchases.OnServerInvoke = function(player)
	local profile = ProfileWrapper:GetProfile(player)
	if profile then
		return profile.Data.Purchases
	else
		return {}
	end
end


--// ProcessReceipt
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local profile = ProfileWrapper:GetProfile(player)
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

	-- Premium-Status aktivieren, wenn BattlepassPremium gekauft wurde
	if data.productKey == "BattlepassPremium" then
                ProfileWrapper:SetBattlepassPremium(player, true)
                ProfileSyncService:Send(player, "Battlepass", ProfileWrapper:GetBattlepass(player))
                log("🎫 Premium-Status sofort aktiviert für", player.Name)
	end

	-- Belohnung vergeben (falls vorhanden)
	ProfileWrapper:GrantRewards(player, data.rewards)

        log("✅ Kauf abgeschlossen:", productId, "→", data.productKey)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
