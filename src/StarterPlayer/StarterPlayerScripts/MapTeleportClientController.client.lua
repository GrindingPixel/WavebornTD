-- StarterPlayerScripts/MapTeleportClientController.client.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PanelManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))
local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Teleport"):WaitForChild("OpenMapSelection")

local isOpen = false

remote.OnClientEvent:Connect(function()
	if isOpen then return end
	isOpen = true

	task.defer(function()
		local gui = GuiResolver:Get("MapTeleportGui")
		local panel = GuiResolver:GetPanel("MapTeleportGui", "MapTeleportPanel")
		if gui and panel then
			PanelManager:OpenPanel(panel)
		else
			warn("❌ MapTeleportGui oder Panel nicht gefunden")
		end
	end)
end)

-- Optional: Reset, falls Panel manuell geschlossen wird (z. B. durch PanelManager:CloseAllPanels())
-- Beispiel: bei Tastendruck oder Buttonschließen → setze isOpen = false
