-- GuiInitScript.client.lua

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileLoadedEvent = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")

--// Modules
local GuiResolver   = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager  = require(ReplicatedStorage.Modules.PanelManager)

ProfileLoadedEvent.OnClientEvent:Wait()
--// Panels
local panelMap = {
	{ gui = "BattlepassGui",  panel = "BattlepassPanel" },
	{ gui = "CodesGui",       panel = "CodesPanel" },
	{ gui = "NewsGui",        panel = "NewsPanel" },
	{ gui = "ShopGui",        panel = "ShopPanel" },
	{ gui = "ProfileGui",     panel = "ProfilePanel" },
	{ gui = "ProfileGui",     panel = "TitlesPanel" },
	{ gui = "FastTravelGui",  panel = "FastTravelPanel" },
	{ gui = "QuestGui",       panel = "QuestPanel" },
	{ gui = "InventoryGui",   panel = "InventoryPanel" },
	{ gui = "UnitInventoryGui", panel = "UnitInventoryPanel" },
	{ gui = "MapTeleportGui", panel = "MapTeleportPanel" },
}

--// Init
for _, entry in ipairs(panelMap) do
	local panel = GuiResolver:GetPanel(entry.gui, entry.panel)
	if panel then
		PanelManager:RegisterPanel(panel)
		print("✅ Panel registriert:", entry.gui, entry.panel)
	else
		warn("⚠️ Panel NICHT gefunden:", entry.gui, entry.panel)
	end
end
