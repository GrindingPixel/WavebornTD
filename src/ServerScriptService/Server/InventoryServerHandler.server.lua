-- InventoryServerHandler.server.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local InventoryData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InventoryDataModule"))

-- Remotes vorbereiten
local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remoteFolder.Name = "Remotes"
remoteFolder.Parent = ReplicatedStorage

local inventoryFolder = remoteFolder:FindFirstChild("Inventory") or Instance.new("Folder")
inventoryFolder.Name = "Inventory"
inventoryFolder.Parent = remoteFolder

local getInventory = Instance.new("RemoteFunction")
getInventory.Name = "GetInventoryRequest"
getInventory.Parent = inventoryFolder

-- Serverfunktion: Gibt Inventar zurück
getInventory.OnServerInvoke = function(player)
	print("[InventoryServer] Sende Inventardaten an:", player.Name)
	return InventoryData.Items
end
