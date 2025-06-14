-- ShopServerHandler.server.lua

--// Services
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local MarketplaceService  = game:GetService("MarketplaceService")
local DataStoreService    = game:GetService("DataStoreService")

--// Modules
local ServerDebounce = require(ReplicatedStorage.Modules.ServerDebounce)

--// Remotes
local shopEvent              = ReplicatedStorage:WaitForChild("ShopPurchaseRequest")
local purchaseCompletedEvent = ReplicatedStorage:WaitForChild("ShopPurchaseCompleted")

--// DataStore
local purchasesDataStore = DataStoreService:GetDataStore("PlayerPurchases")

--// State
local activePurchases = {}

--// Init
local shopHandler = {}
shopHandler.version = "1.0.3"
warn("📦 ShopServerHandler geladen (v" .. shopHandler.version .. ")")

--// Events

-- Cleanup bei Disconnect
Players.PlayerRemoving:Connect(function(player)
	activePurchases[player] = nil
	ServerDebounce:Clear(player)
end)

-- Kaufanfrage vom Client
shopEvent.OnServerEvent:Connect(function(player, productId, buttonName)
	if activePurchases[player] then
		warn("⛔ " .. player.Name .. " hat bereits einen aktiven Kauf!")
		return
	end

	if ServerDebounce:Block(player, "Buy_" .. tostring(productId), 1) then
		warn("🧱 ServerDebounce blockiert Kauf von " .. player.Name)
		return
	end

	activePurchases[player] = {
		ProductId = productId,
		ButtonName = buttonName
	}

	print("🛒 " .. player.Name .. " startet Kauf: Produkt " .. tostring(productId) .. " | Button: " .. tostring(buttonName))
	MarketplaceService:PromptProductPurchase(player, productId)
end)

-- Abschluss des Kaufs (erfolgreich oder abgebrochen)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(player, purchasedProductId, wasPurchased)
	local activePurchase = activePurchases[player]
	activePurchases[player] = nil

	local buttonName = activePurchase and activePurchase.ButtonName or "[unbekannt]"
	local productId = activePurchase and activePurchase.ProductId or purchasedProductId

	if wasPurchased then
		print("✅ Kauf abgeschlossen: " .. player.Name .. " | Produkt-ID: " .. tostring(productId))

		local key = "Player_" .. player.UserId
		local currentData = {}

		local success, result = pcall(function()
			return purchasesDataStore:GetAsync(key)
		end)
		if success and result then
			currentData = result
		elseif not success then
			warn("⚠️ Konnte Kaufdaten für " .. player.Name .. " nicht abrufen.")
		end

		table.insert(currentData, productId)

		local saveSuccess, err = pcall(function()
			purchasesDataStore:SetAsync(key, currentData)
		end)
		if not saveSuccess then
			warn("❌ Fehler beim Speichern des Kaufs für " .. player.Name .. ": " .. tostring(err))
		end

		-- Beispielbelohnung (Platzhalter)
		if productId == 12345678 then
			print("🎁 Beispielbelohnung aktivieren")
		end

		purchaseCompletedEvent:FireClient(player, productId, buttonName)

	else
		print("❌ Kauf abgebrochen – DEBUG:")
		print("player:", player and player.Name or "[nil]")
		print("purchasedProductId:", purchasedProductId)
		print("activePurchase:", activePurchase and typeof(activePurchase), activePurchase)
		print("activePurchases[player]:", activePurchases[player])

		local fallbackButtonName = "[unbekannt]"
		local fallbackProductId  = purchasedProductId

		if activePurchase then
			fallbackButtonName = tostring(activePurchase.ButtonName or "[kein ButtonName]")
			fallbackProductId = activePurchase.ProductId or purchasedProductId
		end

		print("[SHOP] ❌ Abbruch von " .. player.Name .. " | Produkt-ID: " .. tostring(fallbackProductId) .. " | Button: " .. tostring(fallbackButtonName))
		purchaseCompletedEvent:FireClient(player, fallbackProductId, fallbackButtonName)
	end
end)
