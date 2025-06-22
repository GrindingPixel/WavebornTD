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
local function log(...) if DEBUG then print("[UnitServerHandler]", ...) end end
local function warnf(...) if DEBUG then warn("[UnitServerHandler]", ...) end end

--// Remotes
local equipUnitEvent = ReplicatedStorage.Remotes.Units:WaitForChild("EquipUnit")
local getUnitsFunction = ReplicatedStorage.Remotes.Units:WaitForChild("GetPlayerUnits")

--// Units für Client abrufen (UUID-System)
getUnitsFunction.OnServerInvoke = function(player)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("GetPlayerUnits abgelehnt für", player and player.Name)
		return {}
	end

	local result = ProfileWrapper:GetUnits(player)
	log("📦 Units gesendet für", player.Name, "(Anzahl:", #result, ")")
	return result
end

--// Unit ausrüsten
equipUnitEvent.OnServerEvent:Connect(function(player, slot, unitUUID)
	if not ProfileWrapper:IsLoaded(player) then
		warnf("EquipUnit abgelehnt – Profil nicht geladen für", player and player.Name)
		return
	end
	if type(slot) ~= "number" or slot < 1 or slot > 6 then
		warnf("Ungültiger Slot:", slot, "bei", player.Name)
		return
	end
	if type(unitUUID) ~= "string" or unitUUID == "" then
		warnf("Ungültige UnitUUID:", unitUUID, "bei", player.Name)
		return
	end
	if ServerDebounce:Block(player, "EquipUnit_" .. unitUUID, 1.0) then
		warnf("Debounce EquipUnit bei", player.Name)
		return
	end

	local equipped = ProfileWrapper:EquipUnit(player, slot, unitUUID)
	if equipped then
		log("🎮 Unit", unitUUID, "auf Slot", slot, "für", player.Name)
	else
		warnf("EquipUnit fehlgeschlagen für", player.Name, "→", unitUUID)
	end
end)
