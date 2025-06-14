-- GuiResolver.lua

--// Services
local Players = game:GetService("Players")

--// Module
local GuiResolver = {}

--// Funktionen

-- Gibt ein ScreenGui zurück (wenn vorhanden)
function GuiResolver:Get(guiName)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild(guiName)

	if gui and gui:IsA("ScreenGui") then
		return gui
	else
		warn("⚠️ Gui '" .. guiName .. "' konnte nicht gefunden werden.")
		return nil
	end
end

-- Wartet auf ein ScreenGui für max. Timeout Sekunden
function GuiResolver:WaitFor(guiName, timeout)
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

	warn("⚠️ Gui '" .. guiName .. "' nicht innerhalb von " .. timeout .. " Sekunden gefunden.")
	return nil
end

-- Holt ein Panel aus einem bestimmten Gui (z. B. Panel innerhalb von BattlepassGui)
function GuiResolver:GetPanel(guiName, panelName, timeout)
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

	warn("⚠️ Panel '" .. panelName .. "' in '" .. guiName .. "' nicht gefunden.")
	return nil
end

--// Rückgabe
return GuiResolver
