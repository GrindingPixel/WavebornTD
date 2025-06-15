-- InventoryServerHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

--// Modules
local InventoryService  = require(script.Parent.Parent.Modules.InventoryService)
local ServerDebounce    = require(script.Parent.Parent.Modules.ServerDebounce)
local PlayerDataService = require(script.Parent.Parent.Modules.PlayerDataService)

--// Configuration
local debugEnabled = true

--// Remotes
local remoteFolder = ReplicatedStorage:WaitForChild("Remotes")
local inventoryFolder = remoteFolder:FindFirstChild("Inventory") or Instance.new("Folder")
inventoryFolder.Name = "Inventory"
inventoryFolder.Parent = remoteFolder

local requestRemote = Instance.new("RemoteFunction")
requestRemote.Name = "GetInventoryItems"
requestRemote.Parent = inventoryFolder

local addItemEvent = Instance.new("RemoteEvent")
addItemEvent.Name = "AddItemRequest"
addItemEvent.Parent = inventoryFolder

local removeItemEvent = Instance.new("RemoteEvent")
removeItemEvent.Name = "RemoveItemRequest"
removeItemEvent.Parent = inventoryFolder

--// Remote: Anfrage nach Items
requestRemote.OnServerInvoke = function(player)
	if debugEnabled then print("📦 [Inventory] GetInventoryItems →", player.Name) end
	return InventoryService:GetItems(player)
end

--// Remote: Item hinzufügen
addItemEvent.OnServerEvent:Connect(function(player, itemId, amount)
	if not itemId or type(amount) ~= "number" then return end
	if ServerDebounce:Check(player, "AddItem_" .. itemId, 0.5) then return end

	local success = InventoryService:AddItem(player, itemId, amount)

	if debugEnabled then
		if success then
			print("✅ [Inventory] Hinzugefügt:", amount, "x", itemId, "→", player.Name)
		else
			warn("❌ [Inventory] Fehler beim Hinzufügen von", itemId, "bei", player.Name)
		end
	end
end)

--// Remote: Item entfernen
removeItemEvent.OnServerEvent:Connect(function(player, itemId, amount)
	if not itemId or type(amount) ~= "number" then return end
	if ServerDebounce:Check(player, "RemoveItem_" .. itemId, 0.5) then return end

	local success = InventoryService:RemoveItem(player, itemId, amount)

	if debugEnabled then
		if success then
			print("🗑️ [Inventory] Entfernt:", amount, "x", itemId, "→", player.Name)
		else
			warn("❌ [Inventory] Fehler beim Entfernen von", itemId, "bei", player.Name)
		end
	end
end)
