-- GuiInitScript.lua
-- Registriert alle wichtigen Panels beim Spielstart

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiResolver = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiResolver"))
local PanelManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PanelManager"))

local panelMap = {
	-- guiName        panelName
	{ gui = "BattlepassGui", panel = "BattlepassPanel" },
	{ gui = "CodesGui",      panel = "CodesPanel" },
	{ gui = "NewsGui",       panel = "NewsPanel" },
	{ gui = "ShopGui",       panel = "ShopPanel" },
	{ gui = "ProfileGui",    panel = "ProfilePanel" },
	{ gui = "ProfileGui",    panel = "TitlesPanel" },
}

for _, entry in ipairs(panelMap) do
	local panel = GuiResolver:GetPanel(entry.gui, entry.panel)
	if panel then
		PanelManager:RegisterPanel(panel)
		print("✅ Panel registriert:", entry.gui, entry.panel)
	else
		warn("⚠️ Panel NICHT gefunden:", entry.gui, entry.panel)
	end
end
