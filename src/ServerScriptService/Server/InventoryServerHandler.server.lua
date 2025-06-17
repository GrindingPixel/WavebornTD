--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Modules
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")
local PlayerDataService = require(Modules:WaitForChild("PlayerDataService"))

local ItemData = require(ReplicatedStorage.Modules.ItemDataModule)

--// RemoteFolder vorbereiten
local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = ReplicatedStorage
end

--// RemoteFunction erstellen
local getInventoryFunction = Instance.new("RemoteFunction")
getInventoryFunction.Name = "GetInventoryData"
getInventoryFunction.Parent = remoteFolder

--// Debug
local DEBUG = true
local function log(...)   if DEBUG then print("[📦 InventoryServer]", ...) end end
local function warnf(...) if DEBUG then warn("[📦 InventoryServer]", ...) end end

--// Validierungsfunktion
local function ValidateItemEntry(item)
	if typeof(item) ~= "table" then return false end
	if typeof(item.id) ~= "string" then return false end
	if typeof(item.amount) ~= "number" then return false end
	return true
end

--// Verarbeitung
getInventoryFunction.OnServerInvoke = function(player)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warnf("Kein Profil für", player.Name)
		return {}
	end

	local rawInventory = profile.Data.Inventory or {}
	local finalInventory = {}

	for _, item in ipairs(rawInventory) do
		if ValidateItemEntry(item) then
			local meta = ItemData[item.id]
			if meta then
				item.name = meta.displayName
				item.icon = meta.iconId
				item.category = meta.category
				item.desc = meta.desc
				item.rarity = meta.rarity
			end
			table.insert(finalInventory, item)
		else
			warnf("Ungültiger Item-Eintrag bei", player.Name, ":", item)
		end
	end

	log(player.Name .. " Inventar gesendet (" .. #finalInventory .. " Items)")
	return finalInventory
end
