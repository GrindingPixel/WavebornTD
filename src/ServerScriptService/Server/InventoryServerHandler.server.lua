-- InventoryServerHandler.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))
local ItemData = require(ReplicatedStorage.Modules:WaitForChild("ItemDataModule"))

--// Debug
local DEBUG = true
local function log(...)
	if DEBUG then print("[InventoryServerHandler]", ...) end
end
local function warnf(...)
	if DEBUG then warn("[InventoryServerHandler]", ...) end
end

--// Remotes
local getInventoryFunction = ReplicatedStorage.Remotes.Inventory:WaitForChild("GetInventoryData")
local addItemEvent = ReplicatedStorage.Remotes.Inventory:WaitForChild("AddItemRequest")
local removeItemEvent = ReplicatedStorage.Remotes.Inventory:WaitForChild("RemoveItemRequest")

--// Inventory für Client (Read-Only)
getInventoryFunction.OnServerInvoke = function(player)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("GetInventoryData abgelehnt für", player and player.Name)
		return {}
	end
	log("Inventory für", player.Name, "abgerufen")
	return ProfileWrapper:GetInventory(player)
end

--// Item hinzufügen (über RemoteEvent)
addItemEvent.OnServerEvent:Connect(function(player, itemId, amount)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("AddItemRequest abgelehnt (Profil nicht geladen) für", player and player.Name)
		return
	end
	if type(itemId) ~= "string" or itemId == "" then
		warnf("Ungültige ItemId für AddItemRequest von", player.Name)
		return
	end
	if type(amount) ~= "number" or amount <= 0 or amount > 999 then
		warnf("Ungültige Menge für AddItemRequest:", amount, "von", player.Name)
		return
	end
	if not ItemData[itemId] then
		warnf("Unbekanntes Item für AddItemRequest:", itemId, "von", player.Name)
		return
	end
	if ServerDebounce:Block(player, "AddItem", 1.0) then
		warnf("Debounce Block AddItem für", player.Name)
		return
	end

	ProfileWrapper:AddItem(player, itemId, amount)
	log("AddItemRequest:", itemId, "x", amount, "an", player.Name)
end)

--// Item entfernen (über RemoteEvent)
removeItemEvent.OnServerEvent:Connect(function(player, itemId, amount)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("RemoveItemRequest abgelehnt (Profil nicht geladen) für", player and player.Name)
		return
	end
	if type(itemId) ~= "string" or itemId == "" then
		warnf("Ungültige ItemId für RemoveItemRequest von", player.Name)
		return
	end
	if type(amount) ~= "number" or amount <= 0 or amount > 999 then
		warnf("Ungültige Menge für RemoveItemRequest:", amount, "von", player.Name)
		return
	end
	if not ItemData[itemId] then
		warnf("Unbekanntes Item für RemoveItemRequest:", itemId, "von", player.Name)
		return
	end
	if ServerDebounce:Block(player, "RemoveItem", 1.0) then
		warnf("Debounce Block RemoveItem für", player.Name)
		return
	end

	ProfileWrapper:RemoveItem(player, itemId, amount)
	log("RemoveItemRequest:", itemId, "x", amount, "von", player.Name)
end)
