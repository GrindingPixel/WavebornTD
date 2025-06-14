-- InventoryServerHandler.server.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

--// Modules
local InventoryData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InventoryDataModule"))

--// Remotes
local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remoteFolder.Name = "Remotes"
remoteFolder.Parent = ReplicatedStorage

local inventoryFolder = remoteFolder:FindFirstChild("Inventory") or Instance.new("Folder")
inventoryFolder.Name = "Inventory"
inventoryFolder.Parent = remoteFolder

local getInventory = Instance.new("RemoteFunction")
getInventory.Name = "GetInventoryRequest"
getInventory.Parent = inventoryFolder

--// Handler
getInventory.OnServerInvoke = function(player)
	print("[InventoryServer] Sende Inventardaten an:", player.Name)
	return InventoryData.Items
end
