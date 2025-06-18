-- ShopServerHandler.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))
local ShopData = require(ReplicatedStorage.Modules:WaitForChild("ShopDataModule")) -- z. B. Produkt-Infos

--// Debug
local DEBUG = true
local function log(...)
	if DEBUG then print("[ShopServerHandler]", ...) end
end
local function warnf(...)
	if DEBUG then warn("[ShopServerHandler]", ...) end
end

--// Remotes
local shopRequest = ReplicatedStorage.Remotes.Shop:WaitForChild("ShopPurchaseRequest")
local shopCompleted = ReplicatedStorage.Remotes.Shop:WaitForChild("ShopPurchaseCompleted")

--// Shop-Handler
shopRequest.OnServerEvent:Connect(function(player, productId, buttonName)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("ShopPurchaseRequest abgelehnt (Profil nicht geladen) für", player and player.Name)
		return
	end

	if type(productId) ~= "number" or not ShopData[productId] then
		warnf("Ungültige Produkt-ID für ShopPurchaseRequest:", productId, "von", player.Name)
		return
	end

	if type(buttonName) ~= "string" or buttonName == "" then
		warnf("Ungültiger ButtonName für ShopPurchaseRequest:", buttonName, "von", player.Name)
		return
	end

	if ServerDebounce:Block(player, "ShopBuy_" .. tostring(productId), 1.5) then
		warnf("Debounce Block ShopBuy für", player.Name)
		return
	end

	local offer = ShopData[productId]
	local price = offer.Price
	local currency = offer.Currency -- z. B. "Gold" oder "Gems"

	-- Preisvalidierung
	if currency == "Gold" then
		if ProfileWrapper:GetGold(player) < price then
			warnf("Nicht genug Gold für Kauf:", productId, "bei", player.Name)
			return
		end
		ProfileWrapper:RemoveGold(player, price)
	elseif currency == "Gems" then
		if ProfileWrapper:GetGems(player) < price then
			warnf("Nicht genug Gems für Kauf:", productId, "bei", player.Name)
			return
		end
		ProfileWrapper:RemoveGems(player, price)
	else
		warnf("Unbekannte Währung für Produkt:", productId, "bei", player.Name)
		return
	end

	-- Belohnung
	if offer.Item then
		ProfileWrapper:AddItem(player, offer.Item, offer.Amount or 1)
		log("Shopkauf:", productId, "→", offer.Item, "x", offer.Amount or 1, "an", player.Name)
	end

	-- Rückmeldung an Client (Erfolg)
	shopCompleted:FireClient(player, productId, buttonName)
	log("Shopkauf abgeschlossen für", player.Name, "→ Produkt-ID:", productId)
end)
