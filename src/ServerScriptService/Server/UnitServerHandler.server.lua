-- UnitServerHandler.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileWrapper = require(Modules:WaitForChild("ProfileStoreWrapper"))
local ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))
local UnitData = require(ReplicatedStorage.Modules:WaitForChild("UnitDataModule"))

--// Debug
local DEBUG = true
local function log(...)
	if DEBUG then print("[UnitServerHandler]", ...) end
end
local function warnf(...)
	if DEBUG then warn("[UnitServerHandler]", ...) end
end

--// Remotes
local equipUnitEvent = ReplicatedStorage.Remotes.Units:WaitForChild("EquipUnit")
local unlockUnitEvent = ReplicatedStorage.Remotes.Units:WaitForChild("UnlockUnit")
local levelUpUnitEvent = ReplicatedStorage.Remotes.Units:WaitForChild("LevelUpUnit")
local getUnitsFunction = ReplicatedStorage.Remotes.Units:WaitForChild("GetPlayerUnits")

--// Units für Client abrufen (Read-Only)
getUnitsFunction.OnServerInvoke = function(player)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("GetPlayerUnits abgelehnt für", player and player.Name)
		return {}
	end
	local result = {
		Units = ProfileWrapper:GetUnits(player),
		EquippedUnits = ProfileWrapper:GetEquippedUnits(player)
	}
	log("Units für", player.Name, "abgerufen")
	return result
end

--// Unit freischalten
unlockUnitEvent.OnServerEvent:Connect(function(player, unitId)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("UnlockUnit abgelehnt (Profil nicht geladen) für", player and player.Name)
		return
	end
	if type(unitId) ~= "string" or unitId == "" then
		warnf("Ungültige UnitId für UnlockUnit von", player.Name)
		return
	end
	if not UnitData[unitId] then
		warnf("Unbekannte Unit für UnlockUnit:", unitId, "bei", player.Name)
		return
	end
	if ServerDebounce:Block(player, "UnlockUnit_" .. unitId, 1.0) then
		warnf("Debounce Block UnlockUnit für", player.Name)
		return
	end

	ProfileWrapper:UnlockUnit(player, unitId, UnitData[unitId].DefaultStats)
	log("Unit freigeschaltet:", unitId, "für", player.Name)
end)

--// Unit equippen
equipUnitEvent.OnServerEvent:Connect(function(player, slot, unitId)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("EquipUnit abgelehnt (Profil nicht geladen) für", player and player.Name)
		return
	end
	if type(slot) ~= "number" or slot < 1 or slot > 6 then
		warnf("Ungültiger Slot für EquipUnit von", player.Name)
		return
	end
	if type(unitId) ~= "string" or unitId == "" then
		warnf("Ungültige UnitId für EquipUnit von", player.Name)
		return
	end
	if not UnitData[unitId] then
		warnf("Unbekannte Unit für EquipUnit:", unitId, "bei", player.Name)
		return
	end
	if ServerDebounce:Block(player, "EquipUnit_" .. unitId, 1.0) then
		warnf("Debounce Block EquipUnit für", player.Name)
		return
	end

	ProfileWrapper:EquipUnit(player, slot, unitId)
	log("Unit equipped:", unitId, "auf Slot", slot, "für", player.Name)
end)

--// Unit Level-Up
levelUpUnitEvent.OnServerEvent:Connect(function(player, unitId)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("LevelUpUnit abgelehnt (Profil nicht geladen) für", player and player.Name)
		return
	end
	if type(unitId) ~= "string" or unitId == "" then
		warnf("Ungültige UnitId für LevelUpUnit von", player.Name)
		return
	end
	if not UnitData[unitId] then
		warnf("Unbekannte Unit für LevelUpUnit:", unitId, "bei", player.Name)
		return
	end
	if ServerDebounce:Block(player, "LevelUpUnit_" .. unitId, 1.0) then
		warnf("Debounce Block LevelUpUnit für", player.Name)
		return
	end

	ProfileWrapper:LevelUpUnit(player, unitId)
	log("Unit LevelUp:", unitId, "bei", player.Name)
end)
