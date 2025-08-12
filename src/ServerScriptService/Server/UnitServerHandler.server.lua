-- UnitServerHandler.server.lua
-- Typ: Script (ServerScript)

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")

--// Modules
local ProfileService = require(Modules:WaitForChild("ProfileService"))
local ServerDebounce = require(ReplicatedStorage.Modules:WaitForChild("ServerDebounce"))
local UnitData = require(ReplicatedStorage.Modules:WaitForChild("UnitDataModule"))

--// Debug
local DEBUG = true
local function log(...) if DEBUG then print("[UnitServerHandler]", ...) end end
local function warnf(...) if DEBUG then warn("[UnitServerHandler]", ...) end end

--// Remotes
local equipUnitEvent = ReplicatedStorage.Remotes.Units:WaitForChild("EquipUnit")
local getUnitsFunction = ReplicatedStorage.Remotes.Units:WaitForChild("GetPlayerUnits")
local ProfileChanged = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileChanged")

--// Units für Client abrufen (UUID-System)
getUnitsFunction.OnServerInvoke = function(player)
        if not ProfileService:IsLoaded(player) then
		warnf("GetPlayerUnits abgelehnt für", player and player.Name)
		return {}
	end

        local result = ProfileService:GetUnits(player)
	log("📦 Units gesendet für", player.Name, "(Anzahl:", #result, ")")
	return result
end

--// Unit ausrüsten
equipUnitEvent.OnServerEvent:Connect(function(player, slot, unitUUID)
        if not ProfileService:IsLoaded(player) then
		warnf("EquipUnit abgelehnt – Profil nicht geladen für", player and player.Name)
		return
	end
	if type(slot) ~= "number" or slot < 1 or slot > 6 then
		warnf("Ungültiger Slot:", slot, "bei", player.Name)
		return
	end
	if type(unitUUID) ~= "string" then
	warnf("Ungültige UnitUUID:", unitUUID, "bei", player.Name)
	return
end
	if ServerDebounce:Block(player, "EquipUnit_" .. unitUUID, 1.0) then
		warnf("Debounce EquipUnit bei", player.Name)
		return
	end

        local equipped = ProfileService:EquipUnit(player, slot, unitUUID)
	if equipped then
		log("🎮 Unit", unitUUID, "auf Slot", slot, "für", player.Name)

		-- 🔧 EquipSlots & LiveSync senden
                local updated = ProfileService:GetUnits(player)
                local equippedSlots = ProfileService:GetEquippedUnits(player)

		for s = 1, 6 do
			local uuid = equippedSlots[s]
			if uuid then
				player:SetAttribute("EquippedSlot" .. s, uuid)
			else
				player:SetAttribute("EquippedSlot" .. s, nil)
			end
		end

		ProfileChanged:FireClient(player, "Units", updated)
	else
		warnf("EquipUnit fehlgeschlagen für", player.Name, "→", unitUUID)
	end
end)
