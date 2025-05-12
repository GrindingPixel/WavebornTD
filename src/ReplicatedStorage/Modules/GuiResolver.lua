local Players = game:GetService("Players")

local GuiResolver = {}

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

return GuiResolver
