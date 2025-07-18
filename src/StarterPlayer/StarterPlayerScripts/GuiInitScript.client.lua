-- GuiInitScript.client.lua

--// Services
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Remotes
local ProfileLoadedEvent = ReplicatedStorage.Remotes.Profile:WaitForChild("ProfileLoadedEvent")
local IsProfileReady = ReplicatedStorage.Remotes.Profile:WaitForChild("IsProfileReady")
local getInventoryFunction = ReplicatedStorage.Remotes.Inventory:WaitForChild("GetInventoryData")
local getQuestsFunction = ReplicatedStorage.Remotes.Quests:WaitForChild("GetPlayerQuests")
local GetBattlepassInfo = ReplicatedStorage.Remotes.Battlepass:WaitForChild("GetBattlepassInfo")
local GetPlayerUnits = ReplicatedStorage.Remotes.Units:WaitForChild("GetPlayerUnits")

--// Modules
local GuiResolver   = require(ReplicatedStorage.Modules.GuiResolver)
local PanelManager  = require(ReplicatedStorage.Modules.PanelManager)

ProfileLoadedEvent.OnClientEvent:Wait()
print("✅ Profil geladen, starte GUI-Initialisierung...")

-- Serieller Loader-Block:
task.spawn(function()
	-- 1️⃣ Inventory laden
	print("[Loader] Lade Inventory...")
	local inventoryData = getInventoryFunction:InvokeServer()
	if inventoryData then
		print("[Loader] Inventory geladen, Items:", #inventoryData)
	else
		warn("[Loader] Inventory konnte nicht geladen werden!")
	end

	-- 2️⃣ Quests laden
	print("[Loader] Lade Quests...")
	local questData = getQuestsFunction:InvokeServer("Daily")
	if questData then
		print("[Loader] Quests geladen, Einträge:", #questData)
	else
		warn("[Loader] Quests konnten nicht geladen werden!")
	end

	-- 3️⃣ Battlepass laden
	print("[Loader] Lade Battlepass...")
	local battlepassData = GetBattlepassInfo:InvokeServer()
	if battlepassData then
		print("[Loader] Battlepass geladen, Level:", battlepassData.Level)
	else
		warn("[Loader] Battlepass konnte nicht geladen werden!")
	end

	-- 4️⃣ Units laden
	print("[Loader] Lade Units...")
	local unitsData = GetPlayerUnits:InvokeServer()
	if unitsData then
		print("[Loader] Units geladen, Anzahl:", #unitsData)
	else
		warn("[Loader] Units konnten nicht geladen werden!")
	end

	print("[Loader] Alle Systeme fertig geladen!")
end)

--// Panels registrieren
local panelMap = {
	{ gui = "BattlepassGui",  	panel = "BattlepassPanel" },
	{ gui = "CodesGui",       	panel = "CodesPanel" },
	{ gui = "NewsGui",        	panel = "NewsPanel" },
	{ gui = "ShopGui",        	panel = "ShopPanel" },
	{ gui = "ProfileGui",     	panel = "ProfilePanel" },
	{ gui = "ProfileGui",     	panel = "TitlesPanel" },
	{ gui = "FastTravelGui",  	panel = "FastTravelPanel" },
	{ gui = "QuestGui",       	panel = "QuestPanel" },
	{ gui = "InventoryGui",   	panel = "InventoryPanel" },
	{ gui = "UnitInventoryGui", panel = "UnitInventoryPanel" },
	{ gui = "MapTeleportGui", 	panel = "MapTeleportPanel" },
	{ gui = "TDGui", 		  	panel = "TDPanel" },
	{ gui = "MoneyGui", 		panel = "MoneyPanel" },
	{ gui = "UnitActionGui", 	panel = "ActionPanel" },
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
