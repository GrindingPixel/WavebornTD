-- InventoryServerHandler.server.lua
-- Typ: Script (ServerScriptService)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Modules           = ServerScriptService:WaitForChild("Modules")
local Players = game:GetService("Players")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local ItemData       = require(ReplicatedStorage.Modules:WaitForChild("ItemDataModule"))
local ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))
local ProfileSyncService = require(Modules:WaitForChild("ProfileSyncService"))
local DebugLogger = require(Modules:WaitForChild("DebugLogger"))

--// Remotes
local InventoryFolder = ReplicatedStorage.Remotes:WaitForChild("Inventory")
local getInventoryFunction = InventoryFolder:WaitForChild("GetInventoryData")
local addItemEvent        = InventoryFolder:WaitForChild("AddItemRequest")
local removeItemEvent     = InventoryFolder:WaitForChild("RemoveItemRequest")

local log, warnf = DebugLogger.new("InventoryServerHandler", true)

-- GetInventoryData: Inventory als Array an Client
getInventoryFunction.OnServerInvoke = function(player)
	if not ProfileWrapper:IsLoaded(player) then
		warn("❌ [GetInventoryData] Profil nicht geladen für", player)
		return {}
	end

	local inventory = ProfileWrapper:GetInventory(player)
	if typeof(inventory) ~= "table" then
		warn("❌ [GetInventoryData] Ungültiges Inventory für", player, "Typ:", typeof(inventory))
		return {}
	end

	local result = {}

	for itemType, itemList in pairs(inventory) do
		if typeof(itemList) ~= "table" then
			warn("⚠️ [GetInventoryData] Ungültiger Container für Typ:", itemType, "→", typeof(itemList))
			continue
		end

		for itemId, amount in pairs(itemList) do
			table.insert(result, {
				id = itemId,
				type = itemType,
				amount = amount
			})
		end
	end

	print("✅ [GetInventoryData] Sende", #result, "Items an", player.Name)
	return result
end


-- AddItemRequest: Item hinzufügen
addItemEvent.OnServerEvent:Connect(function(player, itemId, amount)
	if not ProfileWrapper:IsLoaded(player) then return end
	if type(itemId) ~= "string" or itemId == "" then return end
	if type(amount) ~= "number" or amount <= 0 or amount > 999 then return end
	if not ItemData[itemId] then return end
	if ServerDebounce:Block(player, "AddItem", 1.0) then return end

	local category = ItemData[itemId].category
	if not category then
		warnf("❌ Item ohne Kategorie:", itemId)
		return
	end

	ProfileWrapper:AddItemTyped(player, category, itemId, amount)
	log("Item hinzugefügt:", itemId, "x", amount, "Typ:", category, "→", player.Name)
end)

-- RemoveItemRequest: Item entfernen
removeItemEvent.OnServerEvent:Connect(function(player, itemId, amount)
	if not ProfileWrapper:IsLoaded(player) then return end
	if type(itemId) ~= "string" or itemId == "" then return end
	if type(amount) ~= "number" or amount <= 0 or amount > 999 then return end
	if not ItemData[itemId] then return end
	if ServerDebounce:Block(player, "RemoveItem", 1.0) then return end

	local category = ItemData[itemId].category
	if not category then
		warnf("❌ Item ohne Kategorie:", itemId)
		return
	end

	local success = ProfileWrapper:RemoveItemTyped(player, category, itemId, amount)
	if success then
		log("Item entfernt:", itemId, "x", amount, "Typ:", category, "←", player.Name)
	else
		warnf("❌ Entfernen fehlgeschlagen:", itemId, "bei", player.Name)
	end

	local profile = ProfileWrapper:GetProfile(player)
	if profile then
		ProfileSyncService:Send(player, "Inventory", profile.Data.Inventory)
	end
end)
