-- PanelDebounce.lua

--// Modul
local PanelDebounce = {}

--// State: globale Sperrliste
local debounceMap = {}

-- Prüft, ob ein Panel gesperrt ist
function PanelDebounce:IsBlocked(panelName)
	return debounceMap[panelName] == true
end

-- Blockiert ein Panel für eine bestimmte Zeit
function PanelDebounce:Block(panelName, duration)
	if self:IsBlocked(panelName) then
		return true
	end

	debounceMap[panelName] = true
	task.delay(duration or 0.25, function()
		debounceMap[panelName] = false
	end)

	return false
end

--// Rückgabe
return PanelDebounce
