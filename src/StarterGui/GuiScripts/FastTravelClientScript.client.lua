-- FastTravelClientScript.client.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local GuiResolver    = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager   = require(ReplicatedStorage.Modules.PanelManager)
local PanelDebounce  = require(ReplicatedStorage.Modules.PanelDebounce)

--// Remotes
local teleportRemote = ReplicatedStorage.Remotes.Teleport:WaitForChild("TeleportToAreaRequest")

--// GUI
local panel          = GuiResolver:GetPanel("FastTravelGui", "FastTravelPanel")
if not panel then
	warn("❌ FastTravelPanel nicht gefunden!")
	return
end

local canvas         = panel:WaitForChild("CanvasGroup")
local scrollingFrame = canvas:WaitForChild("TeleportAreas"):WaitForChild("ScrollingFrame")
local closeButton    = canvas:WaitForChild("FastTravelCloseButton")

local storyButton    = scrollingFrame:WaitForChild("Story")
local raidButton     = scrollingFrame:WaitForChild("Raid")
local summonButton   = scrollingFrame:WaitForChild("Summoning")
local marketButton   = scrollingFrame:WaitForChild("Market")

--// Init
PanelManager:RegisterPanel(panel)

--// Functions
local function teleport(areaName)
	if PanelDebounce:Block("FastTravel_" .. areaName, 0.5) then return end
	print("🛰️ Teleport zu Bereich:", areaName)
	teleportRemote:FireServer(areaName)
	PanelManager:ClosePanel(panel)
end

--// Events
storyButton.MouseButton1Click:Connect(function()
	teleport("StoryAreaTP")
end)

raidButton.MouseButton1Click:Connect(function()
	teleport("RaidAreaTP")
end)

summonButton.MouseButton1Click:Connect(function()
	teleport("SummonAreaTP")
end)

marketButton.MouseButton1Click:Connect(function()
	teleport("UtilsAreaTP")
end)

if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		print("❌ FastTravelPanel wird geschlossen")
		PanelManager:ClosePanel(panel)
	end)
end
