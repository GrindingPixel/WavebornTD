-- UpgradeServerHandler.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))

--// Debug
local DEBUG = true
local function log(...)
	if DEBUG then print("[UpgradeServerHandler]", ...) end
end
local function warnf(...)
	if DEBUG then warn("[UpgradeServerHandler]", ...) end
end

--// Remotes
local upgradeInventoryEvent = ReplicatedStorage.Remotes.Upgrades:WaitForChild("UpgradeInventory")
local getUpgradesFunction = ReplicatedStorage.Remotes.Upgrades:WaitForChild("GetPlayerUpgrades")

--// Upgrades für Client abrufen (Read-Only)
getUpgradesFunction.OnServerInvoke = function(player)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("GetPlayerUpgrades abgelehnt für", player and player.Name)
		return {}
	end
	local upgrades = ProfileWrapper:GetUpgrades(player)
	log("Upgrades für", player.Name, "abgerufen")
	return upgrades
end

--// Inventargröße upgraden
upgradeInventoryEvent.OnServerEvent:Connect(function(player, newSize)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("UpgradeInventory abgelehnt (Profil nicht geladen) für", player and player.Name)
		return
	end
	if type(newSize) ~= "number" or newSize < 1 or newSize > 500 then
		warnf("Ungültige neue Inventargröße:", newSize, "für", player.Name)
		return
	end
	if ServerDebounce:Block(player, "UpgradeInventory", 1.5) then
		warnf("Debounce Block UpgradeInventory für", player.Name)
		return
	end

	ProfileWrapper:UpgradeInventory(player, newSize)
	log("Inventargröße auf", newSize, "für", player.Name, "gesetzt")
end)
