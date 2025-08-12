-- GuiResolver.lua

--// Services
local Players = game:GetService("Players")
local DebugLogger = require(ReplicatedStorage.Modules:WaitForChild("DebugLogger"))

--// Module
local GuiResolver = {}
local log = DebugLogger.new("GuiResolver")

--// Map-Zonen anhand von PlaceId
local placeZones = {
	[84670806766416] = "Lobby",         -- Lobby
	[128061510848823] = "TowerDefense",  -- Story_1
	[92355255451335] = "TowerDefense",  -- Story_2
	[111057724598845] = "TowerDefense", -- Story_3
}

-- Blockierte GUIs pro Zone
local zoneGuiBlocklist = {
	TowerDefense = {
		"BattlepassGui",
		"CodesGui",
		"FastTravelGui",
		"InventoryGui",
		"MapTeleportGui",
		"NewsGui",
		"ProfileGui",
		"QuestGui",
		"MoneyLobbyGui",
		"ShopGui",
		"SummonGui",
		
	},
	Lobby = {
		"MatchResultsGui",
		"MoneyGui",
		"TDGui",
		"UnitActionGui",
	}
}

-- Laufzeitinfo
local PLACE_ID = game.PlaceId
local currentZone = placeZones[PLACE_ID] or "Unknown"
local blocklist = zoneGuiBlocklist[currentZone] or {}

-- Prüft, ob eine GUI blockiert ist
local function isBlocked(guiName)
	for _, name in ipairs(blocklist) do
		if name == guiName then
			return true
		end
	end
	return false
end

-- Gibt ein ScreenGui zurück (wenn vorhanden)
function GuiResolver:Get(guiName)
        if isBlocked(guiName) then
                log:Warn("❌ Zugriff auf '" .. guiName .. "' ist in Zone '" .. currentZone .. "' blockiert (PlaceId: " .. PLACE_ID .. ").")
                return nil
        end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild(guiName)

        if gui and gui:IsA("ScreenGui") then
                return gui
        else
                log:Warn("⚠️ Gui '" .. guiName .. "' konnte nicht gefunden werden.")
                return nil
        end
end

-- Wartet auf ein ScreenGui für max. Timeout Sekunden
function GuiResolver:WaitFor(guiName, timeout)
        if isBlocked(guiName) then
                log:Warn("❌ Zugriff auf '" .. guiName .. "' ist in Zone '" .. currentZone .. "' blockiert (PlaceId: " .. PLACE_ID .. ").")
                return nil
        end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local elapsed = 0
	timeout = timeout or 5

	while elapsed < timeout do
		local gui = playerGui:FindFirstChild(guiName)
		if gui and gui:IsA("ScreenGui") then
			return gui
		end
		task.wait(0.05)
		elapsed += 0.05
	end

        log:Warn("⚠️ Gui '" .. guiName .. "' nicht innerhalb von " .. timeout .. " Sekunden gefunden.")
	return nil
end

-- Holt ein Panel aus einem bestimmten Gui
function GuiResolver:GetPanel(guiName, panelName, timeout)
        if isBlocked(guiName) then
                log:Warn("❌ Panel-Zugriff blockiert: " .. guiName .. "." .. panelName .. " in Zone '" .. currentZone .. "' (PlaceId: " .. PLACE_ID .. ").")
                return nil
        end

	timeout = timeout or 5
	local gui = self:WaitFor(guiName, timeout)
	if not gui then return nil end

	local elapsed = 0
	while elapsed < timeout do
		local panel = gui:FindFirstChild(panelName)
		if panel then return panel end
		task.wait(0.05)
		elapsed += 0.05
	end

        log:Warn("⚠️ Panel NICHT gefunden: " .. guiName .. " → " .. panelName)
	return nil
end

function GuiResolver:IsBlocked(guiName: string): boolean
	for _, name in ipairs(blocklist) do
		if name == guiName then
			return true
		end
	end
	return false
end


return GuiResolver
